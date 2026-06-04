// Honeycomb shelf for the K.Flynn "Modular Shelf System" frame
// (15 mm square-tube rails + corner/T connectors, in Modular+Shelf_stls/).
//
// The cell opening (~255 mm) is as large as the 256 mm bed, so a one-piece tray
// that rests on the rails won't fit. Instead the shelf is a kit:
//
//   * 1 cross BRACE  - a "+" that rests its four end-feet on the rails and
//                      spans the opening, dividing it into four quadrants.
//   * 4 TILES        - one per quadrant, each resting on the two perimeter
//                      rails (outer edges) and the two brace arms (inner edges),
//                      so every tile is supported on all four edges.
//
// Tiles peg onto the brace so the surface acts as one rigid plate; container
// weight flows tile -> brace/rails. Gravity / liftable.
//
// Print: tiles floor-down (no supports); brace printed at 45 deg to fit the bed
// (output="brace" already rotates it). Reference Z=0 = rail top.
//
// Fit-critical numbers are measured from YOUR frame -- caliper and tweak.

use <../../lib/common.scad>

// `use` imports modules/functions but NOT top-level vars, so restate these:
EPS = 0.01;
$fn = $preview ? 32 : 96;

/* [Frame fit — MEASURE on your assembled frame] */
rail          = 15;    // rail square-tube cross-section (mm)
inner_opening = 255;   // bar INNER edge to bar INNER edge across one cell (you measured 255)
post_notch    = 26;    // corner cut-out square clearing the connector post (real post 20×20)
fit_clearance = 0.4;   // slip gap

/* [Tile] */
bear        = 4;       // bearing plane height above the rail top (= brace foot thickness)
floor_th    = 4;       // honeycomb floor thickness
border      = 8;       // solid border around the hex field
rail_rest   = 7.5;     // how far a tile foot sits onto the rail top (<= rail)
seam_gap    = 0.4;     // gap between adjacent tiles at the centre
corner_cut  = 31;      // foot relief in from the cell corner, to clear the elevated connector body

/* [Cross brace] */
brace_w     = 18;      // width of each brace bar (two tiles share it)
brace_depth = bear + rail;  // beam depth -> brace bottom flush with the rail underside
                            // (raise for a stiffer/deeper beam; it then dips below the rails)
peg_d       = 4;       // tile<->brace locating pegs
peg_h       = 3;

/* [Honeycomb] */
hex_width = 12;        // flat-to-flat width of each hex hole
hex_web   = 2.4;       // material between adjacent hexes
hex_angle = 0;         // grid tilt (0 = axis-aligned). 15 lands a mirror axis on the diagonal

/* [Frame preview — visual only, set to your actual parts] */
mock_rail_len = 240;   // actual printed rail length
conn_foot     = 40;    // corner-connector body footprint (real corner = 40×60)
conn_rise     = 2.5;   // connector socket sits ~2-3 mm proud of the rail's top surface (measured)
post_xy       = 20;    // connector socket/post cross-section (measured 20×20)
post_h        = 20;    // post height, sitting on top of the connector body

/* [Output] */
output = "assembly";   // "tile" | "brace" | "assembly"

// ---------- derived ----------
half   = inner_opening / 2;        // 127.5 : rail inner face
rail_c = half + rail / 2;          // 135   : rail centreline & corner-post centre
tile_out = half + rail_rest;       // tile outer edge (onto the rail)

// ---------- honeycomb ----------
// Hex hole pattern centred on the origin (a hex centre sits at 0,0), covering a
// disc of radius `R`. Pointy-top hexes -> a vertex-to-vertex mirror axis runs
// vertically; tilting the whole pattern by 15° lands that axis on the 45°
// tile diagonal, so the clipped result is symmetric about y = x.
module hex_pattern_centered(R, hex_w, web) {
    hex_R = hex_w / sqrt(3);
    pitch_x = hex_w + web;
    pitch_y = pitch_x * sqrt(3) / 2;
    n = ceil(R / pitch_x) + 2;
    m = ceil(R / pitch_y) + 2;
    for (j = [-m : m], i = [-n : n]) {
        ox = (j % 2 == 0) ? 0 : pitch_x / 2;
        translate([i * pitch_x + ox, j * pitch_y])
            rotate([0, 0, 90]) circle(r = hex_R, $fn = 6);
    }
}

// ====================================================================
//  ONE QUADRANT TILE  (+x +y quadrant; rotate for the other three)
// ====================================================================
// Floor sits at Z = bear..bear+floor_th. Inner edges (toward 0) rest on the
// brace top (Z=bear). Outer edges sit on the rails via feet (Z=0..bear) plus a
// locating lip dropping into the opening.
module quadrant_tile() {
    in0 = seam_gap;                      // inner edges (over the brace)
    difference() {
        union() {
            // floor with honeycomb: inset `border` from every edge, and the same
            // `border` kept solid around the corner post notch (uniform frame).
            difference() {
                translate([in0, in0, bear])
                    cube([tile_out - in0, tile_out - in0, floor_th]);
                fx = tile_out - in0 - 2 * border;
                nm = post_notch + 2 * border;   // solid border kept around the post notch
                translate([0, 0, bear - EPS])
                    linear_extrude(floor_th + 2 * EPS)
                        difference() {
                            intersection() {
                                // grid anchored at the CELL centre (origin), so it lines up
                                // across all four mirrored tiles -> continuous honeycomb
                                rotate(hex_angle)
                                    hex_pattern_centered(tile_out + hex_width, hex_width, hex_web);
                                translate([in0 + border, in0 + border]) square(fx);
                            }
                            translate([rail_c - nm / 2, rail_c - nm / 2]) square(nm);
                        }
            }
            // outer feet: rest on the two perimeter rails (Z 0..bear)
            translate([half, in0, 0]) cube([rail_rest, tile_out - in0, bear]);   // on +x rail
            translate([in0, half, 0]) cube([tile_out - in0, rail_rest, bear]);   // on +y rail
            // locating stem: drops into the brace hole (prints up when floor-down)
            translate([brace_w / 2 - 3, brace_w / 2 - 3, bear - peg_h])
                cylinder(h = peg_h, d = peg_d);
        }
        // post through-notch (the post sticks up through the floor)
        translate([rail_c, rail_c, (bear + floor_th) / 2])
            cube([post_notch, post_notch, bear + floor_th + 2], center = true);
        // corner foot relief: remove the feet where the elevated connector body
        // intrudes (the floor above stays and clears it). Keeps the surface continuous.
        translate([rail_c - corner_cut, rail_c - corner_cut, -1])
            cube([corner_cut + post_xy, corner_cut + post_xy, bear + 1 + EPS]);
    }
}

// ====================================================================
//  CROSS BRACE  ("+" that rests on the rails, spans the opening)
// ====================================================================
module brace_bar() {
    // beam over the opening + an end foot on each rail
    translate([-half, -brace_w / 2, bear - brace_depth])
        cube([inner_opening, brace_w, brace_depth]);
    for (s = [-1, 1])
        translate([s * half - (s < 0 ? rail_rest : 0), -brace_w / 2, 0])
            cube([rail_rest, brace_w, bear]);
}
module brace() {
    difference() {
        union() {
            brace_bar();
            rotate([0, 0, 90]) brace_bar();
        }
        // locating holes (one per quadrant) — receive the tile stems
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (brace_w / 2 - 3), sy * (brace_w / 2 - 3), bear - peg_h])
                cylinder(h = peg_h + EPS, d = peg_d + 0.4);
    }
}

// ====================================================================
//  ASSEMBLY PREVIEW
// ====================================================================
module mock_frame() {
    color("#333") {
        // four rails (15×15), real length, inner faces at ±half -> opening = inner_opening
        for (s = [-1, 1]) {
            translate([-mock_rail_len / 2, s * rail_c - rail / 2, -rail])
                cube([mock_rail_len, rail, rail]);
            translate([s * rail_c - rail / 2, -mock_rail_len / 2, -rail])
                cube([rail, mock_rail_len, rail]);
        }
        // four corner connectors: socket WRAPS the rail (down to rail bottom) and
        // sits conn_rise proud of the rail top; the post sits on top of that.
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * rail_c, sy * rail_c, 0]) {
                translate([-conn_foot / 2, -conn_foot / 2, -rail])
                    cube([conn_foot, conn_foot, rail + conn_rise]);   // -rail .. +conn_rise
                translate([-post_xy / 2, -post_xy / 2, conn_rise])
                    cube([post_xy, post_xy, post_h]);                 // post on the body
            }
    }
}
module assembly_preview() {
    mock_frame();
    color("#888") brace();
    // tiles placed by MIRRORING (not rotation) so the cell-anchored grid stays continuous
    color("#c97") quadrant_tile();                       // +x +y  (tile)
    color("#c97") rotate([0, 0, 180]) quadrant_tile();   // -x -y  (tile, rotated 180)
    color("#d8a") mirror([1, 0, 0]) quadrant_tile();     // -x +y  (tile-mirror)
    color("#d8a") mirror([0, 1, 0]) quadrant_tile();     // +x -y  (tile-mirror)
}

// ---------- dispatch ----------
// Print outputs are oriented flat on the plate (Z=0), ready to slice.
if (output == "assembly")
    assembly_preview();                                    // functional view (not for printing)
else if (output == "brace")
    // flipped: bearing face + feet flat on the bed, beam standing up (no overhangs); 45° fits bed
    rotate([0, 0, 45]) translate([0, 0, bear]) rotate([180, 0, 0]) brace();
else if (output == "tile-mirror")
    // mirror-image tile (for the +x-y and -x+y quadrants); print ×2
    translate([0, 0, bear + floor_th]) rotate([180, 0, 0]) mirror([1, 0, 0]) quadrant_tile();
else
    // tile (for the +x+y and -x-y quadrants); print ×2
    translate([0, 0, bear + floor_th]) rotate([180, 0, 0]) quadrant_tile();  // floor-down
