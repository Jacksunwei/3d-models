# Tiles + cross brace (when the opening is itself ~bed-sized)

The normal bed-split (two 180°-rotated halves with a dovetail) only works when
the *whole part* is too big but each half still fits. It fails when the **span
you must cover is itself as large as the bed** — e.g. a shelf that drops into a
~255 mm frame cell on a 256 mm bed. Halving doesn't help: the un-split axis still
spans the full opening and still has to reach the rails (> bed). Split in **both**
axes into quadrant tiles, and carry the unsupported centre with a separate
**cross brace**.

## The kit

- **Cross brace** — a `+` of two bars that rests its four end-feet on the rails,
  spans the opening, and divides it into four quadrants. It carries the centre
  load (there's no rail at the cell centre).
- **4 quadrant tiles** — each rests on the **two perimeter rails** (outer edges)
  and the **two brace arms** (inner edges) → supported on all four edges, so each
  tile is small (~half the opening) and stiff.

## Bearing plane

Pick one Z, `bear`, a few mm above the rail top where *all* supports meet:
- brace top = `bear`; tiles rest on it directly at the inner edges.
- tiles get `bear`-tall feet at the outer edges to reach down to the rail top.
- `bear` also buys clearance over connector bodies that sit slightly proud of the
  rail (measure this — see `fit-to-existing-part.md`).

## Joining tile ↔ brace: hole in brace, stem on tile

Put the **socket in the brace** and the **stem on the tile**. The tile prints
floor-down (flipped), so a downward stem prints *upward* as a clean cylinder; the
brace just gets a drilled hole. Avoid the reverse (a fragile pin standing up on
the brace's centre cross).

## Corner handling (two separate cuts)

- **Post notch** — a through-cut for the connector post that pokes up through the
  floor. Frame it with a uniform `border` (see `honeycomb-panel.md`).
- **Foot relief** — the connector *body* is usually proud of the rail and
  intrudes from the corner; relieve the **feet** (not the floor) over that region
  so the tile doesn't rock. Keep the floor (it clears the body via `bear`).

## Continuous honeycomb across the four tiles

Anchor one hex grid at the **cell centre** and place tiles by **mirroring**, not
rotation (see `honeycomb-panel.md` for why). This makes two mirror variants:
`tile` (for the +x+y and −x−y quadrants, one rotated 180°) and `tile-mirror`
(for +x−y and −x+y). Print 2 of each + 1 brace.

## Diagonal print for the long brace bar

A `+` brace spanning a 255 mm opening is ~270 × 270 mm flat — over a 256 bed. A
single bar is thin, so **rotate the whole brace 45°** for export: the bounding
box drops to ~190–205 mm and it fits. Flip it so the bearing face + end-feet sit
flat on the bed and the beam stands up (no overhangs).

## Export each part bed-ready via the output dispatch

Model everything in *use* orientation, then orient for printing in the `output`
dispatch so each STL drops onto the plate ready to slice:

```scad
if      (output == "assembly")    assembly_preview();                       // use orientation
else if (output == "brace")       rotate([0,0,45]) translate([0,0,bear]) rotate([180,0,0]) brace();
else if (output == "tile-mirror") translate([0,0,bear+floor_th]) rotate([180,0,0]) mirror([1,0,0]) quadrant_tile();
else                              translate([0,0,bear+floor_th]) rotate([180,0,0]) quadrant_tile();
```

## Bed-fit reality check

Two square tiles of side `s` need `2s ≤ bed` to share a plate. For `s ≈ 135` on a
256 bed that's 270 > 256 — so **one tile per plate** (and the brace alone on its
own). State the real plate count instead of promising a combined plate that the
slicer will reject. Only a larger bed (~325) fits the four tiles 2×2.

Full implementation: `models/filament-rack/filament-rack.scad`.
