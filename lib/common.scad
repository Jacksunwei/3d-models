// Shared modules used across models.
// Include with: use <../../lib/common.scad>

$fn = $preview ? 32 : 96;

EPS = 0.01;

module rounded_box(size, radius) {
    minkowski() {
        cube([size.x - 2*radius, size.y - 2*radius, size.z - 2*radius], center = true);
        sphere(r = radius);
    }
}

module shell(outer_size, wall) {
    difference() {
        cube(outer_size, center = true);
        cube([outer_size.x - 2*wall, outer_size.y - 2*wall, outer_size.z + EPS], center = true);
    }
}

module pipe(h, outer_r, wall) {
    difference() {
        cylinder(h = h, r = outer_r);
        translate([0, 0, -EPS])
            cylinder(h = h + 2*EPS, r = outer_r - wall);
    }
}

module mounting_holes(spacing, hole_d, depth) {
    for (x = [-1, 1], y = [-1, 1])
        translate([x * spacing/2, y * spacing/2, 0])
            cylinder(h = depth, d = hole_d, center = true);
}

// Countersunk screw hole (M3 default). Punch through with difference().
module countersunk_hole(shaft_d = 3.2, head_d = 6, head_depth = 1.8, length = 20) {
    translate([0, 0, -EPS])
        cylinder(h = length, d = shaft_d);
    translate([0, 0, -EPS])
        cylinder(h = head_depth, d1 = head_d, d2 = shaft_d);
}
