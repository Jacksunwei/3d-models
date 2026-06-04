# Fitting to an existing part (frame, device, third-party model)

Sometimes the part isn't free-standing — it must mate with an object the user
already owns (a modular frame, a device, an accessory) that has published or
supplied models. Don't guess its geometry; **extract it**, then parameterise the
fit and let the user caliper-verify.

## Extract geometry from supplied STLs

Binary STL is trivial to parse — read it directly instead of eyeballing:

```python
# bounding box + per-axis "levels" reveal feature sizes
import struct
d = open(f, 'rb').read(); n = struct.unpack('<I', d[80:84])[0]
# 84 + i*50 : 12 normal, 3×12 verts, 2 attr  → walk and min/max each axis
```

Two cheap analyses that answer most questions:
- **Bounding box** per part → overall size (rail = 15×15×240, corner = 40×60×40…).
- **Slice profile**: bucket triangle *centroids* into Z bands and print the XY
  bbox per band → the vertical profile (e.g. "body 0–20 mm, then a 20×20 post
  20–40 mm" tells you exactly what protrudes above the mating surface).

Also render the imported STL orthographically (`import("…")` in a scratch `.scad`,
`--projection=ortho`, axis views) to read features visually.

## Parameterise the fit; caliper-verify

The STL gives nominal geometry, but the user's **printed** copy is what your part
must fit. So:
- Expose every fit-critical number as a parameter with the measured default:
  opening, mating-feature size, how far a feature sits proud of the surface,
  slip clearance.
- Tell the user the 2–3 caliper measurements that matter and that they should
  confirm them on the assembled object before printing a full set.
- Prefer measuring the **inner/clear** dimension the part drops into, and the
  **outer** edge-to-edge, and state which your parameter means — they're easy to
  confuse (e.g. "bar inner-edge to inner-edge = 255" vs outer span).

## ⚠️ Licence: reference assets are not yours to redistribute

Third-party models you download to measure against (MakerWorld, etc.) are often
under restrictive licences (e.g. **MakerWorld Exclusive License** forbids hosting
elsewhere). Keep them locally as references but **gitignore them** — never commit/
push them. Build an **original** parametric part inspired by the concept; don't
copy their geometry. Note this in the model README's credits.

```gitignore
# Third-party reference assets — not ours to redistribute
models/<name>/<their-stls>/
models/<name>/*.f3d
```

Worked example: `models/filament-rack/` (shelf fitted to the K.Flynn modular tube
frame — frame STLs measured then gitignored; shelf is original).
