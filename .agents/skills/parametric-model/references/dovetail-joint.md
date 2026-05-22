# Dovetail joint (for split halves)

Trapezoidal tenon + mortise locking two halves against horizontal pull-apart. Used when the design is split into halves (because the bounding box exceeds the printer bed) and needs more than gravity holding the halves aligned.

## How it works

The cross-section in the X-Y plane is a trapezoid: narrow at the seam (X=0), wider at the tip. The shape is extruded in Z through the full floor thickness. When the tenon enters the matching mortise:

- **Sideways pull-apart (in X) is blocked** — the wide tip can't squeeze back through the narrow opening at the seam.
- **Vertical insertion/removal (in Z) is allowed** — the mortise is open at the top and bottom faces of the rail, so the partner half drops straight down onto the tenon from above.

## 2D primitive

```scad
module dovetail_2d(base_w, tip_w, length) {
    polygon([
        [0,      -base_w/2],
        [length, -tip_w/2],
        [length, +tip_w/2],
        [0,      +base_w/2]
    ]);
}
```

Use `linear_extrude(floor_thickness)` to give it the full rail height. For the mortise, mirror across X (so it opens in the −X direction) and subtract from the half body via `difference()`.

## Symmetry under 180° rotation

The two halves are identical prints — one is rotated 180° about Z at assembly time. For the joint to mate after rotation, put the tenon on **one** long rail at the seam (e.g., the +Y rail) and the mortise on the **opposite** rail (the −Y rail). After 180° rotation:

- Original +Y tenon → now at −Y (matches the partner's −Y mortise after their rotation)
- Original −Y mortise → now at +Y (matches the partner's +Y tenon)

Both pairs interlock symmetrically.

## Sizing rules

| Parameter | Default | Why |
|---|---|---|
| `dt_base_w` (Y width at seam) | 5 mm | Narrow enough to leave rail material on both sides |
| `dt_tip_w` (Y width at tip) | 9 mm | Enough flare for real locking |
| `dt_length` (X extent) | 8 mm | Reaches into the partner's rail without using all of it |
| `dt_offset` (Y centerline from rail outer edge) | `rail_width / 2` | **Always center on the rail** — off-center looks wrong and weakens one side |
| `joint_clearance` | 0.3 mm | Mortise is `2 × joint_clearance` wider per face; printable snug fit |

## Tenon vs mortise extents

```
Tenon (additive):     X from 0 to dt_length,    centered Y at half_w - dt_offset
Mortise (subtractive): X from 0 to -dt_length,  centered Y at -(half_w - dt_offset)
                                                  Y-width expanded by 2*joint_clearance
                                                  X-depth expanded by 1*joint_clearance
```

See `models/router-stand/router-stand.scad` for the full implementation, including the `difference() { union() { ... } mortise }` wrapping pattern needed to subtract from the half.

## Assembly instruction for the README

Always tell the user the joint is **vertical-insert only** — don't let them try to slide the halves together horizontally; the dovetail makes that impossible. Example wording:

> Rotate one half 180° about the vertical axis and **lower it straight down** from above so the dovetail tenons drop into the matching mortises.
