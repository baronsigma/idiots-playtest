# IDIOTS! — Godot v0.0.8-alpha.2

A Godot 4.7.2 GDScript migration slice based on the surviving **alpha.6.1** continuous-battle prototype. It is not a full campaign port.

## Changes since alpha.1 hotfix

- Enlarged HUD and primary controls, clear HP and Local Concern meters.
- Bigger character selection cards with pixel sprites.
- Sprite-backed engineering tiles, legible wire controls, compact invention cards and inventory.
- Fullscreen option (F11), proportional scaling to available window size, non-HiDPI default to reduce tiny-render issues on scaled monitors.
- Preserved original encounter logic, persistent independent inventions and deterministic procedural combination grammar.
- Added Web export preset and a GitHub Pages auto-deployment workflow (not yet deployed).

## Run locally

Open `project.godot` in **Godot 4.7.2**, press F5. In the editor you may need to disable embedded-game mode or enlarge the embedded preview if it appears miniature. During gameplay F11 toggles fullscreen.

## Give every alpha its own stable browser URL

1. Create a **public GitHub repository** for this project and push the project files (including the hidden `.github/workflows/pages.yml`).
2. In repository **Settings → Pages**, set **Source: GitHub Actions**.
3. Push to `main` or manually run **Actions → Publish playable IDIOTS! test build**.
4. Once the deployment completes, the Pages tab shows the actual URL. The same URL serves future builds after subsequent pushes.

The workflow installs Godot 4.7.2 and its web export templates, exports HTML5 and deploys all required `.html`, `.wasm`, `.pck`, and script assets. A Godot Web build cannot be opened by visiting an HTML file without these companion files being hosted.

**Current limitation:** This project was assembled and reviewed in the sandbox, where Godot 4.7.2 itself wasn't available for direct testing. The GitHub Actions workflow has not been executed or verified on an actual repository, so any export issues will need to be diagnosed from the first workflow run.

## Controls

- Space: pause
- F: field kit
- F11: fullscreen
- Click part, then board slot: swap/assign; click wires to split or merge contraptions.

## Test targets

- Runtime imports and GDScript parsing in Godot 4.7.2.
- Godot web export and browser launch.
- Hero selection, equipment, independent inventions, field kit.
- Connection order invariance in the grammar (`tests/test_grammar.gd`).
- Scaling on Retina / high DPI and mobile widths (mobile UX still needs further work).

The original HTML alpha.6.1 remains under `reference/` for behavioral comparison; the Godot project does not depend on it.
