# 3D Models

Parametric 3D-printable models, written in [OpenSCAD](https://openscad.org/).

## Layout

```
lib/                  shared modules (rounded boxes, screw holes, pipes, ...)
models/<name>/
  <name>.scad         parametric source
  README.md           parameters, print settings
  exports/            generated STL/3MF files
```

## Models

| Model | Description |
|---|---|
| [router-stand](models/router-stand/) | Connected frame to lift a router and stash a switch underneath |

## Conventions

- Dimensions in millimeters.
- All tunable values declared as variables at the top of each `.scad` file, grouped with `/* [Section] */` comments so OpenSCAD's Customizer picks them up.
- Shared helpers live in `lib/common.scad`; import with `use <../../lib/common.scad>`.
- Use `$fn = $preview ? 32 : 96;` so previews stay snappy and renders stay smooth.

## Exporting STLs

```bash
openscad -o models/<name>/exports/<name>.stl models/<name>/<name>.scad
```

Pass parameters for variants:

```bash
openscad -D 'phone_width=80' -o exports/phone-stand-pixel.stl phone-stand.scad
```
