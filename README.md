# IDIOTS! — Godot v0.0.8-alpha.5 / Feel Restoration

This is a **focused first-90-seconds combat and visual experiment**, based on the Godot alpha.4 branch, not a new gameplay redesign.

What's deliberately different from alpha.4:
- Earlier and more varied enemy arrivals; meaningful encounters within the first minute.
- Bigger class HP pools and more distinct Jimothy / Kram / Bog attack patterns.
- Wall-aware, separation-based autonomous movement rather than walking straight into a boundary.
- Archer projectiles that are visible and can be missed, instead of invisible instant damage.
- Visible melee sweep arcs, hit flares, stagger/knockback and restrained impact rings.
- Freer chicken movement with fire/poison/ice trails and direct peck attacks; faster wing-animated bee swarms.
- Layered, pixel-quantized village environments, silhouettes, outlines and cleaner retro UI.
- Diagnostic first-90-second combat checks and counters (`tests/test_feel.gd`).

Core live engineering, 20 parts, Renown, weapon evolutions, and the long continuous expedition remain intact. Nothing from the rejected five-shift or laboratory experiments was imported.

**Goal:** improve responsiveness and the entertaining chaos of the first ninety seconds compared to the HTML alpha. This version is not a claim of full visual or content parity.

Automated tests in the PR verify GDScript grammar, engineering effects, scene import, short-term pace and Web export. A successful export is not proof of subjective fun. Please compare it directly with the HTML v0.7.3 reference and report where Godot still feels weaker.

See [MIGRATION_PARITY.md](MIGRATION_PARITY.md) for remaining gaps.

---

## Run / verify

Open `project.godot` in Godot 4.7.2 and press F5. Use the same keyboard controls as alpha.2: Space pauses, F uses a field kit, F11 toggles fullscreen. Parts unlock through mid-run discovery prompts; after choosing, click their inventory tiles to place them. Renown upgrades appear on the character-select screen after returning from a run.

Automated checks: `godot --headless --path . --script res://tests/test_grammar.gd`, `godot --headless --path . --script res://tests/test_parity.gd`, and `godot --headless --path . --script res://tests/test_engineering.gd`. PR CI also smoke-tests the scene, builds the Web export, and attaches a Web artifact. **A successful headless test is not a substitute for browser playtesting**; an exported Godot app must be served by HTTP with its HTML/WASM/PCK siblings.

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
