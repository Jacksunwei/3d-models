# Corner post with L-cup walls

A vertical post with two thin walls forming an L at the top corner — catches a device corner from outside. Walls sit fully on top of the post (no overhang) so the part prints flat.

```scad
module corner_post(size, h, wall_t, wall_h, cx, cy) {
    cube([size, size, h]);
    wx = cx > 0 ? size - wall_t : 0;
    wy = cy > 0 ? size - wall_t : 0;
    translate([0, wy, h]) cube([size, wall_t, wall_h]);
    translate([wx, 0, h]) cube([wall_t, size, wall_h]);
}
```

`cx, cy ∈ {-1, +1}` selects which corner of the post top holds the L.

## Sizing guidance

- **Wall height ~6 mm** is a good default — short enough to clear devices with slanted sides (most consumer hardware widens upward), tall enough for real retention.
- **Wall thickness 3 mm** for router-class loads; 2.5 mm for light retention.
- **Post size 15 × 15 mm** square is plenty for compression loads up to ~1 kg per post.

## Placement

Position the post so the device corner sits just inside the L, with `clearance` (2 mm typical) between the device's outer face and the wall's inner face. The router-stand model auto-computes the half-frame so the L's inside corner lands at exactly `device_corner + clearance`.
