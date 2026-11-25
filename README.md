# Are You Human?

A *Scritchy Scratchy* × *Balatro* × *Hypnospace Outlaw*-inspired satirical retro incremental game built in **Godot 4.7**.

Surf an infinitely paginated trail of archived 1999–2007 dead-web forums, hunt `[⬇ DOWNLOAD HERE]` mirrors, survive shady file-host countdowns, `bit.ly` redirect chains, fake `.exe` decoys, and classic CAPTCHAs, monetize Adware pop-ups, and uncover whistleblower `u/NullPtr_99`'s 5-part Kill-Switch Password to stop `OMEGA_WIPE`.

## Quick Start (Zero-Config for New Devs)

No manual installs required — the bootstrap scripts automatically download **Godot 4.7.2-stable** into `.tools/godot/` if you don't already have it on `PATH`, import all assets, and run the automated test suite:

### Windows
```powershell
.\setup.bat        # First-time setup: downloads Godot 4.7.2 + imports + runs all tests
.\run_game.bat     # Play the game (starts on the bouncy CRT Main Menu!)
.\open_editor.bat  # Open in Godot 4.7.2 Editor
.\verify.bat       # Run static resource checks + strict compile + headless test suite
```

### macOS / Linux
```bash
./setup.sh         # First-time setup: downloads Godot 4.7.2 + imports + runs all tests
./run_game.sh      # Play the game
./open_editor.sh   # Open in Godot 4.7.2 Editor
./verify.sh        # Run full headless verification suite
```

## Core Features (v2.0)

- **Infinite Paginated Dead-Web Forums**: Scroll across procedural forum threads (`Page 1..∞`) packed with `[⬇ DOWNLOAD HERE]` attachments, `2.4×` hot leaks, and clickbait mirrors.
- **In-Feed Forum Discovery**: Future forums stay hidden until your trace signal nears threshold — then `u/NullPtr_99` posts an urgent redirect thread (`[🔗 FOLLOW LINK]`) right inside the forum feed!
- **14 CAPTCHA & Shady-Download Gates**:
  - *Visual & Biometric*: **Click All Squares** (starter), **Rotate Upright**, **Warped OCR Text**, **Numbers Station Audio**, **Slide-to-Fit Jigsaw**, **Cursor Wobble Sensor**, **Turing Logic**, and **Biometric Heartbeat**.
  - *Shady File-Host & Dark-Pattern Gates*: **5s Free-Host Countdown** (dodge fake `.exe` buttons), **Spot the 1 Real Download Button**, **3-Hop `bit.ly`/`adf.ly` Shortener Maze**, **Sneaky Bundled-Toolbar EULA**, **Cookie Consent Dark-Pattern**, plus the **☠ Final Dead-Drop Decrypt Boss**.
- **Unlockable Adware & 4 Pop-Up Styles**: Install Adware Tiers 1–4 to unleash Banner Ads, Win98 Trojan Alerts, 2.2× Countdown Video Ads, and 2.5× Golden Sponsor Frenzies.
- **Decluttered Progressive UI & Spring Physics**: Context-filtered shop shows only relevant unlocks, paired with a 4-step interactive onboarding coach and elastic `offset_transform` button/card bounce.

See **[CONTRIBUTING.md](CONTRIBUTING.md)** and **[AGENTS.md](AGENTS.md)** for architecture details and the 16 bundled AI Agent Skills in `.agents/skills/`.
