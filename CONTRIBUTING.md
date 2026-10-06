# Contributing

This project doesn't accept pull requests (see the [README](README.md#contributing)),
but these notes cover the local tooling for anyone maintaining it or a fork.

## Local checks

The secret scan ([gitleaks](https://github.com/gitleaks/gitleaks)) and
workflow audit ([zizmor](https://docs.zizmor.sh)) that CI runs can also run
locally before each commit via the repo's pre-commit hook. Each tool is
optional: if it isn't installed, the hook skips that check and CI catches it
instead. zizmor only runs when files under `.github/` are staged.

Install the tools:

```sh
brew install gitleaks zizmor
```

Enable the hook once per clone:

```sh
git config core.hooksPath .githooks
```

To run the checks by hand:

```sh
gitleaks git --redact   # scan history for secrets
zizmor .github          # audit workflows and Dependabot config
```

zizmor runs some audits online; set `GH_TOKEN` (e.g.
`GH_TOKEN=$(gh auth token) zizmor .github`) to include them, or pass
`--offline` to skip them.

## Dependencies

Dependabot keeps the GitHub Actions up to date, with a cooldown (see
`.github/dependabot.yml`). Actions are pinned to full commit SHAs with the
version in a trailing comment; Dependabot updates both.

## Toolchain and versioning

CI builds with the Xcode version in `.xcode-version` (selected by the
"Select pinned Xcode" step in each macOS job). Dependabot can't update it: when Apple ships a new Xcode, bump the
file to a version listed in the
[runner image README](https://github.com/actions/runner-images/tree/main/images/macos)
(and the runner label, when a new macOS image is needed).

The app version lives in `Configuration/Version.xcconfig`, shared by all
targets. Don't set `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` in the
target build settings — they'd override the xcconfig.
