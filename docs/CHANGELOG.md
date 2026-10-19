# Changelog — Yangon Life

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.0] - 2026-10-19 — Project Pivot to Yangon Life

### BREAKING CHANGES
- **Complete Game Direction Pivot:** The project has pivoted from a tactical first-person shooter (*Yangon Frontline*) to an open-world low-poly life simulation (*Yangon Life*).
- All weapon systems, combat raycasts, military factions (MILITARY vs. PDF), and violent combat mechanics have been permanently discontinued from active development and moved to archival storage.

### Removed
- **Combat Mechanics:** Removed assault rifles, sidearms, marksman rifles, muzzle flashes, procedural recoil, bullet tracers, and reload systems.
- **Combat Components:** Decommissioned `HealthComponent`, `HitboxComponent`, and team friendly-fire filtering logic from active scene pipelines.
- **Hostile AI Systems:** Removed military patrol and attack finite state machines (`AISoldier`).
- **Shooter HUD:** Removed weapon reticle, ammunition counters, and kill tracking interfaces.
- **Archive Migration:** All legacy shooter scenes, scripts, and tests have been archived under `archive/fps_prototype/`.

### Added
- **Third-Person Character Controller:**
  - Responsive third-person character rig with smooth WASD movement, sprint multiplier, jumping, and gravity physics.
  - Orbital third-person camera using `SpringArm3D` with collision-aware raycasting to prevent camera clipping through building walls and urban geometry.
- **Needs & Simulation System:**
  - Real-time simulation of vital character needs: `hunger`, `energy`, `hygiene`, and `stress`.
  - Continuous needs decay over in-game time, driving player engagement with food stalls, rest spots, and baths.
  - Singleton manager registered: `NeedsManager` (`res://scripts/simulation/needs_manager.gd`).
- **In-Game Economy System (Myanmar Kyat):**
  - Authentic currency model using Myanmar Kyat (MMK).
  - Starting player balance initialized to 50,000 MMK.
  - Transaction validation logic preventing overdrafts and negative purchase exploits.
  - Global singleton registered: `EconomyManager` (`res://scripts/economy/economy_manager.gd`).
- **Career System Framework:**
  - Career progression framework supporting authentic Yangon professions (shopkeeper, taxi driver, delivery worker, street food vendor).
  - Shift scheduling, task objectives, performance evaluations, and wage payouts.
  - Global singleton registered: `CareerManager` (`res://scripts/careers/career_manager.gd`).
- **Contextual Interaction System:**
  - Proximity-based interaction detection for street stalls, convenience shops, vehicles, and NPCs.
  - Action mapping for primary interaction (`E` key) and vehicle entry/exit (`F` key).
  - Purchase and dialogue modal UI system.
  - Global singleton registered: `InteractionManager` (`res://scripts/interaction/interaction_manager.gd`).
- **Downtown Yangon Prototype Map (OpenStreetMap):**
  - Low-poly urban map slice based on real-world OpenStreetMap GIS data.
  - Centered on Sule Pagoda roundabout origin `(0, 0, 0)` with metric grid alignment.
  - Modeled landmarks including Sule Pagoda, Maha Bandula Park, colonial shophouses, and roadside tea stalls with plastic stools.
- **Save & Load System:**
  - Versioned JSON serialization storing player coordinates, wallet balance, inventory items, and needs stats.
  - Compatible with Windows local filesystem and browser storage (`IndexedDB` / `localStorage`).
  - Automated schema version validation and graceful fallback handling.
  - Global singleton registered: `SaveManager` (`res://scripts/save/save_manager.gd`).
- **Life Simulation Documentation Suite:**
  - Updated architectural diagrams, game design specifications, and roadmap milestones for the life simulation genre.
  - Created complete multiplayer architecture specification (`docs/MULTIPLAYER.md`).
  - Created production export and deployment guide (`docs/DEPLOYMENT.md`).
  - Created 13-category quality assurance testing guide (`docs/TESTING.md`).
  - Documented Architecture Decision Records ADR-001 through ADR-010 (`docs/DECISIONS.md`).

### Changed
- **Project Identity:** Renamed project in `project.godot` to `"Yangon Life"`.
- **Autoload Configuration:** Configured seven core life simulation singletons: `GameManager`, `EconomyManager`, `NeedsManager`, `TimeManager`, `SaveManager`, `CareerManager`, and `InteractionManager`.
- **Physics Layer Definitions:** Updated layer names: Layer 1: `World`, Layer 2: `Characters`, Layer 3: `Vehicles`, Layer 4: `Interactables`.
- **Keybindings:** Added dedicated bindings for `inventory` (I), `map` (M), `phone` (P), and `enter_vehicle` (F).

---

## [0.1.0] - 2026-10-19 — Original FPS Prototype (Archived)

> [!NOTE]
> All systems and features below represent the initial tactical first-person shooter milestone (*Yangon Frontline*). These assets have been archived to `archive/fps_prototype/` and are no longer active in the main project.

### Added
- **Drive D: Hard Storage Isolation:**
  - Configured Godot Engine 4.7.2 in self-contained mode (`_sc_`) at `D:\Tools\Godot`.
  - Installed official export templates (Windows, Web, Linux, Android) into `D:\Tools\Godot\editor_data\export_templates\4.7.2.stable\`.
- **FPS Core Gameplay Prototype (M1):**
  - First-person player controller with WASD movement, sprint, jump, mouse-look pitch/yaw, and ADS zoom.
  - Raycast assault rifle (MA-1 Vanguard) with ammo counter, recoil kickback, reload timing, and bullet tracer visual effect.
  - Decoupled `HealthComponent` and `HitboxComponent` with friendly-fire filtering.
  - Hostile `AISoldier` with finite state machine (`IDLE`, `PATROL`, `CHASE`, `ATTACK`, `DEAD`) and 90° FOV sight cone.
  - Downtown Yangon prototype arena with asphalt road, barricades, red transit bus, and sandbag bunkers.
  - In-game HUD with crosshair, health gauge, ammo tracker, damage flash, and victory/defeat restart flow.
- **Verification & Builds:**
  - Automated headless test suite with 39 assertions passing headlessly.
  - Initial Windows desktop executable (`build/desktop/YangonFrontline.exe`).
  - Initial WebGL2 browser export (`build/web/index.html`) served via `serve_web.js` with COOP/COEP headers.
