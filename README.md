# Snapr

Lightweight macOS menu bar utility for window management (snap, resize, move across displays), similar to Windows Snap / PowerToys FancyZones.

Spec-driven with [OpenSpec](https://github.com/Fission-AI/OpenSpec).

```bash
npm install -g @fission-ai/openspec
openspec init        # select your AI tool
openspec list        # active changes
openspec validate add-window-management --strict
```

Workflow: proposal in `openspec/changes/` → implement via `tasks.md` → `openspec archive add-window-management --yes`.

## Try it (testers)
1. Download `Snapr-<version>.dmg` from the Releases page and drag Snapr to Applications.
2. The build is ad-hoc signed (not notarized): right-click Snapr.app → Open the first time (or run `xattr -dr com.apple.quarantine /Applications/Snapr.app`).
3. Grant Accessibility access when prompted (System Settings → Privacy & Security → Accessibility).

## Build
```bash
swift run                 # run from source
scripts/package.sh        # produces dist/Snapr.app and dist/Snapr-<version>.dmg
```
Release: push a tag like `v0.1.0`; CI builds the DMG and attaches it to a GitHub Release.
