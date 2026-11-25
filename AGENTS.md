# AGENTS.md — Are You Human?

Godot **4.7.2-stable** (`gl_compatibility`) satirical retro incremental game.

## Verification Gate (Run Before Finishing Any Change)

Run `./verify.bat` (Windows) or `./verify.sh` (macOS/Linux). Every check must exit `0`:
1. `.agents/skills/godot-nodes-scenes/scripts/check_godot_project.py` — `0 errors, 0 warnings`.
2. `.agents/skills/godot-gdscript/assets/check_scripts_compile.gd` — `broken: 0`.
3. `.agents/skills/godot-audio/assets/check_audio_buses.gd` — `unknown bus references: 0`.
4. `res://tests/test_runner.tscn` — all assertions pass (`0 failed`), covering shaders, `.bak` save recovery, all CAPTCHA gates, Adware tiers, Prestige perks, endings, gamepad focus, and `1280×720` / `1720×720` bounds.

## Codebase Invariants

- **Strict Godot 4.7 Typing**: Annotate all variables, parameters, and return types. Use typed math helpers (`maxi`, `maxf`, `minf`, `clampi`, `clampf`, `absi`, `absf`) rather than `Variant`-returning `max`/`min`/`clamp`/`abs`. Cast `Dictionary`/`Array` lookups explicitly (`int(...)`, `float(...)`, `String(...)`).
- **Procedural Assets**: Audio waveforms (`autoload/sound_bank.gd`) and pixel sprites (`scripts/ui/pixel_art_canvas.gd`) are generated in code at runtime; fonts live in `assets/fonts/` with `FONT_ANTIALIASING_NONE`.
- **Save Safety**: Persist plain JSON primitives only (`user://autosave.json`) via `SaveManager.save_atomic()` (`.tmp` + `.bak` fallback). Convert JSON numbers with `int()`/`float()` on load.
- **UI & Accessibility**: Maintain `1280×720` base viewport (`canvas_items` + `expand`). Dual-code unaffordable/locked buttons with both high-contrast text (`NEED $...` / `🔒`) and `disabled = true`. Trap background focus with `focus_behavior_recursive` and `mouse_behavior_recursive` whenever a modal opens.

## Context Pointers

- **Extending Forums, CAPTCHAs, Adware, Upgrades, Bots, or Prestige Perks**: read [`CONTRIBUTING.md`](CONTRIBUTING.md).
- **Bundled Agent Skills** (auto-discovered from `.agents/skills/`):
  - Godot 4.7 APIs & checks: `godot-gdscript`, `godot-nodes-scenes`, `godot-ui-control`, `godot-shaders`, `godot-audio`, `godot-animation`, `godot-gdscript-headless-testing`, `godot-export`.
  - Cross-engine design & persistence: `game-ui-ux`, `game-feel`, `save-systems`.
  - Engineering workflows: `tdd`, `diagnosing-bugs`, `code-review`, `grill-with-docs`, `codebase-design`.
