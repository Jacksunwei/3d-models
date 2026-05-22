# Light retention tab

A short, thin tab sticking up from a floor rail at the device's outer-edge X position. Just a "stop", not a wrap. Use when:

- The user explicitly asks for light retention (e.g., "just need a stop, not a full cup")
- The device is the same width as the frame, leaving no room for a full L-cup at the corner (the side rail itself constrains Y; tabs only need to handle X)
- Cable clearance under the device matters and tall walls would block it

## Typical dimensions

| Parameter | Default | Notes |
|---|---|---|
| Length (along rail) | 20 mm | Wider than the corner so it catches the device even if slightly off-center |
| Thickness (perpendicular to rail) | 2.5 mm | Same as light-retention wall thickness |
| Height (above rail) | 15 mm | Covers the bottom ~10 mm of an elevated device — enough to stop sideways slide |
| Clearance to device | 2 mm | Same `clearance` value used elsewhere |

## Snippet

```scad
// Tab on the +Y long rail at the device's outer X corner
translate([-device_corner_x - tab_x_length/2,
           half_w - tab_thickness,
           floor_thickness])
    cube([tab_x_length, tab_thickness, tab_height]);
```

Mirror as needed for the other 3 corners. The router-stand model has both top and bottom tabs at each switch-corner X position.
