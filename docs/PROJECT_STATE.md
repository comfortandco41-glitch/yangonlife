# Project State — Yangon Life (ရန်ကုန် ဘဝ)

**Last Updated:** 2026-10-19  
**Current Milestone:** M0–M1 — Foundation & Playable Life Simulation Prototype (**DONE & VERIFIED**)  
**Status:** READY FOR M2 (City Map Expansion & Vehicles)

---

## 1. Project Classification
- **Genre:** Open-World Urban Life Simulation (Low-Poly 3D)
- **Setting:** Downtown Yangon, Myanmar (Sule Pagoda, Maha Bandula Park, colonial shophouses, tea stalls)
- **Combat Status:** Strictly NON-COMBAT. Previous FPS prototype safely archived in `archive/fps_prototype/`.
- **Target Platforms:** Windows 10/11 Desktop, Modern Web Browsers (WebGL2), Headless Dedicated Server

---

## 2. Milestone Tracking
- **M0 — Repository Pivot & Architecture Baseline:** DONE (100%)
  - Storage policy: 100% of tools, engine, builds, and assets isolated on Drive D: (`D:\Games\ygn frontier`).
  - Engine setup: Godot 4.7.2 self-contained (`_sc_`) on Drive D: (`D:\Tools\Godot\godot.cmd`).
  - Architecture documents: Comprehensive life sim specs ([GDD.md](file:///d:/Games/ygn%20frontier/docs/GDD.md), [ARCHITECTURE.md](file:///d:/Games/ygn%20frontier/docs/ARCHITECTURE.md), [CAREERS_AND_ECONOMY.md](file:///d:/Games/ygn%20frontier/docs/CAREERS_AND_ECONOMY.md), [SIMULATION_SYSTEMS.md](file:///d:/Games/ygn%20frontier/docs/SIMULATION_SYSTEMS.md), [MAP_DATA.md](file:///d:/Games/ygn%20frontier/docs/MAP_DATA.md), [ART_BIBLE.md](file:///d:/Games/ygn%20frontier/docs/ART_BIBLE.md), [UI_AND_CONTROLS.md](file:///d:/Games/ygn%20frontier/docs/UI_AND_CONTROLS.md), [MULTIPLAYER.md](file:///d:/Games/ygn%20frontier/docs/MULTIPLAYER.md), [DEPLOYMENT.md](file:///d:/Games/ygn%20frontier/docs/DEPLOYMENT.md), [TESTING.md](file:///d:/Games/ygn%20frontier/docs/TESTING.md), [DECISIONS.md](file:///d:/Games/ygn%20frontier/docs/DECISIONS.md)).

- **M1 — Core Simulation Loop & Playable Downtown Yangon Prototype:** DONE (100%)
  - **Autoload Singletons:**
    - `GameManager` (`scripts/systems/game_manager.gd`): Input action registration, pause toggle.
    - `EconomyManager` (`scripts/economy/economy_manager.gd`): MMK wallet (50,000 MMK starting capital), transactions, overdraft protection.
    - `NeedsManager` (`scripts/simulation/needs_manager.gd`): Hunger, energy, hygiene, stress simulation with configurable decay rates, sprint gating, work efficiency modifiers.
    - `TimeManager` (`scripts/simulation/time_manager.gd`): 24-hour game clock (1 real second = 1 game minute), time strings, day periods, day/night cycles, bulk time advances.
    - `CareerManager` (`scripts/careers/career_manager.gd`): Job catalog (Delivery Worker, Street Vendor, Tea Shop Worker, Taxi Driver, Shopkeeper), employment states, 8-hour work shifts, efficiency-based pay calculation.
    - `InteractionManager` (`scripts/interaction/interaction_manager.gd`): Contextual proximity tracking (Physics Layer 4), prompt dispatch, interaction triggering.
    - `SaveManager` (`scripts/save/save_manager.gd`): Versioned JSON persistence (`user://yangon_life_save.json`), saving/loading across economy, needs, time, careers, and player transform.
  - **Player Entity:**
    - `ThirdPersonController` (`scripts/player/third_person_controller.gd`): WASD locomotion, stamina-checked sprinting, jumping, mouse-look orbiting with spring arm pitch clamping (-80° to +60°), pointer capture and release.
    - `player.tscn` (`scenes/player/player.tscn`): Low-poly capsule character on Layer 2 (Characters) colliding with Layer 1 (World), 3 (Vehicles), 4 (Interactables), nested SpringArm3D and Camera3D.
  - **Downtown Yangon Prototype Map:**
    - `downtown_yangon.tscn` (`scenes/world/downtown_yangon.tscn`): Directional warm sun, procedural sky, ground plane, road grid (MainRoad_NS, MainRoad_EW, SideStreets), 8 colonial & urban buildings, Maha Bandula style park with relax bench, interactable food stall, tea shop, and job board.
  - **Interactables Architecture:**
    - `InteractableZone` (`scripts/interaction/interactable_zone.gd`): Layer 4 Area3D component detecting player character and notifying `InteractionManager`.
    - `food_stall_handler.gd`: 3,000 MMK meal restoring 40 hunger.
    - `tea_shop_handler.gd`: 1,500 MMK Burmese tea restoring 15 hunger and relieving 10 stress.
    - `park_bench_handler.gd`: Free park relaxation reducing 25 stress.
    - `job_board_handler.gd`: Lists open downtown jobs and allows hiring.
  - **Heads-Up Display (HUD):**
    - `hud.tscn` (`scenes/ui/hud.tscn`): Top bar with Day counter, 24-hour clock, MMK wallet balance (`K 50,000` with comma separators), bottom-left progress bars (Hunger, Energy, Hygiene, inverted Stress), bottom-center contextual action prompt (`[E]`).
  - **Main Game Composite:**
    - `main_game.tscn` (`scenes/main/main_game.tscn`): Top-level scene integrating DowntownYangon, Player, and HUD.

---

## 3. Latest Test & Verification Results
- **Automated Headless Test Runner (`tests/run_tests.gd`):**
  - **118 passed, 0 failed (100% pass rate).**
  - Exit code: 0.
- **Export Verification:**
  - **Windows Desktop Standalone:** `build/desktop/YangonLife.exe` (109MB) + `YangonLife.pck` (113KB) exported cleanly.
  - **Web / WebGL2 Browser:** `build/web/index.html` + `index.js` + `index.wasm` (39MB) + `index.pck` (113KB) exported cleanly.
  - **Local HTTP Serving Test:** Verified via `server/serve_web.js` with HTTP 200, `Cross-Origin-Opener-Policy: same-origin`, and `Cross-Origin-Embedder-Policy: require-corp`.

---

## 4. Current Blockers
- None.

---

## 5. Next Recommended Milestone (M2)
- **M2 Milestone — City Map Expansion & Vehicles:**
  - Procedural OpenStreetMap pipeline: convert real OSM downtown Yangon coordinates into expanded 3D building and road chunks.
  - Driveable vehicles: Yellow-top Yangon taxi sedan and delivery bicycle (`scenes/vehicles/`).
  - Vehicle mounting/dismounting with `F` key and driving physics.
  - Schedule-driven ambient pedestrians and road traffic.
