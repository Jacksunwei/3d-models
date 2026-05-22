use <../../lib/common.scad>

/* [Router (rectangular bottom)] */
router_length = 231;          // long side
router_width  = 125;          // short side

/* [Switch (rectangular cuboid)] */
switch_length = 210;
switch_width  = 125;
switch_height = 27;

/* [Vertical layout (mm)] */
floor_thickness  = 5;         // floor rail thickness
switch_gap_below = 10;        // cable space + airflow under switch
airflow_gap      = 30;        // gap between switch top and router bottom

/* [Floor rails] */
rail_width = 15;              // wide enough that switch posts sit fully on rails

/* [Router corner L-cups (full wrap, catches corners)] */
post_size      = 15;
wall_height    = 6;           // short enough to clear the router's slanted sides
wall_thickness = 3;

/* [Switch elevation posts (flat top, no walls)] */
switch_post_size = 10;

/* [Switch retention tabs (on long rails, light retention only)] */
tab_x_length  = 20;
tab_thickness = 2.5;
tab_height    = 15;           // above the rail (covers switch bottom 10 mm)

/* [Half-to-half dovetail joint] */
dt_base_w       = 5;          // Y width at the seam (narrow base)
dt_tip_w        = 9;          // Y width at the tip (wide, locks the halves)
dt_length       = 8;          // X extent of the tenon
dt_offset       = rail_width / 2;  // centerline of dovetail = centerline of rail
joint_clearance = 0.3;        // mortise is wider by 2× this on every face

/* [Tolerance] */
clearance = 2;                // gap between part walls and devices

/* [Output mode] */
output = "half";              // "half" | "full" | "assembly"

router_post_h = floor_thickness + switch_gap_below + switch_height + airflow_gap;
switch_post_h = floor_thickness + switch_gap_below;

s_half_l = switch_length / 2;
s_half_w = switch_width  / 2;

// Frame half-dimensions. X is sized by whichever needs more room:
//   - router L-cup wall outer face (router corner + clearance + wall_thickness), OR
//   - switch X clearance to router-post inner face (switch corner + clearance + post_size)
half_l = max(router_length / 2 + clearance + wall_thickness,
             s_half_l       + clearance + post_size);
half_w = router_width  / 2 + clearance + wall_thickness;

EPS = 0.01;

// L-cup post: leg + 2 walls at the corner indicated by (cx, cy).
module corner_post(size, h, wall_t, wall_h, cx, cy) {
    cube([size, size, h]);
    wx = cx > 0 ? size - wall_t : 0;
    wy = cy > 0 ? size - wall_t : 0;
    translate([0, wy, h])
        cube([size, wall_t, wall_h]);
    translate([wx, 0, h])
        cube([wall_t, size, wall_h]);
}

// 2D dovetail tenon: narrow at X=0 (base), wide at X=length (tip).
module dovetail_2d(base_w, tip_w, length) {
    polygon([
        [0,      -base_w/2],
        [length, -tip_w/2],
        [length, +tip_w/2],
        [0,      +base_w/2]
    ]);
}

// LEFT HALF — print 2 copies, rotate one 180° about Z.
// The dovetail joints (top rail tenon, bottom rail mortise — and vice versa
// after rotation) lock the halves so they can't pull apart sideways. Assemble
// by lowering one half straight down onto the other from above.
module stand_half() {
    leg_h_router = router_post_h - floor_thickness;
    leg_h_switch = switch_post_h - floor_thickness;

    difference() {
        union() {
            // ---- FLOOR RAILS (U-shape, open at split line x=0) ----
            translate([-half_l, -half_w, 0])
                cube([rail_width, 2*half_w, floor_thickness]);              // side (closed end of U)
            translate([-half_l, half_w - rail_width, 0])
                cube([half_l, rail_width, floor_thickness]);                // top arm of U
            translate([-half_l, -half_w, 0])
                cube([half_l, rail_width, floor_thickness]);                // bottom arm of U

            // ---- ROUTER CORNER POSTS (2 per half) — full L-cups ----
            translate([-half_l, -half_w, floor_thickness])
                corner_post(post_size, leg_h_router, wall_thickness, wall_height, -1, -1);
            translate([-half_l, half_w - post_size, floor_thickness])
                corner_post(post_size, leg_h_router, wall_thickness, wall_height, -1, +1);

            // ---- SWITCH ELEVATION POSTS (2 per half) — flat tops, no walls ----
            translate([-s_half_l, -s_half_w, floor_thickness])
                cube([switch_post_size, switch_post_size, leg_h_switch]);
            translate([-s_half_l, s_half_w - switch_post_size, floor_thickness])
                cube([switch_post_size, switch_post_size, leg_h_switch]);

            // ---- SWITCH RETENTION TABS (on long rails, at the switch corner X) ----
            translate([-s_half_l - tab_x_length/2, half_w - tab_thickness, floor_thickness])
                cube([tab_x_length, tab_thickness, tab_height]);
            translate([-s_half_l - tab_x_length/2, -half_w, floor_thickness])
                cube([tab_x_length, tab_thickness, tab_height]);

            // ---- DOVETAIL TENON on top rail (sticks out in +X past x=0) ----
            translate([0, half_w - dt_offset, 0])
                linear_extrude(floor_thickness)
                    dovetail_2d(dt_base_w, dt_tip_w, dt_length);
        }

        // ---- DOVETAIL MORTISE on bottom rail (cutout, opens at x=0 going -X) ----
        translate([0, -(half_w - dt_offset), -EPS])
            linear_extrude(floor_thickness + 2*EPS)
                mirror([1, 0, 0])
                    dovetail_2d(dt_base_w  + 2*joint_clearance,
                                dt_tip_w   + 2*joint_clearance,
                                dt_length  + joint_clearance);
    }
}

module stand_full() {
    stand_half();
    rotate([0, 0, 180]) stand_half();
}

module assembly_preview() {
    // Ghost router (height ~50 mm — actual height doesn't affect the stand design)
    %translate([0, 0, router_post_h + 50/2])
        cube([router_length, router_width, 50], center = true);
    %translate([0, 0, switch_post_h + switch_height/2])
        cube([switch_length, switch_width, switch_height], center = true);

    stand_full();
}

if (output == "assembly")   assembly_preview();
else if (output == "full")  stand_full();
else                        stand_half();
