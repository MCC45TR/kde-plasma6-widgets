# MFile Finder Security Model

## Trust boundaries

- Search text is untrusted input. Disabled command-capable prefixes are rejected by `QueryPolicy.js` before both backend dispatch and result activation.
- RSS XML, redirects, URLs and cache files are untrusted. Production RSS accepts HTTPS only, rejects URL credentials, non-standard ports, private/local/reserved address answers and unsafe redirect targets, and applies body, time, XML depth, entry and field limits.
- RSS item links must be HTTPS. Remote item images are accepted only from the already-approved feed host. UI text remains plain text.
- Weather responses are generation-scoped. Replaced requests are aborted and stale callbacks cannot update UI or persistent cache.

## Secrets

Weather API keys are read and written through the Plasma 6 session-bus KWallet interface. Secret values are not encoded into shell commands, process arguments, executable source names or logs. The legacy `secret_store.sh` process bridge is intentionally absent.

## Files and processes

RSS cache files live under the per-user cache directory, use mode `0600`, and are published with atomic rename. The cache directory is mode `0700`; symlinked cache roots and oversized cache files are rejected. RSS workers write only their own source file and a single queued merge publishes `combined.json`.

The remaining executable data-source calls are limited to non-secret local desktop operations and the fixed RSS launcher. User-controlled path values passed to legacy desktop helpers are shell-escaped. New secret or network-sensitive functionality must use typed Qt/KDE/DBus APIs instead of command strings.

## Release integrity

`tools/build_release.py` creates a deterministic archive from `metadata.json` and `contents/`, a source SHA-256 manifest, SPDX 2.3 SBOM, checksum and in-toto/SLSA provenance statement. CI rebuilds and byte-compares the archive. Tags matching `file-search-v*` fail unless a configured GPG private key signs the artifact and the detached signature verifies.

Run `tests/run_checks.sh` before release. Security regressions cover prefix policy, RSS bounds/schemes/private addresses, atomic cache writes, secret transport, lazy startup, weather cancellation and package/source integrity.
