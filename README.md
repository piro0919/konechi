# Konechi

A tiny macOS menu bar app that shows, at a glance, whether your Mac is on
**ethernet or Wi-Fi**.

The stock macOS menu bar only tells you about Wi-Fi — nothing indicates that a
cable is plugged in. Konechi does not guess from what the menu bar looks like.
It reads the **primary interface of the default route** from the system
configuration database (`State:/Network/Global/IPv4`) and decides from that
interface's type. It is looking at the same route `route get default` reports,
so what you see is the link actually carrying your traffic.

The state is expressed through a character's face: on top form for ethernet,
doing fine for Wi-Fi, out of energy when offline. When the route runs through
a VPN, a padlock badge sits on the face of the physical link underneath.

## Build

Xcode is not required — the Swift that ships with the Command Line Tools is
enough. Sparkle, used for updates, is fetched into `Vendor/` on the first
build.

```bash
./build.sh
open Konechi.app
```

## What the menu shows

| Row         | Contents                                                        |
| ----------- | --------------------------------------------------------------- |
| Connection  | Wired / Wi-Fi / Other / Offline, and whether it goes via a VPN   |
| Service     | The name shown in System Settings (e.g. USB 10/100/1000 LAN)     |
| Device      | The BSD name (e.g. `en9`)                                        |
| IP address  | The IPv4 address assigned to it                                  |
| Router      | The default gateway                                              |
| Link speed  | e.g. `1000baseT`. Wi-Fi does not report one, so it shows `-`     |
| Down / Up   | Throughput, measured every second while the menu is open         |

## Settings

Launch at login, language (Japanese / English), icon (character or symbol),
throughput unit, which rows appear in the menu, checking for updates, and the
version.

The language defaults to English, and only falls back to Japanese when the
system is set to Japanese.

## Development

```bash
./probe.sh              # print what the detection logic sees
./probe.sh en0 en9      # look up the type of specific devices
./preview.sh <png>…     # render artwork at its real menu bar size
./mockup.sh             # regenerate the SF Symbols comparison sheet
./Tools/trim.py <png>…  # crop transparent margins using one shared box
```

The app itself takes flags for inspecting states you cannot easily reproduce.

```bash
./Konechi.app/Contents/MacOS/Konechi --state wired|wifi|offline|other
./Konechi.app/Contents/MacOS/Konechi --vpn        # force the padlock badge
./Konechi.app/Contents/MacOS/Konechi --settings   # open with the settings window
```

## Artwork

Drop the images in `Resources/konechi-<state>.png`. Anything missing falls back
to an SF Symbol, so the app runs with none of them present. The prompts used to
generate them live in [docs/art-prompt.md](docs/art-prompt.md).

## Design decisions

See [SPEC.md](./SPEC.md), which also records the approaches that were tried and
dropped, and why.

## Notes

- If you use a menu bar manager such as Ice, a newly added item starts out in
  the hidden section
- Builds are ad-hoc signed. The first launch is met with an "unidentified
  developer" warning; allow it from System Settings

> 仕様の記録（[SPEC.md](./SPEC.md)）と絵の生成に使う指示（[docs/art-prompt.md](docs/art-prompt.md)）は日本語です。
