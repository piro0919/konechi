# CLAUDE.md (Konechi)

How to work in this repository. The behaviour itself is documented elsewhere — do not
restate it here.

## Where the truth lives

- **[SPEC.md](SPEC.md)** — what was decided and why. Open questions stay under 保留.
  Change the text here before changing the implementation, not after
- **[README.md](README.md)** — the outward description: what the app does, how to build it,
  what the menu shows
- **[build.sh](build.sh) / [release.sh](release.sh)** — the comments inside the scripts are the
  procedure. Do not write a second copy of it in prose

## Language

Commit messages, PR titles and bodies, the README, docs, and release notes are written in
English. This file is part of that.

**Comments in the source, SPEC.md, and the explanations inside the shell scripts stay in
Japanese.** That is what the existing code does. Do not translate them.

## Building

Xcode is not needed. The `swiftc` that ships with the Command Line Tools is enough.

```bash
./build.sh          # produces Konechi.app; fetches Sparkle into Vendor/ if missing
open Konechi.app
```

- `Vendor/` is not tracked. If it disappears, `build.sh` fetches it again
- The version is passed in through `KONECHI_VERSION`. Local builds stay at `0.0.0`
- The landing page is a pnpm workspace under `lp/`. Use `pnpm lp:dev` and `pnpm lp:build`

## Gather what you can before asking

Every request costs the other person a turn. Reach for these first.

- `./probe.sh` — prints what the detection logic actually sees. `./probe.sh en0 en9` looks up
  named devices
- `./preview.sh <png>…` — renders artwork at real menu bar size. Legibility can only be judged
  at that size
- `route get default` and `scutil` — read the system state the detection is derived from

If two requests have not resolved something, find a way to read it yourself before asking a
third time.

## Judge artwork at real size

Differences that are obvious in a large image disappear at 17–22pt. As recorded in SPEC.md, the
per-state icons in chappie-desktop were indistinguishable at real size; only the red prohibition
badge read. Run `./preview.sh` whenever the artwork changes.

The icon is **22pt** tall. That is the thickness of the menu bar and the ceiling.

## Releasing

`./release.sh <version>` builds, makes the DMG, signs the update feed, and pushes to GitHub
Releases in one pass.

- **The signing key lives in the login keychain. Lose it and already-installed copies can never
  be updated again**
- `generate_appcast` stops when it sees two archives of the same version. Keep the zip and the
  DMG in separate directories
