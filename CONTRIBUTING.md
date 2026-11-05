# Contributing

## Getting started
Requirements: macOS 13+, Xcode 15+ (or a Swift 5.9+ toolchain), and for the checks below:
```bash
brew install swiftlint
npm install -g @fission-ai/openspec
```

Build, test and lint (CI runs the same):
```bash
swift build
swift test
swiftlint lint --strict
openspec validate --all --strict
```

Run the app:
```bash
swift run                 # quick runs; Accessibility is granted to your terminal app
scripts/package.sh        # builds dist/Snapr.app; then: open dist/Snapr.app
```
Packaged builds are ad-hoc signed, and the signature changes on every build, so macOS stops trusting the Accessibility grant. After a rebuild, reset and re-grant it:
```bash
tccutil reset Accessibility <bundle id>      # default bundle id is in scripts/package.sh
```
Window control, hotkeys, event taps and UI code can only be verified on a real Mac, so say in your PR what you tried by hand.

## Workflow: OpenSpec
Behavior changes are specified first. The `openspec/` folder holds current specs (`specs/`) and in-flight changes (`changes/`).
1. Propose: create `openspec/changes/<change-id>/` with `proposal.md`, `design.md`, `tasks.md` and spec deltas under `specs/<capability>/spec.md`. The change id is kebab-case, verb-led (`add-layout-engine`).
2. Validate: `openspec validate <change-id> --strict`.
3. Implement by following `tasks.md`, ticking tasks as you finish them.
4. Archive once all tasks are done and the change is merged: `openspec archive <change-id> --yes`. This applies the deltas to `openspec/specs/`. Archive a change that others depend on first. Replace the placeholder Purpose line it writes into any new spec.
Small fixes that do not change behavior (typos, lint, refactors with no spec impact) need no change.

## Branching: Git Flow
| Branch | Purpose | Branches from | Merges into |
|---|---|---|---|
| `main` | Released code only; every commit is a tagged release (`vX.Y.Z`) | n/a | n/a |
| `develop` | Integration branch for the next release | `main` | n/a |
| `feature/<change-id>` | One OpenSpec change (or `fix/<topic>` for a small fix) | `develop` | `develop` (PR, `--no-ff`) |
| `release/X.Y.Z` | Stabilise a release: version bump, docs, fixes only | `develop` | `main` and `develop` |
| `hotfix/X.Y.Z` | Urgent fix on a released version | `main` | `main` and `develop` |

Rules
- Do not commit directly to `main` or `develop`; open a pull request. (Branch protection is not enabled yet; follow this by convention.)
- Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `style:`, `test:`).
- A PR is ready when CI is green (SwiftLint, build, tests), `openspec validate --all --strict` passes, new behavior has tests, and the PR says what was verified by hand.
- Keep pure logic in `SnaprCore` behind the `WindowProvider`/`ScreenProvider` protocols so it can be unit tested; OS access lives in `Sources/Snapr`.
- No network access or telemetry beyond the optional update check. No new third-party dependency without a reason in the PR.

## Releasing
1. Branch `release/X.Y.Z` from `develop`. Pick the version and a higher build number (Sparkle compares it); they are passed to `scripts/package.sh` as `VERSION` and `BUILD_NUMBER`, there is no version file.
2. Follow `docs/releasing.md` to build, sign, notarize and publish. Fixes during stabilisation go on the release branch.
3. Merge `release/X.Y.Z` into `main` with `--no-ff` and tag `vX.Y.Z`. The tag triggers the release workflow, which attaches a DMG to a GitHub Release. Merging to `main` also publishes `site/` through the Pages workflow.
4. Merge `main` back into `develop`.

## Settings search
- Every new settings control must add a search entry (id, title, keywords) to `Sources/SnaprCore/SettingsCatalog.swift` in its section, and mark the control with `.settingTarget("<same id>")` so search can scroll to and highlight it. The unit tests check that sections have entries, ids are unique, and every entry has a matching anchor, but cannot detect a control that has no entry, so reviewers check this.
- A new settings section is added to the `SettingsSection` enum (title, symbol, `idPrefix`, `searchEntries`) and the detail switch in `SettingsView.swift`.
