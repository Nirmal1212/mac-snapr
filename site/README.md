# Snapr landing page

Static site: `index.html`, `styles.css`, `assets/`. No build step, no third-party scripts, fonts or trackers.

## Preview

```bash
python3 -m http.server -d site 8000
# open http://localhost:8000
```

## Publish with GitHub Pages

`.github/workflows/pages.yml` deploys `site/` whenever it changes on `main` (or when run manually from the Actions tab).

One-time setup: in the repo go to Settings, Pages, and set Source to "GitHub Actions". The first deploy happens on the next push to `main` that touches `site/`, or run the "Pages" workflow manually.

The site appears at `https://nirmal1212.github.io/mac-snapr/`. All links are relative, so the project subpath works.

To update the site: edit files in `site/` on a feature branch, merge to `develop`, and it goes live when `develop` is merged to `main` as part of a release. For an urgent fix, use a `hotfix/` branch from `main`.

Note: the `github-pages` environment only accepts deploys from `main` by default, which matches Git Flow.

Before sharing the link:
- Keep the version string (hero badge, install step 1, privacy section, FAQ) in sync with the latest release; releases `v0.1.0-beta.1` and `v0.1.0-beta.2` are already published.
- `og:image` is `assets/og-image.png` (1200x627) referenced by absolute URL; check the preview with a social card validator after deploying.
- Add real screenshots of the menu bar popover and Settings (still pending).
