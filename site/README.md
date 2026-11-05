# Snapr landing page

Static site: `index.html`, `styles.css`, `assets/`. No build step, no third-party scripts, fonts or trackers.

`assets/logo.svg` is a placeholder and also serves as the favicon; replace the file in place (keep the path).

## Preview

```bash
python3 -m http.server -d site 8000
# open http://localhost:8000
```

## Publish with GitHub Pages

The repo has no deploy workflow on purpose. Publish manually:

1. Merge the site to the branch you want to publish (for example `main`).
2. Pages serves only `/` or `/docs` from a branch, so either copy `site/` to `/docs`, or use a Pages deployment from a GitHub Actions workflow you add yourself.
3. In the repo go to Settings, Pages, choose "Deploy from a branch", select the branch and folder, and Save.
4. The site appears at `https://nirmal1212.github.io/mac-snapr/`. All links are relative, so a project subpath works.
