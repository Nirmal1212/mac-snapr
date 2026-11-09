# Tasks

## 1. Content accuracy in site/index.html

- [x] 1.1 Remove "no release with all of it has shipped yet"; add a Beta badge and current version near the hero and Download button. Verify: `grep -n "has shipped yet" site/index.html` returns nothing and the badge is visible in a local preview.
- [x] 1.2 Rewrite the privacy section and the update FAQ to match the beta.2 release notes (no automatic updates, no network access; update checks planned for a later release). Verify: no "daily" or "optional update check" claim remains in `site/index.html`.
- [x] 1.3 Replace `Snapr-<version>.dmg` with `Snapr-0.1.0-beta.2.dmg` and state Apple silicon and Intel support. Verify: placeholder text is gone.
- [x] 1.4 Add the Accessibility re-grant note (including `tccutil reset`) and the bundle-identifier-will-change note to install step 3 and the FAQ. Verify: both notes render in the preview.
- [x] 1.5 Replace the duplicated Gatekeeper FAQ steps with a link to `#install`. Verify: steps appear once and the link scrolls to Install.
- [x] 1.6 Check the hero mock's `aria-label` against the CSS animation and correct it if it does not match. Verify: the described start and end states match `styles.css`.

## 2. Social preview and visuals

- [x] 2.1 Copy `assets/linkedin/snapr-linkedin-1.png` to `site/assets/og-image.png`; add `og:url`, absolute `og:image`, `twitter:image` and set `twitter:card` to `summary_large_image`. Verify: the tags appear in the page source and the image URL resolves after deploy.
- [ ] 2.2 Capture real screenshots of the menu bar popover and Settings on a Mac, add them to `site/assets/` and the page. Verify: images render in light and dark mode with alt text; if capture is not possible, record that in the PR and leave this task open.

## 3. Docs consistency

- [x] 3.1 Update `README.md` status, install and screenshots lines to reflect the published betas. Verify: no "No public release has been published yet" remains.
- [x] 3.2 Update the pre-launch checklist in `site/README.md` and add a "bump version on the page" line to `docs/releasing.md`. Verify: both files read consistently with the page.

## 4. Verification

- [x] 4.1 Preview with `python3 -m http.server -d site 8000` at desktop and phone width, check all links, and run `openspec validate fix-landing-page-consistency --strict`. Verify: no broken links and validation passes.
