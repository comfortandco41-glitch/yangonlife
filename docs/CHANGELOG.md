# Changelog — Yangon Frontline

## [0.1.0] - 2026-10-19 — Milestone M0 & M1 Completion
### Added
- **Drive D: Hard Isolation Setup:**
  - Configured Godot Engine 4.7.2 in self-contained mode (`_sc_`) at `D:\Tools\Godot`.
  - Installed official export templates (Windows, Web, Linux, Android) into `D:\Tools\Godot\editor_data\export_templates\4.7.2.stable\`.
  - Ensured zero tool overhead and zero downloads on Drive C:.
- **Documentation Suite:**
  - `AGENTS.md` (Agent instructions, technical stack, Drive D: storage rules).
  - `README.md` (Game overview, controls, run instructions).
  - `docs/GDD.md` (Vision, opposing factions: MILITARY vs PDF, weapon specs, gameplay loop).
  - `docs/ARCHITECTURE.md` (Scene structure, decoupled components, raycast combat pipeline, web considerations).
  - `docs/PROJECT_STATE.md` (Source of truth and milestone tracking).
  - `docs/ROADMAP.md` (Milestones M0 through M7 with granular acceptance criteria).
  - `docs/TASKS.md` (Task backlog with statuses and verification results).
  - `docs/DECISIONS.md` (ADR-001 through ADR-004: Engine, Renderer, Storage, Component Architecture).
  - `docs/LEVEL_DESIGN.md` (Downtown Yangon arena specifications, cover props, bus).
  - `docs/ART_BIBLE.md` (Low-poly aesthetics, color palettes, faction uniforms, asset standards).
  - `docs/AI_SYSTEMS.md` (State machine: IDLE, PATROL, CHASE, ATTACK, DEAD; perception cone).
  - `docs/CONTROLS_AND_UI.md` (Controls, browser pointer capture, HUD wireframes).
  - `docs/MULTIPLAYER.md` (Authoritative server architecture, WebSocket transport, state sync).
  - `docs/DEPLOYMENT.md` (Desktop & WebGL export commands, Nginx / Node.js web server headers).
  - `docs/TESTING.md` (Automated headless tests and verification checklist).
  - `docs/CHANGELOG.md` (Release tracking).
- **Core Gameplay Systems (M1):**
  - `PlayerController` (`scenes/player/player.tscn`): WASD movement, sprint, jump, gravity, ground collision, mouse-look pitch/yaw, ADS camera zoom, procedural weapon sway and bob.
  - `WeaponManager` (`scenes/weapons/rifle_m1.tscn`): MA-1 Vanguard assault rifle with raycast hit resolution, magazine tracking (30/90), reload timing, procedural kickback recoil, muzzle flash, bullet tracer.
  - `HealthComponent` & `HitboxComponent` (`scripts/combat/`): Decoupled damage calculation, friendly-fire filtering, health clamping, death signals.
  - `AISoldier` (`scenes/characters/ai_soldier.tscn`): Hostile military AI with FSM (`IDLE`, `PATROL`, `CHASE`, `ATTACK`, `DEAD`), 90° FOV sight cone raycast check, burst rifle fire, collapse on death.
  - `YangonArena` (`scenes/environment/yangon_arena.tscn`): 60m x 28m downtown Yangon urban arena with asphalt road, road markings, raised curbs, sidewalks, colonial facades, red city transit bus cover, Jersey barricades, sandbag bunkers, and perimeter walls.
  - `HUD` (`scenes/ui/hud.tscn`): Crosshair, real-time health bar and counter, ammo counter and reload warning, PDF faction badge, objective tracking, directional damage flash, victory and defeat dialogs, mission restart flow (`F5` / button).
  - `MissionClearSector` (`scenes/main/main_game.tscn`): Mission coordinator handling spawning, player tracking, enemy defeat count, victory/defeat triggers, and restart.
- **Verification & Builds:**
  - Automated headless test suite (`tests/run_tests.gd`): 39 unit/integration assertions passing headlessly with exit code 0.
  - Web export (`build/web/index.html`): WebGL2/WASM build successfully exported and served with Node.js test server (`server/serve_web.js`) with COOP/COEP headers.
  - Desktop export (`build/desktop/YangonFrontline.exe`): Standalone 64-bit Windows executable generated and verified.
