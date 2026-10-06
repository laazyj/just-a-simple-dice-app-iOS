# Pins the SwiftLint image CI runs (see the "SwiftLint" job).
# Kept as a Dockerfile so Dependabot's docker ecosystem can update it;
# Dependabot doesn't track container: images inside workflows.
FROM ghcr.io/realm/swiftlint:0.57.0@sha256:012687cd214bab0ea50ab0b0bfbf1a803b7d25c90765a04d1d2b56aae78830d9
