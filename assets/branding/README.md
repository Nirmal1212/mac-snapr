# Snapr branding

## Concept
A window split into panes, with one pane "snapped" into place and lit in amber while the others stay neutral.
Two white panes plus one accent pane form a half + two quarters layout, the core of what Snapr does.
Original geometry; no third-party marks.

## Palette
| Role | Hex |
|------|-----|
| Indigo (top of background) | `#4C5BE8` |
| Deep indigo (bottom, wordmark text) | `#1E2380` |
| Amber (accent, light to deep) | `#FFD54A` to `#FF9F1C` |
| Pane white to lavender | `#FFFFFF` to `#D9DDFB` |
| Menu bar glyph | black on transparent (template image) |

## Files
- `app-icon.svg`: 1024 canvas, 824px rounded body (Big Sur grid, 100px margin), gradient + soft shadow.
- `logo.svg`: the mark alone (body only, no margin or shadow); use on the website.
- `wordmark.svg`: mark + "Snapr" (live text, system font stack; outline it in an editor for exact rendering).
- `favicon.svg`: simplified mark for 16-64px.
- `menubar-glyph.svg`: 18pt template glyph. Output `MenuBarIconTemplate.png` (18px) and `@2x` (36px).
- Generated: `AppIcon.icns`, `MenuBarIconTemplate*.png`, `png/*`.

## Usage
- Clear space: at least 1/4 of the mark's width on every side; minimum size 16px (use `favicon.svg` below 32px).
- Do not recolor the mark, rotate it, add effects, or stretch it. On very dark backgrounds the indigo mark keeps working; use the wordmark text in white (`#FFFFFF`) there.
- The menu bar glyph must stay a black-on-transparent template image so macOS tints it for light/dark.

## Regenerating
```bash
scripts/make-icons.sh
```
Uses only built-in macOS tools: `swiftc` (scripts/render-svg.swift renders SVG through AppKit, macOS 13+) and `iconutil`.
Re-run it after editing any SVG, then commit the generated files.
