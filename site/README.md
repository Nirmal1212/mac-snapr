# Snapr landing page

Static site: `index.html`, `styles.css`, `assets/`. No build step, no third-party scripts, fonts or trackers.

`assets/logo.svg` is a placeholder and also serves as the favicon; replace the file in place (keep the path).

## Preview

```bash
python3 -m http.server -d site 8000
# open http://localhost:8000
```

## Publish with GitHub Pages

The repo has no deploy workflow on purpose. Publish manually.

With Git Flow, publish from `main` after a release:

1. After a release is merged to `main`, either copy `site/` into `/docs` on that branch, or add an Actions workflow of your own (Pages serves only `/` or `/docs` from a branch).
2. In the repo go to Settings, Pages, choose "Deploy from a branch", select `main` and the folder, and Save.
3. The site appears at `https://nirmal1212.github.io/mac-snapr/`. All links are relative, so a project subpath works.

The footer LICENSE link points at the `develop` branch; change it to `main` after the first release.
