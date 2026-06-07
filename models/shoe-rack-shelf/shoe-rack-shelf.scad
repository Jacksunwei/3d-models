// Replacement shelf for a tube-frame shoe rack whose woven fabric shelf tore.
//
// Two parallel ROUND bars (16 mm dia) run the tier's length, 262 mm apart (inner
// face to inner face), 930 mm long. The shelf spans the 262 mm gap and tiles
// along the 930 mm length.
//
// 262 mm > the 256 mm bed, so each segment is TWO halves. They are tied into one
// rigid plank by TWO RODS ("sticks") that slide through rib channels running
// across the span:
//
//   * each half is a deck reaching its bar, with rib tubes running Y (toward the
//     hangers). A ~180 deg CRADLE drapes over the bar (rests on top, lifts off).
//   * 2 rods slide through BOTH halves' aligned tubes -> they tie the halves and
//     act as the support beam carrying load all the way to the hangers. Being
//     straight and stiff through both halves, the rods stop the seam folding.
//   * Push the 2nd half onto the protruding rods (across the span); the saddles
//     cap the rod ends so nothing slides out once it's on the bars.
//
// The two halves are IDENTICAL (rotate one 180 deg about Z). Honeycomb is off for
// now (solid deck) while we get the structure right. Reference Z=0 = bar centre.
//
// Fit-critical numbers are MEASURED from YOUR rack -- caliper and tweak.

use <../../lib/common.scad>

// `use` imports modules/functions but NOT top-level vars, so restate these:
EPS = 0.01;
$fn = $preview ? 32 : 64;

/* [Bars — MEASURE on your rack] */
bar_d     = 16;    // bar diameter (you measured r = 8 mm)
bar_gap   = 251;   // INNER face to INNER face, across the two bars
shelf_len = 930;   // bar length to cover along the rack
bar_clear = 0.6;   // slip gap between cradle and bar

/* [Segmentation] */
tile_count = 8;    // segments along the length; 8 -> two halves fit one plate
tile_gap   = 1.0;  // clearance between adjacent segments

/* [Deck] */
deck_th = 1.6;       // deck thickness (thin to save filament; honeycomb keeps it stiff)
deck_style = "honeycomb";  // "honeycomb" | "diagonal" | "solid"
border  = 8;       // solid border around the hex field (perimeter)
rib_margin = 1.5;  // small solid margin where holes meet a rib (holes sit flush to it)
seam_gap = 0.3;    // gap between the two halves at the centre seam (clean mating)

/* [Honeycomb] */
hex_w   = 26;      // flat-to-flat width of each hex hole
hex_web = 3;       // material between adjacent hexes

/* [Cradle (saddle over the bar)] */
cradle_wall = 3;   // saddle wall thickness beside the bar

/* [Sticks — printed PLA bars that bridge the seam to tie the halves] */
rod_count = 2;     // number of sticks per segment
rod_w     = 3;     // stick width (across) — narrow so it prints/bridges easily
rod_h     = 4;    // stick height (stands tall in the rib) — taller = stiffer
rod_reach = 70;    // how far the stick reaches into EACH half from the seam
rod_clear = 0.4;   // slot clearance around the stick
rib_wall  = 2;     // wall around the stick slot -> rib size
cap_wall  = 3;     // wall the stick bottoms against; rib is hollow beyond it

/* [Output] */
output = "assembly";   // "assembly" | "assembled" | "tile" | "rod" | "plate"
bed = 256;             // print bed size (square) for the "plate" layout

// ---------- derived ----------
tile_pitch = shelf_len / tile_count;
tile_w   = tile_pitch - tile_gap;               // printed-half width (X)
R        = bar_d / 2 + bar_clear;               // cradle inner radius
cy       = bar_gap / 2 + bar_d / 2;             // bar centreline in Y (139)
deck_z0  = bar_d / 2;                            // deck underside = bar top (8)
y_sad_in = cy - R - cradle_wall;                // saddle inner edge (toward centre)
y_outer  = cy + R + cradle_wall;                // saddle / deck outer edge
seam_g   = seam_gap / 2;                         // half-gap: each half's inner face

tube_w   = rod_w + rod_clear;                   // slot width
tube_h   = rod_h + rod_clear;                   // slot height
rib_w    = tube_w + 2 * rib_wall;               // rib width around the slot
rib_depth = tube_h + 2 * rib_wall;              // rib hangs below the deck
slot_bot = deck_z0 - rib_depth + rib_wall;      // slot bottom Z
rod_z0   = slot_bot + (tube_h - rod_h) / 2;     // stick bottom Z (centred in slot)
hole_len = min(rod_reach, y_sad_in);            // slot depth in each half (rib stays solid beyond)
rod_len  = 2 * hole_len - 1;                    // stick bridges the seam (− slop)

// rod X positions: spread evenly across the width
rod_xs = [for (i = [0 : rod_count - 1])
            -tile_w / 2 + (i + 0.5) * tile_w / rod_count];

// ---------- deck hole patterns (centred, clipped) ----------
// Each pattern is anchored at the origin -> 180-symmetric, so holes line up
// across the centre seam between a half and its 180-rotated mate.
module hex_pattern_centered(R_field) {
    hex_R = hex_w / sqrt(3);
    px = hex_w + hex_web;
    py = px * sqrt(3) / 2;
    n = ceil(R_field / px) + 2;
    m = ceil(R_field / py) + 2;
    for (j = [-m : m], i = [-n : n]) {
        ox = (j % 2 == 0) ? 0 : px / 2;
        translate([i * px + ox, j * py])
            rotate([0, 0, 90]) circle(r = hex_R, $fn = 6);
    }
}

// diagonal grid: square holes on a 45-deg-rotated lattice -> diamond holes with
// straight 45-deg struts (fast to print).
module diag_pattern_centered(R_field) {
    p = hex_w + hex_web;          // pitch
    n = ceil(R_field / p) + 3;
    rotate([0, 0, 45])
        for (i = [-n : n], j = [-n : n])
            translate([i * p, j * p]) square(hex_w, center = true);
}

// Holes over the open deck only: solid border all round, solid strips over the
// rod ribs, and solid over the saddle band (Y > y_sad_in).
module deck_holes_plus() {
    translate([0, 0, deck_z0 - EPS])
        linear_extrude(deck_th + 2 * EPS)
            intersection() {
                if (deck_style == "diagonal") diag_pattern_centered(y_outer + hex_w);
                else                          hex_pattern_centered(y_outer + hex_w);
                difference() {
                    translate([-tile_w / 2 + border, border])
                        square([tile_w - 2 * border, y_sad_in - 2 * border]);
                    for (x = rod_xs)
                        translate([x - rib_w / 2 - rib_margin, -1])
                            square([rib_w + 2 * rib_margin, y_sad_in + 2]);
                }
            }
}

// ====================================================================
//  +Y HALF  (covers the +Y bar; rotate 180 about Z for the -Y mate)
// ====================================================================
module saddle_plus() {
    // block hugging the bar from the deck down to the equator (Z=0); subtract the
    // bar so it cradles the upper ~180 deg -> lift-off.
    difference() {
        translate([-tile_w / 2, y_sad_in, 0])
            cube([tile_w, y_outer - y_sad_in, deck_z0]);
        translate([-tile_w / 2 - 1, cy, 0])
            rotate([0, 90, 0]) cylinder(h = tile_w + 2, r = R);
    }
}

module deck_plus() {
    translate([-tile_w / 2, seam_g, deck_z0])
        cube([tile_w, y_outer - seam_g, deck_th]);
}

module rib_tubes_plus() {
    // ONE uniform beam per rib, seam to saddle, hollow down the centre. The rod
    // fills only the front of the void; a cap wall stops it, and the void
    // continues empty behind the cap (the saddle caps the far end).
    difference() {
        for (x = rod_xs)
            translate([x - rib_w / 2, seam_g, deck_z0 - rib_depth])
                cube([rib_w, y_sad_in - seam_g, rib_depth + EPS]);
        for (x = rod_xs) {
            // rod slot: open at the seam, capped at hole_len
            translate([x - tube_w / 2, -1, slot_bot])
                cube([tube_w, hole_len + 1, tube_h]);
            // empty void behind the cap wall, on to the saddle
            translate([x - tube_w / 2, hole_len + cap_wall, slot_bot])
                cube([tube_w, y_sad_in - hole_len - cap_wall, tube_h]);
        }
    }
}

module half_tile() {
    difference() {
        union() {
            deck_plus();
            saddle_plus();
            rib_tubes_plus();
        }
        if (deck_style != "solid") deck_holes_plus();
    }
}

// stick in INSTALLED orientation: width X, length along Y, height Z
module rod() { cube([rod_w, rod_len, rod_h]); }

// ====================================================================
//  ASSEMBLY PREVIEW
// ====================================================================
preview_segs = 2;   // segments shown side by side along the bars

// distinct colour per piece, so each half / stick is easy to tell apart
tile_cols = ["#e0a050", "#cf5f86", "#5bb06a", "#5a86d6", "#d8a23c", "#8a6fc0"];
stick_cols = ["#33414f", "#7a4636", "#2f6f5e", "#553b6e"];

module mock_bars() {
    span = preview_segs * tile_pitch + 60;
    color("#333")
        for (s = [-1, 1])
            translate([-tile_pitch / 2 - 30, s * cy, 0])
                rotate([0, 90, 0]) cylinder(h = span, r = bar_d / 2);
}

module segment(k = 0) {
    color(tile_cols[(2 * k) % len(tile_cols)]) half_tile();
    color(tile_cols[(2 * k + 1) % len(tile_cols)]) rotate([0, 0, 180]) half_tile();
    // the two sticks, spanning both halves
    color(stick_cols[k % len(stick_cols)])
        for (x = rod_xs)
            translate([x - rod_w / 2, -hole_len + 0.5, rod_z0]) rod();
}

module assembly_preview() {
    mock_bars();
    for (k = [0 : preview_segs - 1])
        translate([k * tile_pitch, 0, 0]) segment(k);
}

// ====================================================================
//  PLATE LAYOUT  (how many pieces fit on one bed)
// ====================================================================
// deck-down, centred at the origin (footprint tile_w × (y_outer−seam_g))
module printed_tile() {
    translate([0, (y_outer + seam_g) / 2, deck_z0 + deck_th]) rotate([180, 0, 0]) half_tile();
}
// flat on its side, centred at the origin (footprint rod_h × rod_len, height rod_w)
module printed_stick() {
    translate([-rod_h / 2, -rod_len / 2, 0]) cube([rod_h, rod_len, rod_w]);
}

// One printable plate = ONE complete segment: the two halves side by side plus
// the segment's sticks above them. The bed slab shows only in the preview (so it
// stays out of the STL).
module plate() {
    margin = 3; gap = 3; pitch = rod_h + gap;
    ty = y_outer - seam_g;                       // printed tile depth (Y)
    if ($preview)
        %color([0.86, 0.86, 0.86]) translate([-bed / 2, -bed / 2, -0.8]) cube([bed, bed, 0.6]);
    // two halves of one segment, side by side, sitting at the front
    tcols = ["#cf5f86", "#5bb06a"];
    for (s = [0, 1])
        color(tcols[s])
            translate([(s - 0.5) * (tile_w + gap), -bed / 2 + margin + ty / 2, 0])
                printed_tile();
    // the segment's sticks, above the tiles, laid lengthwise along X
    sy0 = -bed / 2 + margin + ty + gap;
    for (i = [0 : rod_count - 1])
        color("#5a86d6")
            translate([0, sy0 + rod_h / 2 + i * pitch, 0])
                rotate([0, 0, 90]) printed_stick();
}

// ---------- dispatch ----------
if (output == "plate")
    plate();
else if (output == "assembly")
    assembly_preview();                             // functional view, includes mock bars
else if (output == "assembled")
    // assembled segments side by side (parts only, no bars) -> STL
    for (k = [0 : preview_segs - 1])
        translate([k * tile_pitch, 0, 0]) segment(k);
else if (output == "rod")
    // print orientation: lay the stick flat on its side (stable, no overhang)
    translate([0, 0, rod_w]) rotate([0, 90, 0]) rod();
else
    // print orientation: deck face-down, ribs + cradle point up (no supports)
    translate([0, 0, deck_z0 + deck_th]) rotate([180, 0, 0]) half_tile();
