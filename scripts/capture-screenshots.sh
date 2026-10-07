#!/bin/bash
# Captures the App Store screenshots (one die, two dice) on fresh simulators
# of the largest iPhone and iPad, which App Store Connect requires:
#   scripts/capture-screenshots.sh build/app-store-screenshots
set -euo pipefail

out=$(mkdir -p "$1" && cd "$1" && pwd)

# The newest iOS runtime, and its newest iPhone Pro Max and 13-inch iPad Pro.
read -r runtime iphone ipad < <(xcrun simctl list --json runtimes | python3 -c '
import json, re, sys

def numbers(text):
    return [int(n) for n in re.findall(r"\d+", text)]

runtimes = [r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == "iOS" and r["isAvailable"]]
runtime = max(runtimes, key=lambda r: numbers(r["version"]))

def newest(pattern):
    types = [t for t in runtime["supportedDeviceTypes"] if re.fullmatch(pattern, t["name"])]
    return max(types, key=lambda t: numbers(t["name"]))["identifier"]

print(runtime["identifier"], newest(r"iPhone \d+ Pro Max"), newest(r"iPad Pro 13-inch.*"))
')
if [ -z "${ipad:-}" ]; then
  echo "Couldn't find an iOS runtime with an iPhone Pro Max and a 13-inch iPad Pro" >&2
  exit 1
fi

devices=()
cleanup() {
  # macOS's bash 3.2 treats an empty array as unset under set -u.
  for udid in ${devices[@]+"${devices[@]}"}; do
    xcrun simctl shutdown "$udid" || true
    xcrun simctl delete "$udid" || true
  done
}
trap cleanup EXIT

destinations=()
for type in "$iphone" "$ipad"; do
  udid=$(xcrun simctl create "App Store screenshots" "$type" "$runtime")
  devices+=("$udid")
  destinations+=(-destination "platform=iOS Simulator,id=$udid")
  xcrun simctl boot "$udid"
done
# First boots are slow, so they run side by side.
for udid in "${devices[@]}"; do
  xcrun simctl bootstatus "$udid"
  xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi \
    --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 \
    --batteryState charged --batteryLevel 100
done

# xcodebuild passes TEST_RUNNER_-prefixed variables to the tests, minus
# the prefix.
results=build/ScreenshotResults.xcresult
rm -rf "$results"
if ! TEST_RUNNER_SCREENSHOTS_DIR="$out" xcodebuild test \
  -project JustASimpleDice.xcodeproj \
  -scheme JustASimpleDice \
  "${destinations[@]}" \
  -derivedDataPath build \
  -resultBundlePath "$results" \
  -only-testing:JustASimpleDiceUITests/RollUITests/testCaptureStoreScreenshots \
  CODE_SIGNING_ALLOWED=NO; then
  # With several destinations, xcodebuild's log leaves out why tests failed.
  xcrun xcresulttool get test-results summary --path "$results" >&2 || true
  exit 1
fi

count=$(find "$out" -name '*.png' | wc -l | tr -d ' ')
if [ "$count" -ne 4 ]; then
  echo "Expected 4 screenshots in $out, found $count" >&2
  exit 1
fi
ls -l "$out"
