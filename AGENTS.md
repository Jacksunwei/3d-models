# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Parametric 3D-printable models written in OpenSCAD. Each model lives in
`models/<name>/` with a `.scad` source, README, and `exports/` folder for
generated STLs and PNG previews. Shared helpers live in `lib/common.scad`.

## OpenSCAD CLI

The CLI binary is **not on PATH**. Use the full path:

```
/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
```

(This is the `openscad@snapshot` cask install — `OpenSCAD version 2026.04.26`.
The plain `openscad` cask only ships a stub; do not use it.)

### Render STL

```bash
"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" \
  -o models/<name>/exports/<name>.stl \
  models/<name>/<name>.scad
```

### Render PNG preview

```bash
"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" \
  -o models/<name>/exports/<name>.png \
  --imgsize=1400,900 --colorscheme=Tomorrow \
  models/<name>/<name>.scad
```

### Render a parametric variant

```bash
"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" \
  -D 'output="full"' \
  -o exports/router-stand-full.stl \
  models/router-stand/router-stand.scad
```

### Top-down ortho preview (useful for verifying corner alignment)

```bash
"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" \
  -o /tmp/top.png --imgsize=1600,1000 --colorscheme=Tomorrow \
  --camera=0,0,0,0,0,0,500 --projection=ortho \
  models/<name>/<name>.scad
```

## Model conventions

- **Units in millimeters.**
- **Top-of-file parameters** grouped with `/* [Section] */` headers so OpenSCAD's Customizer panel picks them up. Body in modules, top-level call at the bottom.
- **Shared helpers** live in `lib/common.scad`; import with `use <../../lib/common.scad>`. The shared file sets `$fn = $preview ? 32 : 96;` (snappy previews, smooth renders).
- **Print orientation:** design each model to print flat on the bed with **no supports**. L-walls and overhangs sit fully on top of their parent post — don't cantilever features into mid-air.
- **Variants via an `output` string** (see `models/router-stand/`) — top-level dispatch on a string variable (`"half"`, `"full"`, `"assembly"`) lets one `.scad` file serve printable parts AND assembly previews.

## Print bed constraint

User's printer (a Bambu Lab) has a **256 × 256 mm bed**. Anything whose
bounding box exceeds that on any axis must be split. The router-stand model
illustrates the pattern: design as one logical piece (`stand_full()`), then
expose a `stand_half()` that prints the left half; user prints 2 copies and
rotates one 180°. The router/switch above lock the halves together by
gravity — no fasteners needed.

## When adding a new model

Create `models/<name>/` with:
- `<name>.scad` — parametric source
- `README.md` — parameters table, print settings, assembly notes
- `exports/` — STL + PNG preview (commit them for browsability)

Add a row to the root `README.md` model table.
