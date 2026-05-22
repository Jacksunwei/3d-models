# Auto-sized frame

When the design has competing constraints — e.g., the router-fit wants the frame this wide, but the switch-fit wants it that wide — let the larger constraint win automatically. Don't try to balance by hand.

```scad
half_l = max(router_length/2 + clearance + wall_thickness,
             switch_length/2 + clearance + post_size);
```

## What this prevents

Without the `max()`, you'd pick one constraint, hardcode the frame size, and then quietly violate the other. For example, sizing only for the router could leave the switch with no clearance to the router-post inner face — or vice versa, sizing only for the switch could pinch the router L-walls.

With `max()`, the frame grows to accommodate whichever device drives the constraint. The cost is that one device gets *more* clearance than the minimum, which is fine.

## When to use it

Any time two or more devices need to coexist inside the same frame and their geometries pull in different directions. Common in this repo because many models stack a smaller device (switch, NAS) under a larger one (router).

## When not to use it

When there is only one constraining device. Just compute `half_l` directly from that device's footprint + clearance + wall thickness. The `max()` pattern adds noise if the second argument is always smaller.
