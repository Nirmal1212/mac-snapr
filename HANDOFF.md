# Handoff: Snapr (mac-snapr)

## Goal
OpenSpec repo for a simple macOS window-management utility (Windows-style snap). Name: **Snapr**; repo `mac-snapr`; bundle id `com.you.snapr`.

## State
- Scaffold complete (OpenSpec layout): `openspec/project.md`, `openspec/changes/add-window-management/{proposal,design,tasks}.md`, 5 specs (window-snapping, keyboard-shortcuts, multi-display, drag-snapping, menu-bar-app), `AGENTS.md`, `README.md`.
- Not yet validated: run `openspec init` then `openspec validate add-window-management --strict`.
- Remote: https://github.com/Nirmal1212/mac-snapr contains only LICENSE. Scaffold not pushed (cloud session lacked GitHub push access).
- Open question: default shortcut modifiers (Ctrl+Opt assumed).

## Next steps
1. Clone/open `~/Development/git/mac-snapr`, copy this scaffold in (excluding `.git`), commit, push.
2. `npm i -g @fission-ai/openspec && openspec init && openspec validate add-window-management --strict`
3. Implement per `tasks.md`; archive with `openspec archive add-window-management --yes`.

## Preferences
Keep responses minimal and to the point. Commit messages: Conventional Commits.
