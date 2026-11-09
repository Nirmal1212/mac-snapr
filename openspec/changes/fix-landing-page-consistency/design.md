# Design

## Context

The site is static (`site/index.html`, `styles.css`, `assets/`), published by GitHub Pages from `main`. The beta.2 release notes state no automatic updates and no network access. `scripts/package.sh` only writes Sparkle keys when `SU_FEED_URL` and `SU_PUBLIC_ED_KEY` are both set, so a build without them has updates disabled. See proposal.md for the full list of defects.

## Goals / Non-Goals

**Goals:**
- Every factual claim on the page can be traced to the release notes, README or source.
- Keep the page a single static file with no scripts or third-party assets.

**Non-Goals:**
- No change to the app, Sparkle configuration or release process.
- No redesign of the page.

## Decisions

- **Release notes are the source of truth for the beta's behavior.** The page follows them (no updates, no network). The update-check text moves to a short "coming in a later release" note. Alternative: keep describing Sparkle as current; rejected because it contradicts the shipped notes.
- **Assumption:** beta.2 was built without a Sparkle feed, as its notes state. If the owner confirms otherwise before implementation, the privacy wording is flipped to describe the optional check and the release notes are fixed instead.
- **Version string is written once in a short comment-marked spot** (hero badge, install step 1) and updated per release; no build step is introduced.
- **Social image:** copy `assets/linkedin/snapr-linkedin-1.png` (1200x627) to `site/assets/og-image.png`; reference it by absolute URL because crawlers do not resolve relative paths.
- **Screenshots:** capture real ones of the popover and Settings on a Mac. Fallback if not available at implementation time: ship without them and keep the task open, rather than using mockups presented as the app.
- **Gatekeeper steps live only in Install;** FAQ links to `#install`.

## Risks / Trade-offs

- [Version string drifts at the next release] → add a release-checklist line to `docs/releasing.md`.
- [Absolute og URLs break on a custom domain] → keep them in one block of `<head>` so they are easy to change.
