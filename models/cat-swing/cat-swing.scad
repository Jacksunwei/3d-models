use <../../lib/common.scad>

/* [Head] */
head_r = 26;
ear_h = 18;
ear_base = 18;
ear_sep = 32;
ear_tilt = 0.25;

/* [Body] */
body_r = 20;
head_body_overlap = 8;     // head sinks into body by this much

/* [Paws — dangling over the seat front] */
show_paws = true;
paw_r = 7;
paw_sep = 24;              // wide enough to stick out past the body
paw_y_abs = 6;             // absolute y position of paw centers (low, into the seat region)

/* [Seat] */
seat_width = 56;
seat_thickness = 9;
body_seat_overlap = 6;

/* [String holes] */
string_hole_d = 3.5;
string_hole_inset = 6;

/* [3D body — minkowski puff] */
flat_base = 6;             // flat extrusion before puff
puff_r = 5;                // sphere radius for chibi roundness ($fn for sphere set low for speed)
puff_fn = 24;

/* [Face engraving] */
eye_r = 6;
eye_sep = 22;
eye_y_offset = 4;
eye_highlight_r = 1.8;
eye_highlight_dx = -2;     // highlight offset from eye center (upper-left = kawaii sparkle)
eye_highlight_dy = 2;
nose_w = 3.5;
nose_h = 3;
nose_y_offset = -6;
mouth_curve_r = 2.5;
mouth_y_offset = -11;
blush_r = 3.5;
blush_sep = 22;            // directly below eyes
blush_y_offset = -9;       // well below eyes
face_engrave_depth = 2.0;
blush_engrave_depth = 0.6;

/* [Output mode] */
output = "print";          // "print" | "upright" | "assembly"

// ---- Derived ----
body_cy   = seat_thickness + body_r - body_seat_overlap;
head_cy   = body_cy + body_r + head_r - head_body_overlap;
hole_x    = seat_width/2 - string_hole_inset;
hole_y    = seat_thickness/2;
top_z     = flat_base + puff_r;
front_z   = flat_base + 2*puff_r;  // approximate top of puffed shape

// ---- 2D silhouette (no holes — holes cut in 3D after minkowski) ----

module ear_2d() {
    polygon([
        [-ear_base/2, 0],
        [ ear_base/2, 0],
        [ ear_base/2 * ear_tilt, ear_h]
    ]);
}

module seat_2d() {
    translate([-seat_width/2, 0]) square([seat_width, seat_thickness]);
}

module cat_silhouette_2d() {
    union() {
        seat_2d();
        translate([0, body_cy]) circle(body_r);
        translate([0, head_cy]) circle(head_r);
        translate([-ear_sep/2, head_cy + head_r * 0.55])
            mirror([1, 0, 0]) ear_2d();
        translate([ ear_sep/2, head_cy + head_r * 0.55])
            ear_2d();
        if (show_paws) {
            translate([-paw_sep/2, paw_y_abs]) circle(paw_r);
            translate([ paw_sep/2, paw_y_abs]) circle(paw_r);
        }
    }
}

// ---- Face features ----

module mouth_2d() {
    // tiny ω smile
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

module eye_with_sparkle_2d() {
    // ring cut: outer eye minus the highlight island
    difference() {
        circle(eye_r);
        translate([eye_highlight_dx, eye_highlight_dy]) circle(eye_highlight_r);
    }
}

module face_features_2d() {
    translate([-eye_sep/2, head_cy + eye_y_offset]) eye_with_sparkle_2d();
    translate([ eye_sep/2, head_cy + eye_y_offset]) eye_with_sparkle_2d();
    translate([0, head_cy + nose_y_offset])
        polygon([
            [-nose_w/2, nose_h/2],
            [ nose_w/2, nose_h/2],
            [0, -nose_h/2]
        ]);
    translate([0, head_cy + mouth_y_offset]) mouth_2d();
}

module blush_features_2d() {
    translate([-blush_sep/2, head_cy + blush_y_offset]) circle(blush_r);
    translate([ blush_sep/2, head_cy + blush_y_offset]) circle(blush_r);
}

// ---- 3D (puffed) cat in print orientation ----

// minkowski-puffed silhouette: 3D rounded chibi shape
module puffed_body() {
    minkowski() {
        linear_extrude(height = flat_base)
            cat_silhouette_2d();
        sphere(r = puff_r, $fn = puff_fn);
    }
}

module cat_3d_print() {
    difference() {
        puffed_body();
        // Flat back: chop everything below z=0
        translate([0, 0, -50])
            cube([400, 400, 100], center = true);
        // String holes — vertical cylinders through the seat region
        for (sx = [-1, 1])
            translate([sx * hole_x, hole_y, -1])
                cylinder(h = front_z + 2, d = string_hole_d);
        // Face cuts — go from above the surface down to face_engrave_depth below the highest point.
        translate([0, 0, top_z - face_engrave_depth])
            linear_extrude(height = puff_r + face_engrave_depth + 2)
                face_features_2d();
        // Blush cuts — shallower
        translate([0, 0, top_z - blush_engrave_depth])
            linear_extrude(height = puff_r + blush_engrave_depth + 2)
                blush_features_2d();
    }
}

module cat_3d_upright() {
    rotate([90, 0, 0]) cat_3d_print();
}

module preview_strings() {
    cat_depth = front_z;
    bar_y = -cat_depth/2;
    bar_z = hole_y + 100;
    color([0.85, 0.6, 0.3, 0.8]) {
        for (sx = [-1, 1])
            translate([sx * hole_x, bar_y, hole_y])
                cylinder(h = 100, d = 1.2);
        translate([0, bar_y, bar_z])
            rotate([0, 90, 0])
                cylinder(h = seat_width + 30, d = 5, center = true);
    }
}

module assembly_preview() {
    cat_3d_upright();
    preview_strings();
}

// ---- Dispatch ----
if      (output == "assembly") assembly_preview();
else if (output == "upright")  cat_3d_upright();
else                           cat_3d_print();
