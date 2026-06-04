# Honeycomb (hex) panel

A perforated hex-grid surface — light, rigid, good airflow. Used for shelf tiles,
basket walls, vents. Cut holes out of a solid plate, leaving a solid border.

## Generator (centred grid)

Generate the hex pattern centred on the origin (a hex centre sits at 0,0) so you
can place/clip it deterministically:

```scad
module hex_pattern_centered(R, hex_w, web) {
    hex_R = hex_w / sqrt(3);        // circumradius for pointy-top hex
    pitch_x = hex_w + web;
    pitch_y = pitch_x * sqrt(3) / 2;
    n = ceil(R / pitch_x) + 2;
    m = ceil(R / pitch_y) + 2;
    for (j = [-m : m], i = [-n : n]) {
        ox = (j % 2 == 0) ? 0 : pitch_x / 2;
        translate([i * pitch_x + ox, j * pitch_y])
            rotate([0, 0, 90]) circle(r = hex_R, $fn = 6);   // pointy-top
    }
}
```

Cut it from a floor, clipped to an inset field so a solid `border` survives:

```scad
difference() {
    cube([w, h, floor_th]);                                  // the plate
    translate([0, 0, -EPS]) linear_extrude(floor_th + 2*EPS)
        intersection() {
            hex_pattern_centered(max(w, h), hex_width, hex_web);
            translate([border, border]) square([w - 2*border, h - 2*border]);
        }
}
```

## Uniform border around a cutout

To leave the **same `border` width** around an interior cutout (e.g. a post
notch) as around the edges, subtract `(cutout expanded by border)` from the hole
region — don't let the honeycomb run ragged up to the cutout:

```scad
difference() {
    intersection() { hex_pattern_centered(...); inset_field; }
    translate([notch_x - (notch + 2*border)/2, notch_y - (notch + 2*border)/2])
        square(notch + 2*border);          // solid frame of width `border` around it
}
```

## ⚠️ `use` does NOT import EPS / $fn

`use <../../lib/common.scad>` imports **modules and functions only — not
variables**. So `EPS` and `$fn = $preview ? 32 : 96;` are *undefined* in a file
that only `use`s the lib. Symptom: `translate([x, y, -EPS])` becomes
`translate([x, y, undef])`, silently dropped → holes land in the wrong place
(e.g. honeycomb only in one quadrant). Restate them at the top of the file:

```scad
use <../../lib/common.scad>
EPS = 0.01;
$fn = $preview ? 32 : 96;
```

## Symmetry facts (these bite if you don't know them)

A hex lattice has mirror axes every **30°** (0/30/60/90/120/150) and 6-fold
rotation. Consequences:

- **Diagonal (45°) mirror symmetry is impossible by shifting.** No horizontal/
  vertical translation puts a mirror axis on 45°. To make a tile symmetric about
  its diagonal you must **rotate the grid 15°** (`rotate(15)` lands a vertex-axis
  on 45°). Shifting only buys symmetry about the horizontal/vertical centrelines.
- **Identical tiles rotated 90° never tile continuously.** A hex lattice is
  6-fold, not 4-fold, so a 90°-rotated copy is a *different* orientation →
  patchwork seams.
- **For a continuous pattern across tiles, anchor ONE grid at the shared origin
  and place tiles by MIRRORING.** Mirroring across X or Y leaves an axis-aligned
  hex lattice invariant, so the holes line up across every seam. Cost: the tiles
  become two mirror variants (`tile` + `tile-mirror`) instead of one part.

See `models/filament-rack/filament-rack.scad` (tiles share a cell-anchored grid,
placed by `mirror([1,0,0])` / `mirror([0,1,0])`) and `models/cat-basket/` (simple
clipped honeycomb walls).
