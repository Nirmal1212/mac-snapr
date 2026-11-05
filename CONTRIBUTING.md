# Contributing

Branching follows Git Flow.

| Branch | Purpose | Branches from | Merges into |
|---|---|---|---|
| `main` | Released code only; every commit is a tagged release (`vX.Y.Z`) | n/a | n/a |
| `develop` | Integration branch for the next release | `main` | n/a |
| `feature/<openspec-change-id>` | One OpenSpec change | `develop` | `develop` (PR, `--no-ff`) |
| `release/X.Y.Z` | Stabilise a release (version bump, docs, fixes only) | `develop` | `main` and `develop` |
| `hotfix/X.Y.Z` | Urgent fix on a released version | `main` | `main` and `develop` |

Rules
- Never commit directly to `main` or `develop`; open a pull request.
- Feature branch name matches the OpenSpec change id, e.g. `feature/add-layout-engine`.
- Conventional Commits. CI (build, test, lint) must pass; `openspec validate --all --strict` must pass.
- Releasing: branch `release/X.Y.Z` from `develop`, then merge into `main` with `--no-ff`, tag `vX.Y.Z` (the tag triggers the release workflow), and merge back into `develop`.
- After a feature merges, archive its change with `openspec archive <id> --yes` (archive `add-window-management` first).

Settings search
- Every new settings control must add a search entry (id, title, keywords) to `Sources/SnaprCore/SettingsCatalog.swift` in its section, and mark the control with `.settingTarget("<same id>")` so search can scroll to and highlight it. The unit tests check that sections have entries and ids are unique, but cannot detect a control that has no entry, so reviewers check this.
- A new settings section is added to the `SettingsSection` enum (title, symbol, `idPrefix`, `searchEntries`) and the detail switch in `SettingsView.swift`.
