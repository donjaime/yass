# Landing page assets

Every image the page uses lives here, at a fixed path, so new graphics replace files without touching `index.html`. The files here now are placeholders: each one carries the marker `yass-placeholder` (an SVG comment, or a PNG `tEXt` chunk), and `tests/site.sh --deploy`, which the Pages workflow runs before it publishes, fails while any file still has it. Real graphics shouldn't contain the marker.

| File | Required | Spec | Where it shows |
|---|---|---|---|
| `logo.svg` | yes | about 320×96 (the page draws it at up to 240 px wide); legible on the light (`#fbf9f6`) and dark (`#15131a`) backgrounds; keep the `viewBox` | top of the hero, with "YASS!" as its alt text |
| `favicon.svg` | yes | square; reads at 16 px | browser tab |
| `favicon-32.png` | yes | 32×32 | browser tab, for browsers without SVG favicons |
| `apple-touch-icon.png` | yes | 180×180, opaque (no transparency) | home-screen icon on iOS |
| `og.png` | yes | 1200×630; keep text inside the central 1000×500, since some apps crop | the preview card when someone shares a link to the page |
| `logo-dark.svg` | no | same as `logo.svg`, for dark mode, if one logo can't work on both | add `<picture><source srcset="assets/logo-dark.svg" media="(prefers-color-scheme: dark)">…</picture>` around the hero's `<img>` |
| `hero.svg` or `hero.png` | no | about 480×360, transparent background | beside the hero text on wide screens, in place of the log card; hidden on phones is fine. Swap it into the hero's `<figure>` (the comment there shows how) |

`tests/site.sh` checks that the required files exist, that the page references them, and that the PNGs have the sizes above. Everything the page loads, except `og.png`, has to stay under 150 KB in total, so prefer SVG and compress PNGs.
