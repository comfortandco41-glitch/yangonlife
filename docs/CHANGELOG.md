# Changelog — Yangon Life

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.7.1] - 2026-10-19 — Hotfix: Player Spawn Collision & 3D Asset Integration

### Fixed
- **Player Spawn Collision & Camera Clipping Inside Sule Pagoda:**
  - Resolved issue in `scenes/main/main_game.tscn` where `Player` was initialized at `(0, 1, 0)` directly inside the 8-meter solid cylinder collision base of Sule Pagoda, which trapped player movement and forced the third-person spring arm camera to clip inside the yellow stupa geometry.
  - Aligned initial player spawn transform in `main_game.tscn` to `(0, 1, 14)` on Sule Pagoda Road plaza.
  - Added runtime safety clamp in `scripts/player/third_person_controller.gd` (`_ready()`) ensuring any player spawning within 8.0m of world origin automatically relocates to `DowntownYangon/SpawnPoint` or `(0, 1, 14)`.
  - Added `margin = 0.2` to `SpringArm3D` in `scenes/player/player.tscn` to prevent near-plane clipping against geometry.

### Added
- **Kenney Suburban & City 3D Asset Integration (`assets/new/kenney_cityKitSuburban/`):**
  - Instanced lush large and small trees (`tree_large.glb`, `tree_small.glb`) across Maha Bandula Park around the Independence Monument and along Sule Pagoda Road sidewalks.
  - Added decorative colonial perimeter fencing (`fence_large.glb`) along park boundaries.
  - Added multi-story colonial houses and suburban shophouses (`house_type01.glb`, `house_type04.glb`, `house_type15.glb`) to Downtown Yangon building blocks.
- **SuperRetroWorld Character Pack 2D Portrait Integration (`assets/new/SuperRetroWorld_CharacterPack_Full/`):**
  - Integrated 2D character avatar portraits into `scenes/ui/hud.tscn` top-left citizen header.
  - Integrated resident avatar portrait into Phone Menu (`scenes/ui/phone_menu.tscn`) Home screen and Life Status app (`character_1`).
  - Added KBZPay banking agent avatar (`character_2`) into Mobile Banking app.
  - Added Yangon Jobs employment recruiter avatar (`character_3`) into Careers app.

## [0.7.0] - 2026-10-19 — Production Release: Milestones M2–M7 Complete

### Added
- **Milestone M2 (City Map Expansion & Driveable Vehicles):**
  - `VehicleController` (`scripts/vehicles/vehicle_controller.gd`): Reusable CharacterBody3D driving physics, steering, acceleration, braking, fuel consumption, taxi meter, and save/load persistence.
  - Iconic yellow-top Yangon taxi sedan (`scenes/vehicles/taxi_sedan.tscn`) and courier delivery bicycle (`scenes/vehicles/delivery_bicycle.tscn`).
  - `JigsawRouteRunner` (`scripts/careers/jigsaw_route_runner.gd`): 4-stop arterial transit loop.
  - Golden octagonal Sule Pagoda stupa, neoclassical City Hall, Independence Monument obelisk, and refuel gas pump.
- **Milestone M3 (Complete Career Loops, Skills & Housing):**
  - `SkillManager` (`scripts/skills/skill_manager.gd`): 5 skills (driving, cooking, customer service, business, mechanic) with 1–5 level thresholds and vocational perks.
  - `InventoryManager` (`scripts/inventory/inventory_manager.gd`): 16-slot grid backpack with authentic consumable catalog (Mohinga, Shan Noodles, Laphet Yay, Sparks, Herbal Balm, Thanaka, Kun-ya) and needs effects.
  - `HousingManager` (`scripts/housing/housing_manager.gd`): 5 housing tiers (Park Bench to Heritage Shophouse), rent schedules, rest restoration, and eviction safety net.
  - Career shift runners: `DeliveryRunner`, `StreetVendorRunner`, `TaxiShiftRunner`.
- **Milestone M4 (Living City NPCs, Traffic & Weather):**
  - Schedule-driven ambient pedestrians (`NPCPedestrian`) with 3-tier distance LOD (Full 3D -> Waypoint math -> Offscreen timetable) and Burmese dialogue.
  - Automated road traffic (`TrafficCar` YBS red bus) with forward obstacle RayCast3D and tire traction modulation.
  - Celestial day/night lighting cycle and `CPUParticles3D` monsoon rain weather controller.
- **Milestone M5 (Full UI Suite & Phone Apps):**
  - Burmese smartphone personal organizer (`P` key): KBZPay Banking, Jobs board, GPS Map POIs, Life Status apps.
  - 16-slot grid backpack inventory (`I` key) with item detail cards and consumption button.
  - Browser start screen with WebAudio unlock and mouse pointer capture.
  - Pause menu (`Escape`) with Save/Load and audio/sensitivity settings.
- **Milestone M6 (WebSocket Multiplayer Prototype):**
  - Client-server architecture with `WebSocketMultiplayerPeer` (port 8910, 20 Hz tick rate).
  - Server-authoritative economy: Zero client trust for MMK balance, purchases, and wage deposits.
  - `RemotePlayer` multiplayer puppet entity with cubic Hermite transform interpolation and billboard nameplate.
  - Dedicated headless server scene (`server/server.tscn` & `server/server_main.gd`).
- **Milestone M7 (Polish, Audio, Performance & Production Release):**
  - `AudioManager` (`scripts/systems/audio_manager.gd`): Zero-dependency procedural 16-bit PCM sound synthesis for WebGL2 and Desktop (UI clicks, MMK coin chimes, footsteps, ambient city murmur, and rain hiss).
  - Street aesthetics: roadside plastic tea shop stools (red & blue), YBS bus stop shelter with bench and signage, roadside utility poles.
  - Performance optimization for WebGL2: 59 draw meshes (<150 limit), 28 physics bodies (<100 limit), lightweight vertex-lit shaders.
  - Comprehensive master test suite (`tests/run_tests.gd`) with 406/406 tests passing (797 tests across all suites).
  - Production standalone Windows executable (`YangonLife.exe` 109MB) and optimized WebGL2 distribution (`build/web/` 39.5MB wasm).

---

## [0.5.0] - 2026-10-19 — Milestone M5: Full UI Suite, Phone Apps & Web Play Readiness

### Added
- **Smartphone Personal Organizer (`scripts/ui/phone_controller.gd` & `scenes/ui/phone_menu.tscn`):**
  - Burmese Android smartphone interface toggled with `P` or closed via `Escape`.
  - **KBZPay / WavePay Banking App:** Real-time MMK balance, transaction ledger (income/expense logging), and quick "Pay Rent" action.
  - **Jobs App:** Displays current role, shift status (8-hr / 480 mins), available downtown job openings, "Start Shift", and resignation actions.
  - **GPS Map App:** Live dynamic distance calculation in meters from player to 5 downtown POIs (Sule Pagoda, Maha Bandula Park, Chinatown 19th St, Yangon City Hall, Botahtaung Pagoda).
  - **Status App:** Visual gauges for Hunger, Energy, Hygiene, Stress, overall work efficiency rating, and acquired vocational skills.
  - 3-button navigation bar (Back, Home, Close) and quick dock launcher.
- **Grid Backpack Inventory (`scripts/ui/inventory_menu_controller.gd` & `scenes/ui/inventory_menu.tscn`):**
  - 16-slot grid (4x4) displaying item names, quantity badges, and category pills (`FOOD`, `DRINK`, `MISC`).
  - Item detail card with descriptions and stat effects.
  - "Use / Eat / Drink" consumption action integrating directly with `InventoryManager` and `NeedsManager`. Toggled with `I` or `Escape`.
- **Browser Click-to-Play Overlay (`scripts/ui/start_screen_controller.gd` & `scenes/ui/start_screen.tscn`):**
  - Full-screen CanvasLayer overlay (layer 50) with Burmese-English title and control instruction card.
  - Click-to-start action locking mouse pointer (`Input.MOUSE_MODE_CAPTURED`) and unlocking WebAudio context for browser compatibility.
- **Pause Menu & Settings Overlay (`scripts/ui/pause_menu_controller.gd` & `scenes/ui/pause_menu.tscn`):**
  - Pause overlay running in `PROCESS_MODE_ALWAYS`, toggled with `Escape`.
  - Resume Game, Save Game (calls `SaveManager.save_game()` with toast), Load Game (calls `SaveManager.load_game()` with toast), Restart Day.
  - Master Volume slider (0% to 100%) attenuating `AudioServer` bus.
  - Mouse Sensitivity slider (0.001 to 0.010) tuning third-person player camera rotation.
- **Milestone M5 Automated Test Suite (`tests/test_m5_ui_suite.gd`):**
  - 75 unit assertions verifying all 4 UI scenes and controllers under Godot 4.7.2 headless execution.

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
