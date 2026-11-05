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
- Publish a release so the Download button leads to a DMG.
- Add screenshots and an `og:image` for social previews (needs an absolute URL once the site is live).
