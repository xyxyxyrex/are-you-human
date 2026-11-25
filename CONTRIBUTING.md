# Contributing & Developer Guide

Everything needed to develop, test, and extend **Are You Human?** is self-contained or automatically bootstrapped by this repository.

## 1. Prerequisites & Zero-Config Setup

- **Required**: Git + Internet connection (first run only, to download Godot `4.7.2-stable` into `.tools/godot/` if not already installed).
- **Optional**: Python `3.10+` (enables the static `.tscn`/`.tres` resource path checker in `verify`), Node.js `22+` (only if you want to install extra global skills via `npx skills`).

### Windows (PowerShell / CMD)
```powershell
.\setup.bat        # Downloads Godot 4.7.2-stable to .tools/godot/, imports assets, and runs all 51 tests
.\run_game.bat     # Launches the game
.\open_editor.bat  # Opens the project in Godot 4.7.2 Editor
.\verify.bat       # Runs static checks + headless compile + audio bus + gameplay test suite
```

### macOS & Linux
```bash
chmod +x setup.sh run_game.sh open_editor.sh verify.sh
./setup.sh         # Downloads Godot 4.7.2-stable to .tools/godot/, imports assets, and runs all 51 tests
./run_game.sh      # Launches the game
./open_editor.sh   # Opens the project in Godot 4.7.2 Editor
./verify.sh        # Runs static checks + headless compile + audio bus + gameplay test suite
```

> **Custom Godot Path**: Set `GODOT_BIN=/path/to/godot` to override automatic resolution.

---

## 2. Project Structure

```text
are-you-human/
├── autoload/
│   ├── save_manager.gd       # Versioned atomic JSON save/load (.tmp + .bak recovery)
│   ├── sound_bank.gd         # Procedural 16-bit PCM synth SFX, numbers-station tones & ambient pad
│   └── game_state.gd         # Campaign data tables, economy math, unlocks, bots, prestige & endings
├── scripts/
│   ├── puzzles/
│   │   ├── captcha_host.gd   # Interactive controller for all 9 verification challenges
│   │   └── captcha_canvas.gd # Custom _draw() renderers (rotate, wavy OCR, oscilloscope, jigsaw, ECG, vault)
│   └── ui/
│       ├── main_hud.gd       # 3-column Forum Browser HUD, Adware tab, 12-node Prestige grid & modals
│       ├── ad_popup.gd       # Draggable retro adware pop-ups & Golden 2.5x Frenzy ads
│       ├── pixel_art_canvas.gd # Runtime nearest-neighbor pixel sprite generator
│       └── pixel_theme.gd    # Crisp Silkscreen-Bold + VT323 pixel Theme & StyleBox builder
├── assets/
│   ├── fonts/                # Bundled OFL pixel fonts (Silkscreen-Bold, VT323-Regular) + licenses
│   └── shaders/              # crt_overlay.gdshader, dither_bg.gdshader, fire_box.gdshader
├── scenes/
│   └── main.tscn             # Main entry scene
├── tests/
│   ├── test_runner.tscn      # Headless integration & layout test scene
│   └── test_runner.gd        # 51 assertions covering every system & screen resolution
└── .agents/skills/           # 16 bundled Agent Skills + Godot 4.7 static/headless verifiers
```

---

## 3. How to Extend the Game

### Adding a New CAPTCHA Variant
1. Add an entry to `VARIANT_DEFS` in `autoload/game_state.gd` (`id`, `name`, `forum`, `unlock_cost`, `base_pay`, `desc`).
2. Add a `match variant_id:` branch in `CaptchaHost.load_variant()` and `CaptchaHost.submit_verification()` (`scripts/puzzles/captcha_host.gd`). If it needs custom 2D drawing, add a `CanvasMode` enum value in `scripts/puzzles/captcha_canvas.gd`.
3. `tests/test_runner.gd` automatically iterates `GameState.VARIANT_DEFS` to test unlocking and solving every non-boss variant; add specific edge-case assertions there and run `verify`.

### Adding Forums, Upgrades, Adware Tiers, Bots, or Prestige Perks
All progression tables are data-driven `const Array[Dictionary]` definitions at the top of `autoload/game_state.gd`:
- **`FORUM_DEFS`**: Forum domain, color theme, unlock cost, password fragment, and thread clue.
- **`ADWARE_DEFS`**: Unlockable Adware monetization tiers shown in the `📢 ADS` tab.
- **`UPGRADE_DEFS` / `BOT_DEFS`**: Repeatable rig upgrades and automation daemons.
- **`PERK_DEFS`**: Permanent `Clearance Token (CT)` nodes rendered in the `4×3` CYBERCOM Prestige Grid.

---

## 4. Bundled AI Agent Skills
`.agents/skills/` ships 16 portable [Agent Skills](https://agentskills.io) (`godot-*`, `game-ui-ux`, `game-feel`, `save-systems`, `tdd`, `diagnosing-bugs`, `code-review`, `grill-with-docs`, `codebase-design`) loaded automatically by Antigravity, Cursor, Codex, Gemini CLI, and GitHub Copilot. To install the full upstream catalogs globally:
```bash
npx skills@latest add gamedev-skills/awesome-gamedev-agent-skills -g
npx skills@latest add mattpocock/skills -g
```
