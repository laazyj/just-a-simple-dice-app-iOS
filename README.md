# JASDA - Just A Simple Dice App

[![CI](https://github.com/laazyj/just-a-simple-dice-app-iOS/actions/workflows/ci.yml/badge.svg)](https://github.com/laazyj/just-a-simple-dice-app-iOS/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![App Store](https://img.shields.io/badge/App_Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/app/jasda-just-a-simple-dice-app/id6797626109)

One die, or two when the game calls for it. Tap **ROLL** or shake your phone. That's it.

**[Download JASDA free on the App Store](https://apps.apple.com/app/jasda-just-a-simple-dice-app/id6797626109)** — no ads, no tracking, no nonsense.

<img src="docs/screenshots/pr2-die.png" alt="A white die showing five on a felt-green background, above a ROLL button" width="300">

## Why

Built for casual family gaming — board games on vacation, settling who goes
first, replacing the die that rolled under the sofa. Every dice app on the
store seems to bury a random number behind ads, pop-ups, cookie banners,
tracking, and in-app purchases.

This is just a nice skin over a random number generator:

- **No ads. No pop-ups. No cookies. No tracking. No in-app purchases.**
- No accounts, no analytics, and no network access at all — the app
  ships with a privacy manifest declaring zero data collection.
- Fair rolls from the system's cryptographic RNG.
- Haptic feedback and full VoiceOver support.

## Building

Open `JustASimpleDice.xcodeproj` in Xcode 26 or later and hit Run (CI pins
the exact version in [`.xcode-version`](.xcode-version)).
No dependencies, no package resolution, nothing to install.

## Testing

`⌘U` in Xcode, or:

```sh
xcodebuild test \
  -project JustASimpleDice.xcodeproj \
  -scheme JustASimpleDice \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

CI runs the same suite on every push and pull request — plus SwiftLint,
actionlint, gitleaks, and zizmor — and uploads a simulator screenshot as a
build artifact. See [CONTRIBUTING.md](CONTRIBUTING.md) to run the security
checks locally.

## Shipping your own build

1. Set your bundle identifier and signing team in Xcode.
   The home-screen name is **JASDA**; use the full
   "JASDA - Just A Simple Dice App" (exactly 30 characters) as the
   App Store Connect app name.
2. Product → Archive → Distribute App.
3. The App Store privacy questionnaire answers are all "No" —
   the app collects nothing.

## Contributing

This project is intentionally finished and doesn't accept pull requests —
adding features is how apps like this go bad. It's MIT licensed, so fork
away and make it your own.

## Privacy

JASDA collects nothing — see [PRIVACY.md](PRIVACY.md). Security reports:
see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) — free to use, copy, and modify.
