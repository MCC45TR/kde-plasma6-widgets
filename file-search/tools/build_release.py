#!/usr/bin/env python3
"""Build and verify a deterministic Plasma package and release evidence."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_ROOTS = (ROOT / "metadata.json", ROOT / "contents")
RELEASE_DIR = ROOT / "release"
BUILD_DIR = ROOT / "build"
FIXED_ZIP_TIME = (1980, 1, 1, 0, 0, 0)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def package_mode(name: str) -> int:
    return 0o755 if name.endswith(".sh") else 0o644


def package_files() -> list[tuple[str, Path]]:
    files: list[tuple[str, Path]] = []
    for root in PACKAGE_ROOTS:
        candidates = [root] if root.is_file() else root.rglob("*")
        for path in candidates:
            if not path.is_file() or path.is_symlink():
                continue
            relative = path.relative_to(ROOT).as_posix()
            if any(part.startswith(".") for part in PurePosixPath(relative).parts):
                continue
            if path.suffix in {".pyc", ".bak", ".orig", ".rej"}:
                continue
            files.append((relative, path))
    return sorted(files)


def metadata() -> dict:
    return json.loads((ROOT / "metadata.json").read_text(encoding="utf-8"))


def source_manifest(files: list[tuple[str, Path]]) -> dict:
    return {
        "schemaVersion": 1,
        "package": metadata()["KPlugin"]["Id"],
        "version": metadata()["KPlugin"]["Version"],
        "files": [
            {
                "path": name,
                "sha256": sha256_bytes(path.read_bytes()),
                "size": path.stat().st_size,
                "mode": f"{package_mode(name):04o}",
            }
            for name, path in files
        ],
    }


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def build_archive(archive: Path, files: list[tuple[str, Path]]) -> str:
    archive.parent.mkdir(parents=True, exist_ok=True)
    temporary = archive.with_suffix(archive.suffix + ".tmp")
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for name, path in files:
            info = zipfile.ZipInfo(name, FIXED_ZIP_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = ((0o100000 | package_mode(name)) << 16)
            output.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    os.replace(temporary, archive)
    return sha256_bytes(archive.read_bytes())


def create_sbom(manifest: dict) -> dict:
    namespace_hash = sha256_bytes(json.dumps(manifest, sort_keys=True).encode())
    files = []
    relationships = []
    for index, entry in enumerate(manifest["files"], 1):
        spdx_id = f"SPDXRef-File-{index}"
        files.append({
            "SPDXID": spdx_id,
            "fileName": entry["path"],
            "checksums": [{"algorithm": "SHA256", "checksumValue": entry["sha256"]}],
            "licenseConcluded": "NOASSERTION",
            "copyrightText": "NOASSERTION",
        })
        relationships.append({
            "spdxElementId": "SPDXRef-Package",
            "relationshipType": "CONTAINS",
            "relatedSpdxElement": spdx_id,
        })
    return {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"{manifest['package']}-{manifest['version']}",
        "documentNamespace": f"https://github.com/MCC45TR/Plasma6Widgets/spdx/{namespace_hash}",
        "creationInfo": {"created": "1980-01-01T00:00:00Z", "creators": ["Tool: build_release.py"]},
        "packages": [{
            "name": manifest["package"],
            "SPDXID": "SPDXRef-Package",
            "versionInfo": manifest["version"],
            "downloadLocation": "NOASSERTION",
            "filesAnalyzed": True,
            "licenseConcluded": "GPL-3.0-only",
            "licenseDeclared": "GPL-3.0-only",
            "copyrightText": "NOASSERTION",
        }],
        "files": files,
        "relationships": relationships,
    }


def verify(archive: Path, manifest_path: Path, checksum_path: Path) -> None:
    expected_manifest = source_manifest(package_files())
    actual_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if actual_manifest != expected_manifest:
        raise RuntimeError("source manifest does not match the current package sources")
    expected_names = [entry["path"] for entry in actual_manifest["files"]]
    with zipfile.ZipFile(archive) as package:
        names = package.namelist()
        if names != expected_names or len(names) != len(set(names)):
            raise RuntimeError("archive file list is not canonical")
        for entry in actual_manifest["files"]:
            if sha256_bytes(package.read(entry["path"])) != entry["sha256"]:
                raise RuntimeError(f"archive content mismatch: {entry['path']}")
            archived_mode = (package.getinfo(entry["path"]).external_attr >> 16) & 0o777
            if archived_mode != int(entry["mode"], 8):
                raise RuntimeError(f"archive mode mismatch: {entry['path']}")
    checksum = checksum_path.read_text(encoding="ascii").split()[0]
    if checksum != sha256_bytes(archive.read_bytes()):
        raise RuntimeError("archive checksum mismatch")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--gpg-key", help="optionally create an ASCII-armored detached signature")
    args = parser.parse_args()

    package_meta = metadata()["KPlugin"]
    archive = BUILD_DIR / f"{package_meta['Id']}-{package_meta['Version']}.plasmoid"
    manifest_path = RELEASE_DIR / "source-manifest.json"
    sbom_path = RELEASE_DIR / "SBOM.spdx.json"
    provenance_path = RELEASE_DIR / "provenance.json"
    checksum_path = archive.with_suffix(archive.suffix + ".sha256")

    if args.verify:
        verify(archive, manifest_path, checksum_path)
        print(f"verified {archive}")
        return 0

    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    for stale in BUILD_DIR.glob(f"{package_meta['Id']}-*.plasmoid*"):
        stale.unlink()
    files = package_files()
    manifest = source_manifest(files)
    write_json(manifest_path, manifest)
    write_json(sbom_path, create_sbom(manifest))
    digest = build_archive(archive, files)
    checksum_path.write_text(f"{digest}  {archive.name}\n", encoding="ascii")
    write_json(provenance_path, {
        "_type": "https://in-toto.io/Statement/v1",
        "subject": [{"name": archive.name, "digest": {"sha256": digest}}],
        "predicateType": "https://slsa.dev/provenance/v1",
        "predicate": {
            "buildDefinition": {
                "buildType": "https://github.com/MCC45TR/Plasma6Widgets/file-search/deterministic-zip@v1",
                "externalParameters": {"version": package_meta["Version"]},
                "resolvedDependencies": [{
                    "uri": "source-manifest.json",
                    "digest": {"sha256": sha256_bytes(manifest_path.read_bytes())},
                }],
            },
            "runDetails": {"builder": {"id": "file-search/tools/build_release.py"}},
        },
    })
    if args.gpg_key:
        if not shutil.which("gpg"):
            raise RuntimeError("gpg is required for signing")
        subprocess.run([
            "gpg", "--batch", "--yes", "--local-user", args.gpg_key,
            "--armor", "--detach-sign", "--output", str(archive) + ".asc", str(archive),
        ], check=True)
    verify(archive, manifest_path, checksum_path)
    print(f"built {archive} ({digest})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        print(f"release build failed: {error}", file=sys.stderr)
        raise SystemExit(1)
