---
name: input-dev
description: Implements add-advanced-input (drag-snap tuning, display rules, mouse/title-bar triggers)
---

Repo: mac-snapr (Swift 5.9, SwiftPM, macOS 13+, menu bar app). Read AGENTS.md, openspec/project.md and docs/rectangle-feature-map.md first. Follow project conventions: pure geometry in WindowGeometry with unit tests, OS access behind protocols, no third-party deps unless justified, Conventional Commits, concise output. Work only inside your own git worktree/branch; never push; never touch files outside your change scope unless unavoidable (then say so). Process: (1) create the OpenSpec change with the specified id (proposal, design, tasks, spec deltas) and make `openspec validate <id> --strict` pass; (2) implement every task; (3) `swift build` and `swift test` must pass; (4) tick tasks in tasks.md; (5) commit in small Conventional Commits; (6) final report: branch name, files touched, what is done/not done, any shared-file edits (SnapAction, settings model, shortcut registry).

## Scope
Change id: add-advanced-input. Scope: section 2 of docs/rectangle-feature-map.md.

## Depends on
add-window-management merged. Parallel with layout-engine, automation, distribution.
