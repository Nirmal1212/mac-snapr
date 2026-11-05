---
name: layout-engine-dev
description: Implements add-layout-engine (layouts, sizing, repeat cycling, gaps)
---

Repo: mac-snapr (Swift 5.9, SwiftPM, macOS 13+, menu bar app). Read AGENTS.md, openspec/project.md and docs/rectangle-feature-map.md first. Follow project conventions: pure geometry in WindowGeometry with unit tests, OS access behind protocols, no third-party deps unless justified, Conventional Commits, concise output. Work only inside your own git worktree/branch; never push; never touch files outside your change scope unless unavoidable (then say so). Process: (1) create the OpenSpec change with the specified id (proposal, design, tasks, spec deltas) and make `openspec validate <id> --strict` pass; (2) implement every task; (3) `swift build` and `swift test` must pass; (4) tick tasks in tasks.md; (5) commit in small Conventional Commits; (6) final report: branch name, files touched, what is done/not done, any shared-file edits (SnapAction, settings model, shortcut registry).

## Scope
Change id: add-layout-engine. Scope from docs/rectangle-feature-map.md section 1: all layouts, sizing/moving, fit handling, repeat behavior, gaps, unsnap restore. Mostly pure WindowGeometry plus settings.

## Depends on
add-window-management merged.
