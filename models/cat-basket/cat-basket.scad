use <../../lib/common.scad>

/* [Basket] */
basket_size = 100;            // outer cube edge — 10 cm on each side
wall_thickness = 3;
floor_thickness = 3;

/* [Cat ears (stick up above the rim at the front)] */
ear_h = 18;                   // height above the rim
ear_base = 25;
ear_sep = 50;                 // x-distance between ear centers
ear_tilt = 0.3;
show_inner_ear = true;
inner_ear_scale = 0.55;
inner_ear_engrave_depth = 1.2;

/* [Honeycomb cutouts on the three non-face walls] */
hex_width = 10;               // flat-to-flat width of each hex hole
hex_web = 2;                  // material thickness between adjacent hexes
hex_margin = 10;              // unbroken border around the hex pattern (corner + rim + floor support)

/* [Cat head — solid circular disk on the front wall, surrounded by honeycomb] */
head_circle_r = 45;           // radius of the solid head disk
head_circle_border = 2;       // extra solid border between disk and the hex pattern

/* [Cat face engraving on the front wall] */
face_center_z = 50;           // height from floor to face center (and head circle center)
face_engrave_depth = 2;
eye_r = 8;
eye_sep = 30;
eye_y_offset = 7;
eye_highlight_r = 2.5;
eye_highlight_dx = -3;
eye_highlight_dy = 3;
nose_w = 5;
nose_h = 4;
nose_y_offset = -7;
mouth_curve_r = 4;
mouth_y_offset = -16;
blush_r = 5;
blush_sep = 30;
blush_y_offset = -10;
blush_engrave_depth = 0.7;

// ---- Shell ----

module basket_shell() {
    // Open-top hollow cube
    difference() {
        cube([basket_size, basket_size, basket_size]);
        translate([wall_thickness, wall_thickness, floor_thickness])
            cube([
                basket_size - 2*wall_thickness,
                basket_size - 2*wall_thickness,
                basket_size - floor_thickness + 1
            ]);
    }
}

// ---- Ears on top of the front wall ----

module ear_triangle_2d(scale_factor) {
    base = ear_base * scale_factor;
    h    = ear_h    * scale_factor;
    polygon([
        [-base/2, 0],
        [ base/2, 0],
        [ base/2 * ear_tilt, h]
    ]);
}

// Extrude a 2D shape oriented as if drawn on the front face of the basket
// (X = horizontal, Y in the 2D drawing → Z in the world), cutting/extending
// into the +Y direction by `depth`.
module project_to_front(x_offset, z_offset, depth) {
    translate([x_offset, 0, z_offset])
        rotate([90, 0, 0])
            translate([0, 0, -depth - 0.5])
                linear_extrude(height = depth + 1)
                    children();
}

// Solid 3D ear prism extending up from the rim and OUT in +Y (same depth as wall)
module ear_prism(side) {
    x_offset = basket_size/2 + side * ear_sep/2;
    translate([x_offset, 0, basket_size])
        rotate([90, 0, 0])
            translate([0, 0, -wall_thickness])
                linear_extrude(height = wall_thickness)
                    if (side == 1) ear_triangle_2d(1);
                    else           mirror([1, 0, 0]) ear_triangle_2d(1);
}

module inner_ear_cut(side) {
    x_offset       = basket_size/2 + side * ear_sep/2;
    inner_offset_z = (ear_h - ear_h * inner_ear_scale) / 3;
    project_to_front(x_offset, basket_size + inner_offset_z, inner_ear_engrave_depth) {
        if (side == 1) ear_triangle_2d(inner_ear_scale);
        else           mirror([1, 0, 0]) ear_triangle_2d(inner_ear_scale);
    }
}

// ---- Cat face features ----

module eye_with_sparkle_2d() {
    difference() {
        circle(eye_r);
        translate([eye_highlight_dx, eye_highlight_dy]) circle(eye_highlight_r);
    }
}

module mouth_2d() {
    r = mouth_curve_r;
    union() {
        translate([-r, 0]) difference() {
            circle(r);
            translate([0, r/2 + 0.05]) square([2*r + 1, r + 0.1], center = true);
        }
        translate([ r, 0]) difference() {
            circle(r);
            translate([0, r/2 + 0.05]) square([2*r + 1, r + 0.1], center = true);
        }
    }
}

module face_features_2d() {
    translate([-eye_sep/2, eye_y_offset]) eye_with_sparkle_2d();
    translate([ eye_sep/2, eye_y_offset]) eye_with_sparkle_2d();
    translate([0, nose_y_offset])
        polygon([
            [-nose_w/2, nose_h/2],
            [ nose_w/2, nose_h/2],
            [0, -nose_h/2]
        ]);
    translate([0, mouth_y_offset]) mouth_2d();
}

module blush_features_2d() {
    translate([-blush_sep/2, blush_y_offset]) circle(blush_r);
    translate([ blush_sep/2, blush_y_offset]) circle(blush_r);
}

// ---- Honeycomb pattern for the side and back walls ----

module hex_grid_2d(region_w, region_h, hex_w, web) {
    hex_R = hex_w / sqrt(3);          // circumscribed radius for pointy-top hex
    pitch_x = hex_w + web;
    pitch_y = pitch_x * sqrt(3) / 2;
    cols = ceil(region_w / pitch_x) + 2;
    rows = ceil(region_h / pitch_y) + 2;
    intersection() {
        union() {
            for (j = [-1 : rows], i = [-1 : cols]) {
                offset_x = (j % 2 == 0) ? 0 : pitch_x / 2;
                translate([i * pitch_x + offset_x, j * pitch_y])
                    rotate([0, 0, 90])
                        circle(r = hex_R, $fn = 6);
            }
        }
        translate([-0.1, -0.1]) square([region_w + 0.2, region_h + 0.2]);
    }
}

// Hex pattern for the front wall — with a circular hole left for the cat head disk
module front_hex_cut_2d() {
    cut_w = basket_size - 2*hex_margin;
    cut_h = basket_size - 2*hex_margin;
    difference() {
        hex_grid_2d(cut_w, cut_h, hex_width, hex_web);
        // Keep the head disk + border SOLID — subtract it from the cut pattern
        translate([basket_size/2 - hex_margin, face_center_z - hex_margin])
            circle(r = head_circle_r + head_circle_border);
    }
}

module hex_cuts_for_walls() {
    cut_w = basket_size - 2*hex_margin;
    cut_h = basket_size - 2*hex_margin;

    // FRONT wall (y = 0): cut in +Y direction, but spare the head disk area
    translate([hex_margin, -0.5, hex_margin])
        rotate([90, 0, 0])
            translate([0, 0, -wall_thickness - 0.5])
                linear_extrude(height = wall_thickness + 1)
                    front_hex_cut_2d();

    // LEFT wall (x = 0): cut in +X direction
    translate([-0.5, hex_margin, basket_size - hex_margin])
        rotate([0, 90, 0])
            linear_extrude(height = wall_thickness + 1)
                hex_grid_2d(cut_w, cut_h, hex_width, hex_web);

    // RIGHT wall (x = basket_size): cut in -X direction
    translate([basket_size + 0.5, hex_margin, hex_margin])
        rotate([0, -90, 0])
            linear_extrude(height = wall_thickness + 1)
                hex_grid_2d(cut_w, cut_h, hex_width, hex_web);

    // BACK wall (y = basket_size): cut in -Y direction
    translate([hex_margin, basket_size + 0.5, hex_margin])
        rotate([90, 0, 0])
            linear_extrude(height = wall_thickness + 1)
                hex_grid_2d(cut_w, cut_h, hex_width, hex_web);
}

// ---- Assembly ----

module cat_basket() {
    difference() {
        union() {
            basket_shell();
            ear_prism(-1);
            ear_prism( 1);
        }
        project_to_front(basket_size/2, face_center_z, face_engrave_depth)
            face_features_2d();
        project_to_front(basket_size/2, face_center_z, blush_engrave_depth)
            blush_features_2d();
        if (show_inner_ear) {
            inner_ear_cut(-1);
            inner_ear_cut( 1);
        }
        hex_cuts_for_walls();
    }
}

cat_basket();
