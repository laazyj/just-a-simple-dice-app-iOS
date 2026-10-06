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
- **Linter images** (SwiftLint, actionlint) are pinned by tag and digest in
  `.github/linters/*.Dockerfile`. CI runs the image named on the `FROM`
  line; the files exist so Dependabot's docker ecosystem can see them.
  Match your local `swiftlint` to that version.

The app itself has no dependencies.

## Pull requests

PRs are squash-merged, and the title must follow
[Conventional Commits](https://www.conventionalcommits.org) (`feat:`,
`fix:`, `ci:`, ...) — the PR title check enforces it. Release tooling reads
those titles to pick the next version and write the changelog.

## Toolchain and versioning

CI builds with the Xcode version in `.xcode-version` (selected by the
"Select pinned Xcode" step in each macOS job). Dependabot can't update it: when Apple ships a new Xcode, bump the
file to a version listed in the
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

One-time setup (until then the job is skipped):

1. **App Store Connect → Users and Access → Integrations → Team Keys**:
   generate a key with the **Admin** role (cloud-managed distribution
   signing needs it) and download the `.p8`.
2. **GitHub → Settings → Environments**: create `testflight`, limit
   deployment branches to `main`, and add the secrets:
   - `ASC_KEY_ID`: the key ID
   - `ASC_ISSUER_ID`: the issuer ID shown above the keys list
   - `ASC_KEY_P8`: the full contents of the `.p8` file
3. **GitHub → Settings → Secrets and variables → Actions → Variables**:
   add the repository variable `TESTFLIGHT_ENABLED` = `true`.
4. **TestFlight → Internal Testing**: create a group with automatic
   distribution enabled, so new builds reach testers without a click.

To run a lane locally, set `ASC_KEY_ID`, `ASC_ISSUER_ID` and
`ASC_KEY_PATH` (path to the `.p8`), then `bundle install` and
`bundle exec fastlane beta`.

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

One-time setup, on top of the TestFlight setup above:

0. Tag the commit that shipped as 1.0 with `v1.0.0` and push the tag, so
   TestFlight builds know 1.0.0 is closed and use 1.0.1.

1. **Settings → Environments**: create `app-store`, limit it to `main`,
   add yourself as a **required reviewer**, and add the same three `ASC_*`
   secrets.
2. **Settings → Actions → General**: allow GitHub Actions to create pull
   requests.
3. Optional but recommended once checks are required on `main`: add a
   fine-grained personal access token as the `RELEASE_PLEASE_TOKEN`
   repository secret (this repo only; Contents and Pull requests:
   read/write). Release PRs opened with the default token don't trigger CI,
   so their required checks would never report.
