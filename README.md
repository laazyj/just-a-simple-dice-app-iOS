# Just a Simple Dice

One die. Tap **ROLL** or shake your phone. That's it.

No ads. No tracking. No monetisation. No nonsense.

## Building

Open `JustASimpleDice.xcodeproj` in Xcode 16 or later and hit Run.
No dependencies, no package resolution, nothing to install.

## Testing

Tests arrive with the dice logic. Until then, CI builds the app on every
push and pull request, and uploads a simulator screenshot as a build
artifact:

```sh
xcodebuild build \
  -project JustASimpleDice.xcodeproj \
  -scheme JustASimpleDice \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
