---
name: parametric-model
description: 'Design a parametric 3D-printable model in this repo — stands, mounts, brackets, holders, enclosures, or any physical accessory for hardware. Use whenever the user wants to model or print a custom physical part for a specific device (router, switch, NAS, hard drive, etc.), measures something to design around it, or says things like "design a stand for X", "make a holder for Y", "model a bracket for Z", "print a part to fit [device]", or shows a photo of hardware they want to accessorize. Covers the full iterative workflow — gathering measurements, parametric OpenSCAD design, rendering visual previews for review, handling print-bed-size constraints, and producing slicer-ready STLs with a README.'
---

# Parametric model design

Workflow for designing a new model in `models/<name>/` of this repo. First read `AGENTS.md` for the repo's conventions (mm units, `/* [Section] */` Customizer headers, `use <../../lib/common.scad>`, print-flat-no-supports, OpenSCAD CLI path) — this skill builds on those.

> **Platform note.** The design workflow and the OpenSCAD code are fully cross-platform — `.scad` files render the same way everywhere. The **shell commands** in Phase 3 (render and show) use Unix conventions (macOS/Linux): `SCAD=...` env var, `"$SCAD"` invocation, `/tmp/top.png` for scratch output. On Windows, substitute: `set SCAD=...`, `%SCAD%`, and a Windows temp path like `%TEMP%\top.png`. The OpenSCAD CLI flags themselves (`-o`, `-D`, `--imgsize`, `--colorscheme`, `--camera`, `--projection`) are identical across platforms.

## Phase 1 — Capture intent and measurements

Don't write geometry until you know:

- **The device(s) the part holds / mounts / elevates.** What it is, its bottom-face footprint (`length × width` in mm), and chassis height. If there are multiple devices (e.g., router on top, switch under), get each one separately.
- **The functional goal.** Elevate for airflow, retain against sliding, mount to a wall, organize cables, etc. The geometry follows from this.
- **Retention needs.** Does the device need to be "captured" so it can't slide off, or is gravity enough? "Some retention is enough" usually means short tabs, not full wraps.
- **Print bed size.** Ask the user which 3D printer they're using if it hasn't already been established in this conversation. Then look up the printer's bed dimensions (web search the model name) so you can constrain the design's bounding box before drafting geometry.
- **Style preferences.** Minimal frame vs. full enclosure, open-air for cooling vs. sealed.
- **Mating object (if any).** If the part must fit an existing frame or device that has published/supplied 3D models, don't guess its geometry — **extract it from the STLs** (bounding box + slice profile), expose the fit dimensions as parameters, and have the user caliper-verify on their printed copy. See `references/fit-to-existing-part.md`.

If the user sends a photo, study the shape (rounded corners, slants, vent locations, antenna positions). Photos clarify form, but you still need numeric measurements — ask for them. Don't infer dimensions from images.

Use **AskUserQuestion** for crisp multi-choice questions (4 options + Other). For open-ended measurements, ask in plain text. **Never guess dimensions** — the user has the device in front of them, and even nominally identical hardware (e.g., "TP-Link Archer") varies between revisions.

It's common to gather measurements over multiple turns. That's fine — confirm what you have, list what you still need, ask again.

## Phase 2 — Draft the `.scad` file

Create `models/<name>/<name>.scad` following the conventions in `AGENTS.md`. For a complete worked example, look at the most recently committed model in `models/` (use `git log models/` to find it) — it'll have the freshest pattern. Skeleton:

```scad
use <../../lib/common.scad>

/* [Device A — name] */
device_a_length = …;
device_a_width  = …;
device_a_height = …;

/* [Vertical layout (mm)] */
floor_thickness  = 5;
…

/* [Tolerance] */
clearance = 2;        // gap between printed walls and devices

/* [Output mode] */
output = "half";      // "half" (default printable) | "full" | "assembly"

// derived dimensions
half_l = …;
half_w = …;

module corner_post(size, h, wall_t, wall_h, cx, cy) { … }

module stand_half() {
    difference() {
        union() {
            // floor rails (U-shape, open at split line x=0)
            // posts, tabs, tenons
        }
        // mortise cutouts
    }
}

module stand_full() {
    stand_half();
    rotate([0, 0, 180]) stand_half();
}

module assembly_preview() {
    %translate(…) cube([device_a_length, device_a_width, device_a_height], center = true);
    stand_full();
}

if      (output == "assembly") assembly_preview();
else if (output == "full")     stand_full();
else                           stand_half();
```

Sensible defaults to start with (tune as the design develops):
- `clearance = 2` mm to devices
- `floor_thickness = 5` mm
- `airflow_gap = 30` mm above heat-emitting devices
- `wall_height = 6` mm for retention L-walls (short enough to clear most slanted device sides)
- `wall_thickness = 3` mm for router-class retention, `2.5` mm for light tabs

## Phase 3 — Render and show

After every meaningful change, render and show the user. **Don't just write code and ask "does this look right?" — generate the PNG so they can see it.**

Set `SCAD` to the OpenSCAD CLI binary path documented in `AGENTS.md` (which records the location for the current setup). Then:

```bash
F=models/<name>/<name>.scad

"$SCAD" -o models/<name>/exports/<name>-half.stl "$F"
"$SCAD" -o models/<name>/exports/<name>-half.png --imgsize=1400,900 --colorscheme=Tomorrow "$F"
"$SCAD" -o models/<name>/exports/<name>-assembly.png --imgsize=1600,1000 --colorscheme=Tomorrow -D 'output="assembly"' "$F"
```

**For alignment-sensitive checks, also render a top-down ortho view.** Perspective renders hide misalignment because the eye can't tell if two things are at the same Y; ortho is unambiguous:

```bash
"$SCAD" -o /tmp/top.png --imgsize=1600,1000 --colorscheme=Tomorrow \
  -D 'output="full"' --camera=0,0,0,0,0,0,400 --projection=ortho "$F"
```

Always `Read` the PNG yourself before showing the user — you'll catch obvious bugs (parts in the wrong place, missing features) before they have to. The STL render also reports `Status: NoError` if manifold; anything else is a geometry bug to fix before moving on.

## Phase 4 — Iterate

User feedback in this loop is usually terse and prescriptive ("dovetail needs to align in the middle", "walls too tall", "leave clearance", "elevate the switch a little"). Treat each as a constraint that changes one or two parameters — not as a request to redesign.

Common iteration types and what they map to:

| User says | Usually means |
|---|---|
| "leave tolerance / clearance" | bump `clearance` to 2 mm everywhere; recompute frame dims |
| "center X on Y" | set the offset equal to half of Y's width |
| "too tall / too short" | adjust the relevant height variable |
| "connect the pieces" | add a joint (see "Joints") |
| "elevate it a little" | add an elevation post or bump `_gap_below` |
| "just retention, not full wrap" | switch L-cup → short tab (~2.5 × 15 mm) |
| "fit on my printer" | check bounding box; if needed, split into halves |

When in doubt about what the user means, ask one focused question (with `AskUserQuestion` if it's a choice).

## Phase 5 — README and root index

Write `models/<name>/README.md` with:
- One-line purpose
- Retention/support strategy (what holds the device in place)
- Vertical stack ASCII diagram showing the layers
- Print settings — surface them in a table. Reasonable starting defaults for most consumer FDM printers: PLA, 0.2 mm layer, 25% gyroid infill, 3 wall loops, 4 top / 3 bottom shells, **no supports**. If the user's slicer (Bambu Studio, PrusaSlicer, OrcaSlicer, etc.) has model-specific recommendations, prefer those — ask the user or look them up.
- Assembly steps if multi-piece (e.g., "rotate one 180° about Z, lower it onto the other")
- Parameter tuning table — list the `/* [Section] */` parameters and what they control
- Export commands

Then add a row to the root `README.md` models table.

---

# Recurring patterns

Building blocks that show up across most stands and holders in this repo. One-line summaries below — read the linked reference for the full module code, dimensions, and gotchas before using:

- **Corner post with L-cup walls** — vertical post topped with two thin L-shaped walls that catch a device corner from outside. Default wall height ~6 mm so it clears slanted device sides. See `references/corner-post.md`.
- **Light retention tab** — short ~20 × 2.5 × 15 mm tab on a floor rail at the device's outer-edge X. Use for "just a stop" retention when a full L-cup is overkill or won't fit. See `references/retention-tab.md`.
- **Dovetail joint (split halves)** — trapezoidal tenon + mortise locking two halves against horizontal pull-apart. Assembly is vertical-only. Always center on rail width; 0.3 mm joint clearance for printable snug fit. See `references/dovetail-joint.md`.
- **Auto-sized frame** — when two devices compete for the frame's dimensions, use `max(constraint_a, constraint_b)` instead of balancing by hand. See `references/auto-sized-frame.md`.
- **Honeycomb panel** — perforated hex surface for shelf tiles, basket walls, vents: a centred hex generator clipped to leave a uniform solid border, plus the hex-symmetry rules that govern alignment across tiles (and the `use`-skips-`EPS`/`$fn` gotcha). See `references/honeycomb-panel.md`.
- **Tiles + cross brace** — for a tray/shelf whose opening is itself ~bed-sized: split into quadrant tiles carried by a separate `+` brace that rests on the frame and bears the unsupported centre. See `references/tiles-and-brace.md`.

---

# Print-bed splitting

If the bounding box exceeds the user's printer bed in any axis, split into halves. Pattern:

1. Design the logical whole, expose `stand_half()` as the printable unit.
2. Use 180° Z-rotational symmetry so one printed part covers both sides.
3. Make the floor frame a **U-shape per half** (open at the split line), not a solid rectangle — when two halves butt together, the Us merge into a full perimeter.
4. Add a dovetail joint at the seam so the halves can't pull apart.
5. The user prints 2 identical copies, rotates one 180° about vertical, and lowers it down onto the other.

Default split direction: along the **long** axis (each half has the full short dimension, half the long).

**When the opening itself is ~bed-sized** (a tray/shelf that must span a gap as wide as the bed), halving doesn't help — the un-split axis still spans the full opening and still has to reach the supports (> bed). Split in **both** axes into quadrant tiles carried by a separate **cross brace** that rests on the frame and bears the unsupported centre. See `references/tiles-and-brace.md`. (Reality check: two square tiles of side `s` only share a plate if `2s ≤ bed`; state the true plate count rather than promising a combined plate the slicer will reject.)

---

# Print-orientation rules

The design must print flat on the bed with **no supports**. This is non-negotiable for this repo's style — supports waste time, leave surface marks, and break easily on detailed features.

- L-walls and tabs sit fully on top of their parent post — no overhangs into thin air
- Posts are vertical pillars from the floor — no horizontal cantilevers
- Bridges shorter than ~10 mm are usually fine; longer than that needs a redesign
- If you catch yourself wanting supports, the geometry is wrong — split it differently, change the orientation, or pick a different approach

---

# Anti-patterns

- **Don't guess dimensions.** Ask. Even within the same product line, revisions vary.
- **Don't add unrequested features.** No fillets, no extra mounting holes, no decorative cuts, no fancy retention if "just a stop" was asked for.
- **Don't write a single-piece design without checking the bed size.** Always confirm the user's printer first and compare the design's bounding box to its bed dimensions.
- **Don't skip clearance.** 0 mm fits don't print; leave 2 mm at minimum for devices, 0.3 mm for joint fits.
- **Don't recommend supports.** Redesign so it prints flat.
- **Don't render and stop.** Always `Read` the PNG yourself before showing the user — you'll catch obvious bugs first.
- **Don't redesign on terse feedback.** "Walls too tall" means tune one parameter, not rewrite the file.
- **Don't commit third-party reference STLs.** Models you download to measure against are often licence-restricted (e.g. MakerWorld Exclusive) — gitignore them and build an original part. See `references/fit-to-existing-part.md`.
- **Don't forget `use` skips variables.** `use <../../lib/common.scad>` imports modules/functions only — restate `EPS` and `$fn` locally or honeycomb/holes silently mis-place. See `references/honeycomb-panel.md`.
