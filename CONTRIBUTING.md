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

Dependabot keeps CI's dependencies up to date, with a one-week cooldown
and one grouped PR per ecosystem per week (see `.github/dependabot.yml`):

- **GitHub Actions** are pinned to full commit SHAs with the version in a
  trailing comment; Dependabot updates both.
- **SwiftLint's image** is pinned by tag and digest in
  `.github/linters/swiftlint.Dockerfile`. CI runs the image named on the
  `FROM` line; the file exists so Dependabot's docker ecosystem can see it.
  Match your local `swiftlint` to that version.
- **actionlint** runs as the `kjanat/actionlint` action, so Dependabot
  updates it with the other actions.

The app itself has no dependencies.

## Pull requests

PRs are squash-merged, and the title must follow
[Conventional Commits](https://www.conventionalcommits.org) (`feat:`,
`fix:`, `ci:`, ...) — the PR title check enforces it. Release tooling reads
those titles to pick the next version and write the changelog.

## Toolchain and versioning

CI builds with the Xcode version in `.xcode-version`, selected by the
`.github/actions/setup-xcode` action in each macOS job. Jobs reference it
with GitHub's self-repository syntax (`uses: $/.github/actions/...`), which
zizmor requires. Upstream rhysd/actionlint can't parse it, so CI lints
workflows with the maintained fork
[kjanat/actionlint](https://github.com/kjanat/actionlint); switch back once
upstream releases `$/` support.

Dependabot can't update the Xcode version: when Apple ships a new Xcode,
bump `.xcode-version` to a version listed in the
[runner image README](https://github.com/actions/runner-images/tree/main/images/macos)
(and the runner label, when a new macOS image is needed).

The app version lives in `Configuration/Version.xcconfig`, shared by all
targets. Don't set `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION` in the
target build settings — they'd override the xcconfig.

## TestFlight

Every push to `main` that passes CI is built and uploaded to TestFlight by
the **Upload to TestFlight** job (`fastlane beta`). The build number is the
latest one in App Store Connect plus one, and the TestFlight "What to Test"
note is the commit's subject line. Signing is cloud-managed, so no
certificates or provisioning profiles are stored anywhere.

## Releasing to the App Store

[release-please](https://github.com/googleapis/release-please) keeps a
**release PR** open on `main`. It collects the `feat:` and `fix:` titles
merged since the last release, bumps `MARKETING_VERSION` (minor for
features, patch for fixes) and updates `CHANGELOG.md`. Other types (`ci:`,
`test:`, `chore:`, ...) don't trigger a release.

To ship:

1. Merge the release PR. CI tags `vX.Y.Z`, creates the GitHub release, and
   uploads that commit's build to TestFlight as usual.
2. Try the build in TestFlight.
3. Approve the waiting **Submit for App Review** job (the `app-store`
   environment). It submits that exact build with the changelog as
   "What's New", released in phases once Apple approves.

If the TestFlight upload for a release commit didn't happen, submit by
hand with `bundle exec fastlane submit version:X.Y.Z build_number:N`.

App Store Connect closes a version to new builds once it's submitted, so
TestFlight builds from commits after a release tag use the next patch
version (e.g. `1.1.1` after `v1.1.0`) until the next release PR bumps it.
