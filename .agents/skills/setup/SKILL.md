---
name: setup
description: 'Install and configure the toolchain needed to design, render, and print models in this repo — OpenSCAD (with a working CLI), a slicer, and Homebrew if on macOS. Use whenever the user is freshly cloning the repo, asks "how do I get started", "what do I need to install", "set up the tools", says OpenSCAD or their slicer is broken or missing, gets a "command not found" error trying to render a model, or needs to install or update OpenSCAD or a slicer (Bambu Studio, PrusaSlicer, OrcaSlicer). Includes macOS-specific brew commands plus manual install guidance for other OSes. Knows about the OpenSCAD cask gotcha (the standard cask ships only a GUI stub with no working CLI binary — the snapshot cask is the one you actually want).'
---

# Setup — toolchain

Bring this repo from "freshly cloned" to "can edit, render, and slice". Three pieces:

1. **Homebrew** — package manager that installs everything else
2. **OpenSCAD (snapshot cask)** — modeling + CLI for rendering STL/PNG
3. **A slicer** — converts STL to printer-ready G-code (choice depends on the user's printer)

If only one piece is missing, jump straight to that phase. The full sequence below assumes a clean machine.

> **Platform note.** The commands below are for **macOS** (Homebrew + `brew install --cask ...`). For other OSes (Windows, Linux), the same three pieces are still needed but installation is manual — guide the user to each project's own install page, one piece at a time:
> - **Homebrew** is macOS / Linux only; on Windows skip it
> - **OpenSCAD** — download the *development snapshot* (NOT the stable 2021.01 release) from <https://openscad.org/downloads.html>
> - **Slicer** — download from the printer vendor's site (Bambu Studio, PrusaSlicer, OrcaSlicer)
>
> The cask/path guidance in `references/openscad-cask.md` is also macOS-specific. The principles (use the snapshot, verify with `--version`) carry over; the exact paths don't.

## Phase 1 — Check what is already installed

Before installing anything, inspect the current state. The OpenSCAD check is two-pronged because `brew list` can lie about it (see `references/openscad-cask.md`):

```bash
which brew                                                                # is Homebrew installed?
ls -la /Applications/OpenSCAD*.app 2>/dev/null                            # does the app exist?
"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" --version 2>&1       # does it actually run?
brew list --cask 2>/dev/null | grep -iE 'bambu-studio|prusaslicer|orcaslicer'   # any slicer?
```

Report findings and skip phases for things the user already has. The `--version` check is what matters for OpenSCAD: a year-based version (`2026.04.26`) means good; `2021.01` or an error means Phase 3 is needed.

## Phase 2 — Install Homebrew (if missing)

If `which brew` returned nothing, Homebrew needs to be installed. **Don't run this yourself with the Bash tool** — it is interactive, asks for the user's password (sudo), and the user should see what it's doing.

Tell the user to paste this into their terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After it finishes, ask them to run `which brew` and confirm it returns a path. On Apple Silicon Macs the installer also prints two `eval` lines to add brew to PATH — make sure those land in their shell rc file (`~/.zshrc` or `~/.bash_profile`).

## Phase 3 — Install OpenSCAD

**The standard `openscad` cask is a trap** — it installs a stub `.app` with no working CLI binary. Always use `openscad@snapshot` instead.

Quick install (assuming a clean machine):

```bash
brew uninstall --cask openscad 2>/dev/null    # noop if not installed; clears the stub if present
brew install --cask openscad@snapshot
"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" --version
```

Expect `OpenSCAD version 2026.XX.XX` (or newer). For the full gotcha explanation, verification steps, shell alias setup, and what to do if the install path changes in a future cask version, read `references/openscad-cask.md`.

## Phase 4 — Install a slicer

Ask which printer the user has (use **AskUserQuestion** if it has not come up yet), then install the slicer matching their printer's **brand** — Bambu Studio for any Bambu Lab printer, PrusaSlicer for any Prusa, OrcaSlicer for Creality/Ender/generic.

| Brand | Slicer | Install |
|---|---|---|
| Bambu Lab | Bambu Studio | `brew install --cask bambu-studio` |
| Prusa | PrusaSlicer | `brew install --cask prusaslicer` |
| Creality / Ender / other | OrcaSlicer | `brew install --cask orcaslicer` |

If the user has no printer yet, skip this phase. For first-launch setup, model-specific guidance, and a note about looking up the user's exact bed size (needed by the `parametric-model` skill), see `references/slicers.md`.

## Phase 5 — Verify with a test render

If there is at least one model in `models/`, do an end-to-end test to confirm everything works:

```bash
SCAD="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
F=$(find models -name '*.scad' | head -1)
"$SCAD" -o /tmp/setup-test.stl "$F" 2>&1 | tail -5
ls -la /tmp/setup-test.stl
```

If the STL is non-zero size and the output reports `Status: NoError`, the toolchain is working. Optionally open it in the slicer to confirm the round-trip:

```bash
open -a "Bambu Studio" /tmp/setup-test.stl     # or PrusaSlicer / OrcaSlicer
```

## Anti-patterns

- **Don't install the standard `openscad` cask** — it ships a stub with no working binary. Always use `openscad@snapshot`. (Details in `references/openscad-cask.md`.)
- **Don't run the Homebrew installer yourself** — it is interactive, needs the user's password, and is safer when the user runs it and sees what it is doing.
- **Don't trust `brew list --cask` alone** for OpenSCAD — it reports the stub install as present. Verify with `--version` on the actual binary path.
- **Don't hardcode the OpenSCAD path into multiple places.** If a future cask version changes the install path, update `AGENTS.md` and let other skills inherit from there.
- **Don't enumerate every specific printer model** when picking a slicer — Bambu, Prusa, and Creality all keep releasing new models. Map by brand instead, the way `references/slicers.md` does.
- **Don't install a slicer the user did not ask for.** Match the slicer to the user's actual printer.
