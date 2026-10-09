# Changelog

Notable changes to Konechi. `release.sh` publishes the section for the version being released as
its release notes, and stops if that section is missing or empty — so before releasing, rename
`Unreleased` to `[x.y.z] - YYYY-MM-DD` and commit.

Versions up to v0.1.2 predate this file; their history is in `git log`.

## [0.1.4] - 2026-10-09

### Changed

- The update window now follows the Mac's language, so it appears in Japanese on a Japanese
  Mac. It was always in English before.

### Fixed

- Show the connection on IPv6-only networks instead of reporting it as offline.
- Read 64-bit interface byte counters so throughput stays correct past 4 GiB.

### Internal

- The build verifies the SHA-256 of the Sparkle archive it downloads.
- The release script runs the self test, and refuses a dirty working tree, a commit that is not
  on origin/main, an existing tag, a version the built app does not carry, or a missing
  changelog section.
