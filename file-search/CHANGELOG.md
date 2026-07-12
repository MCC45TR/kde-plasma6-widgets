# Changelog

## 1.3.0 - 2026-07-12

- Replaced the legacy process/argv KWallet bridge with native session-bus calls.
- Enforced disabled-prefix policy before backend dispatch and result activation.
- Replaced RSS synchronization with a bounded HTTPS-only parser, private-network and redirect policy, atomic per-source writes, and one queued batch merge.
- Added weather request debounce, generation guards, and XHR cancellation.
- Fixed Enter activation so list and button modes launch the selected sorted result and record it in history.
- Wired fuzzy/exact/starts-with and dynamic result-limit settings into ranking, and removed unrelated RSS filler results.
- Reloaded category settings live and centralized locale-tolerant result classification across filters, previews, history, and priorities.
- Persisted per-feed RSS sync timestamps and moved weather forecast payloads from synchronous KConfig writes to an atomic file cache.
- Replaced filename heuristics in terminal launching, tightened desktop-entry detection, and documented IP-based weather location privacy.
- Unified pinned, history, and result headings through a shared Plasma-native category header with inline actions.
- Reworked tile labels to single-line elision with full-name tooltips, removed the pinned card shell, and strengthened keyboard selection with the Plasma highlight style.
- Filled idle tile space with quick command shortcuts and removed the redundant recent-searches heading layer.
- Replaced fixed component font sizes with system-theme scaling, standardized the touched tile spacing/radii, and removed hover assignments that broke theme bindings.
- Migrated component-layer controls from Qt Quick Controls to Plasma Components 3.
- Added a 13-step panel-width slider, shared low/medium/full content opacity, and matched the panel search icon color to its text.
- Removed metadata-cache thrash, full RSS object copies, redundant startup work, and per-scroll coordinate mapping.
- Virtualized bounded pinned views and lazily instantiated history previews.
- Removed unused fonts and duplicate legacy gettext catalogs.
- Added deterministic packages, source manifest, SPDX SBOM, checksum, provenance, GPG release gate, CI, security tests, and performance budgets.
