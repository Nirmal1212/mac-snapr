# Proposal

## Why

A review of the landing page (`site/index.html`) against the README, `docs/release-notes/0.1.0-beta.2.md` and `scripts/package.sh` found statements that contradict what has shipped. Two betas are public (`v0.1.0-beta.1`, `v0.1.0-beta.2`), so these must be fixed before the launch announcement sends traffic to the page.

## What Changes

- Replace "no release with all of it has shipped yet" with accurate public-beta wording and name the current version.
- Label the product as a beta near the hero and the Download button, and set expectations (rough edges, report issues).
- Make the privacy and update statements match the shipped build: the beta has no automatic updates and no network access; the Sparkle update check is described as a later, opt-in release feature.
- Add the Accessibility re-grant note (ad-hoc signed builds are treated as a new app after each update) to install step 3 and the FAQ, plus a note that the bundle identifier will change before 1.0.
- Replace the `Snapr-<version>.dmg` placeholder with the current beta file name and state that the DMG runs on Apple silicon and Intel.
- Add Open Graph and Twitter card metadata with an absolute `og:image`, `og:url` and `twitter:image`, and use the `summary_large_image` card.
- Align the README with the landing page: remove "No public release has been published yet" and the stale install and screenshot status, and update `site/README.md` pre-launch checklist.
- Replace the duplicated Gatekeeper instructions in the FAQ with a link to the Install section.
- Verify and, if needed, correct the hero mock's `aria-label` so it matches the animation.
- Add real screenshots of the menu bar popover and Settings to the page (see design for the fallback).

## Capabilities

### New Capabilities
- `landing-page`: content accuracy, beta status, install guidance, privacy statements and social-preview metadata of the public site in `site/`.

### Modified Capabilities

## Impact

- `site/index.html`, `site/styles.css`, `site/assets/` (new `og-image.png`, screenshots).
- `README.md`, `site/README.md`.
- No application code, no change to `updates` or `distribution` behavior.
- Deploys through the existing GitHub Pages workflow when merged to `main`.
