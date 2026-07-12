# Changelog

## 1.3.0 - 2026-07-12

- Replaced the legacy process/argv KWallet bridge with native session-bus calls.
- Enforced disabled-prefix policy before backend dispatch and result activation.
- Replaced RSS synchronization with a bounded HTTPS-only parser, private-network and redirect policy, atomic per-source writes, and one queued batch merge.
- Added weather request debounce, generation guards, and XHR cancellation.
- Removed metadata-cache thrash, full RSS object copies, redundant startup work, and per-scroll coordinate mapping.
- Virtualized bounded pinned views and lazily instantiated history previews.
- Removed unused fonts and duplicate legacy gettext catalogs.
- Added deterministic packages, source manifest, SPDX SBOM, checksum, provenance, GPG release gate, CI, security tests, and performance budgets.
