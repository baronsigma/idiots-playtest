# IDIOTS! — Godot v0.0.8-alpha.3 parity branch

> Draft migration work. **Godot runtime and browser export are not yet verified.** Do not treat this branch as a stable playable release.

The primary reference is the original **continuous HTML alpha.6.1** (in `reference/`), not the discarded five-shift or Test Lab experiments.

This branch retains the Godot v0.0.8-alpha.2 battle and procedural combination grammar while beginning to restore the HTML game's content loop: timed part discoveries, two in-run signature weapon evolutions, saved Renown for capped HP/gold preparation, and basic specialist enemies. Core six-slot connections and live inventions remain active.

Read [MIGRATION_PARITY.md](MIGRATION_PARITY.md) for exact feature gaps and migration order. This is not full parity yet.

## Run / verify

Open `project.godot` in Godot 4.7.2 and press F5. Use the same keyboard controls as alpha.2: Space pauses, F uses a field kit, F11 toggles fullscreen. Parts unlock through mid-run discovery prompts; after choosing, click their inventory tiles to place them. Renown upgrades appear on the character-select screen after returning from a run.

Automated checks: `godot --headless --path . --script res://tests/test_grammar.gd` and `godot --headless --path . --script res://tests/test_parity.gd`. A GitHub Actions PR workflow attempts import, both tests, and a short scene smoke test. Until these run successfully, the build is **unverified**.

---

## Previous alpha.2 notes

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
