# Slicers on macOS

A slicer converts the `.stl` files OpenSCAD produces into printer-ready G-code. Pick the one matching the user's printer brand — using the matching slicer means stock printer profiles work out of the box, so the user doesn't have to hand-configure print settings.

## Brand → slicer map

| Printer brand | Slicer | Install |
|---|---|---|
| **Bambu Lab** (X1/X1C, P1S/P1P, P2S, X2D, A1/A1 Mini, H2D, and newer) | Bambu Studio | `brew install --cask bambu-studio` |
| **Prusa** (MK3/MK4/Mini/XL/Core One) | PrusaSlicer | `brew install --cask prusaslicer` |
| **Creality, Ender, generic Marlin/Klipper** | OrcaSlicer | `brew install --cask orcaslicer` |
| Other / unsure | OrcaSlicer | Safest general default — Bambu Studio fork with broad Marlin/Klipper support |

This is intentionally brand-keyed, not model-keyed — Bambu, Prusa, and Creality all keep releasing new models, but the slicer choice has stayed stable per brand. Don't try to enumerate every individual model.

## After install

Open the slicer once to confirm it launches and complete the first-run setup (sign in for Bambu Studio if the user wants cloud features; otherwise local-only works).

Then point the user at the model directory to test:

```bash
open -a "Bambu Studio" models/<any-model>/exports/<name>.stl
```

(Substitute `PrusaSlicer` or `OrcaSlicer` as appropriate.)

In the slicer:

1. Confirm the printer profile matches the user's specific model (top-right dropdown)
2. Confirm the filament matches what's loaded
3. Slice — if the time/material estimate appears, the toolchain is fully working

## Bed-size lookup

For the `parametric-model` skill to size designs correctly, Claude needs the user's printer's actual bed dimensions. When you first set up the slicer:

1. Have the user pick their printer model in the slicer's printer-selection dialog
2. Note the build volume the slicer displays (or web-search the exact model)
3. Record it for later use — for example, mention it in the conversation so subsequent design work has it in context

Different Bambu models have very different beds — A1 Mini is 180 × 180, most current models (X1/X1C, P1S/P1P, A1) are 256 × 256, H2D is 350 × 320, and newer models (P2S, X2D, and whatever ships after) may differ again. Don't assume — look it up in the slicer's printer-selection screen or on the product page.
