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

results=build/ScreenshotResults
rm -rf "$results"

udid=""
cleanup() {
  if [ -n "$udid" ]; then
    xcrun simctl shutdown "$udid" || true
    xcrun simctl delete "$udid" || true
    udid=""
  fi
}
trap cleanup EXIT

# One fresh simulator at a time: with two booting and testing at once on a
# CI runner, XCTest timed out launching the app. A brand-new simulator can
# still be busy with first-boot setup, so a failed capture gets one retry.
for type in "$iphone" "$ipad"; do
  udid=$(xcrun simctl create "App Store screenshots" "$type" "$runtime")
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi \
    --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 \
    --batteryState charged --batteryLevel 100

  # xcodebuild passes TEST_RUNNER_-prefixed variables to the tests, minus
  # the prefix.
  TEST_RUNNER_SCREENSHOTS_DIR="$out" xcodebuild test \
    -project JustASimpleDice.xcodeproj \
    -scheme JustASimpleDice \
    -destination "platform=iOS Simulator,id=$udid" \
    -derivedDataPath build \
    -resultBundlePath "$results/$type.xcresult" \
    -only-testing:JustASimpleDiceUITests/RollUITests/testCaptureStoreScreenshots \
    -retry-tests-on-failure -test-iterations 2 \
    CODE_SIGNING_ALLOWED=NO

  cleanup
done

count=$(find "$out" -name '*.png' | wc -l | tr -d ' ')
if [ "$count" -ne 4 ]; then
  echo "Expected 4 screenshots in $out, found $count" >&2
  exit 1
fi
ls -l "$out"
