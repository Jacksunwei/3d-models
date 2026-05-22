# OpenSCAD install on macOS — the cask gotcha

## The trap

There are two Homebrew casks named similarly. They behave very differently:

| Cask | What you get | Has CLI? |
|---|---|---|
| `openscad` | An `.app` directory that is just a stub — no working binary inside | **No** |
| `openscad@snapshot` | The modern dev build with a real CLI binary at `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD` | **Yes** |

`brew list --cask | grep openscad` reports the stub cask as installed. `which openscad` may even succeed. But `openscad --version` or `openscad -o file.stl input.scad` will fail because there is no real binary inside the .app.

Always verify by actually running the binary, not by checking package state.

## Install or fix

If the stub cask is currently installed, uninstall it first (otherwise the snapshot install can land in a conflicting state):

```bash
brew uninstall --cask openscad 2>/dev/null    # noop if not installed
brew install --cask openscad@snapshot
```

The snapshot cask installs the app as `/Applications/OpenSCAD.app` (same path as the stub, just with a real binary inside it).

## Verify it works

```bash
"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" --version
```

Expected: a year-based version like `OpenSCAD version 2026.04.26`. If it says `2021.01`, the stub cask got installed again — repeat the uninstall/reinstall above.

End-to-end check — render any existing model in `models/`:

```bash
"/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" -o /tmp/setup-test.stl models/<any-model>/<name>.scad
```

If the output reports `Status: NoError` and `/tmp/setup-test.stl` is non-zero size, the install is good.

## Optional shell alias

Long path. Add to `~/.zshrc` (or whatever shell rc):

```bash
echo 'alias openscad="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"' >> ~/.zshrc
source ~/.zshrc
```

After this, `openscad --version` works directly.

## If the cask install path changes in the future

The snapshot cask might switch app name (e.g., `OpenSCAD (Nightly).app`) in a future release. If that happens:

1. Run `find /Applications -maxdepth 3 -name OpenSCAD -type f` to find the real binary
2. Update `AGENTS.md` with the new path — it is the single source of truth for the CLI path that other skills (like `parametric-model`) reference
3. Update the shell alias to match
