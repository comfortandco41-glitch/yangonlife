# AGENTS.md — Instructions for Autonomous AI Engineers

> [!IMPORTANT]
> **PROJECT CLASSIFICATION: OPEN-WORLD LIFE SIMULATION**  
> **THIS IS A LIFE SIMULATOR, NOT A SHOOTER.**  
> Under no circumstances should combat, military factions, firearms, deathmatches, or shooter mechanics be introduced into this project. All game systems, scenes, scripts, and documentation must center on life simulation, careers, economic progression, character needs, social interactions, city navigation, and urban life in Yangon, Myanmar.

---

## 1. Project Purpose & Scope
- **Project Name:** Yangon Life (ရန်ကုန် ဘဝ)
- **Genre:** Low-Poly Open-World Urban Life Simulation
- **Setting:** Stylized, recognizable downtown Yangon, Myanmar (Sule Pagoda, Maha Bandula Park, City Hall, colonial shophouses, tea stalls, bustling bus stops, and markets).
- **Core Player Experience:** Live an ordinary life in Yangon: arrive with modest savings, find lodging, manage daily needs (hunger, energy, hygiene, stress), work jobs or run small businesses, earn Myanmar Kyat (MMK), learn skills, buy vehicles, build relationships, and upgrade living standards.

### Supported Play Modes:
1. **Mode A (Offline Single-Player):** 100% standalone, fully local gameplay. Complete local simulation loop with AI schedules, traffic, career shifts, shopping, housing, and JSON-based local save/load. No internet connection, account, or external server required.
2. **Mode B (Online Multiplayer):** 4–8 players sharing the urban world. Server-authoritative economy and state synchronization over WebSockets. Shared city spaces, peer trading, cooperative business operations, and local text/emote chat.
3. **Mode C (Browser Play):** Exported for modern desktop web browsers (Chrome, Edge, Firefox) using WebGL2 (`gl_compatibility` renderer), mouse pointer capture, click-to-initialize WebAudio, and optimized low-poly memory footprint.

---

## 2. Hard Storage Rule (Drive D: Only)
> [!CAUTION]
> **STRICT SYSTEM RULE: ALL STORAGE MUST REMAIN ON DRIVE D: (`D:\...`).**  
> - **NEVER** write or install dependencies, tools, SDKs, caches, temp files, or exports to Drive C: (`C:\...`).
> - Godot 4.7.2 runs in self-contained mode (`_sc_`) located at `D:\Tools\Godot\` with its editor data and templates stored within `D:\Tools\Godot\editor_data\`.
> - The workspace resides exclusively at `D:\Games\ygn frontier\`.
> - Temporary scripts, artifacts, and staging builds must reside in `D:\Games\ygn frontier\` or Drive D: subdirectories.

---

## 3. Technical Stack
- **Engine:** Godot Engine 4.7.2 (Self-contained 64-bit at `D:\Tools\Godot\godot.cmd`).
- **Language:** GDScript 2.0 with strict static typing (`:=`, `-> void`, explicit class references).
- **Renderer:** `gl_compatibility` backend (OpenGL ES 3.0 / WebGL2 compliant).
- **Version Control:** Git repository at `D:\Games\ygn frontier\`.
- **Target Platforms:** Windows 10/11 Desktop, HTML5/WebGL2 Browser.
- **Geographic Data:** OpenStreetMap (ODbL) pre-baked into native Godot scenes.
- **Networking:** Godot `WebSocketMultiplayerPeer` (runs uniformly on native desktop and web browsers).
- **Web Serving / Tooling:** Node.js v20+ / Python 3.x (Drive D:) for headless data processing and local HTTP testing.

---

## 4. Architectural Principles
1. **Third-Person Perspective:** Player character is controlled from a third-person orbit camera (`SpringArm3D` + `Camera3D`) attached to a `CharacterBody3D`. Locomotion rotates character toward movement vector with responsive acceleration and deceleration.
2. **Decoupled Simulation & Transport:** Local simulation managers (`NeedsManager`, `EconomyManager`, `CareerManager`, `TimeManager`, `SaveManager`) operate completely independently of networking. Multiplayer networking acts strictly as an external synchronization bridge over the local simulation state.
3. **Component-Based Modularity:** Character, vehicle, and world nodes compose functionality through distinct components (`InteractionComponent`, `NeedsComponent`, `InventoryComponent`, `ScheduleFollowerComponent`) rather than monolithic inheritance trees.
4. **Data-Driven Configuration:** Jobs, items, NPC schedules, vehicle specs, and dialogue trees are defined as Godot `Resource` (`.tres`) files or typed data structures rather than hardcoded script logic.
5. **Browser-First Asset Budgeting:** Every visual mesh and texture must be optimized for WebGL2. Use unshaded or low-poly vertex-lit materials, atlas textures, simple box/capsule colliders, and avoid desktop-only compute shaders or volumetric effects.

---

## 5. Coding & GDScript Conventions
- **Files & Folders:** Lowercase snake_case (`character_controller.gd`, `needs_manager.gd`, `shop_counter.tscn`).
- **Class Names:** `PascalCase` with explicit `class_name` registration on reusable classes (e.g., `class_name ThirdPersonController extends CharacterBody3D`).
- **Variables & Functions:** `snake_case` (e.g., `var current_hunger: float = 80.0`, `func purchase_item(...) -> bool:`).
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `const MAX_ENERGY: float = 100.0`, `const STARTING_CASH: int = 50000`).
- **Signals:** Event-driven, past-tense naming (e.g., `signal money_changed(new_balance: int)`, `signal shift_completed(job_id: String, earnings: int)`).
- **Static Typing Mandatory:** Every variable, function parameter, and return type must declare an explicit static type:
  ```gdscript
  func calculate_fare(distance_meters: float, duration_seconds: float) -> int:
      var base_fare: int = 1500
      var distance_charge: int = int(distance_meters * 1.2)
      return base_fare + distance_charge
  ```
- **Docstrings & Comments:** Document classes and exported variables with Godot docstring format (`## Summary comment`).

---

## 6. Directory Structure
```
d:\Games\ygn frontier/
├── AGENTS.md                  # Autonomous agent instructions (this file)
├── README.md                  # Project overview, controls, build instructions
├── project.godot              # Godot project definition & autoload configuration
├── export_presets.cfg         # Web & desktop export profiles
├── docs/                      # Core design, architecture, and system specifications
│   ├── GDD.md                 # Complete Game Design Document (Life Simulation)
│   ├── ARCHITECTURE.md        # Comprehensive engine & system architecture
│   ├── MAP_DATA.md            # OpenStreetMap data strategy, coordinates, pipeline
│   ├── PROJECT_STATE.md       # Current milestone status, health, and test status
│   ├── ROADMAP.md             # Development roadmaps and milestone schedule
│   ├── TASKS.md               # Active task backlog and sprint items
│   ├── DECISIONS.md           # Architecture Decision Records (ADRs)
│   ├── LEVEL_DESIGN.md        # Downtown Yangon layout, zoning, and landmark specs
│   ├── ART_BIBLE.md           # Low-poly aesthetic, color palettes, Burmese street culture
│   ├── CONTROLS_AND_UI.md     # Input schemes, HUD layout, and menu wireframes
│   ├── MULTIPLAYER.md         # WebSocket architecture, authority, and state sync
│   ├── DEPLOYMENT.md          # Desktop & Web build pipelines and server setups
│   ├── TESTING.md             # Headless test harnesses and verification criteria
│   └── CHANGELOG.md           # Release notes and sequential engineering log
├── scenes/
│   ├── main/                  # Top-level coordinators (main_game.tscn, world_root.tscn)
│   ├── player/                # Third-person player rig, camera arm, HUD
│   ├── world/                 # Chunked Downtown Yangon world, day/night, weather
│   ├── ui/                    # Menus, HUD, inventory grid, career window, dialogs
│   ├── vehicles/              # Driveable cars, taxis, bicycles, buses
│   ├── npcs/                  # Schedule-driven pedestrians, shopkeepers, customers
│   └── interactables/         # Stalls, doors, ATMs, beds, bus stops
├── scripts/
│   ├── systems/               # Core managers (game_manager.gd, time_manager.gd)
│   ├── player/                # Third-person locomotion, camera controllers
│   ├── economy/               # EconomyManager, transactions, prices
│   ├── simulation/            # NeedsManager, day/night cycle, weather
│   ├── careers/               # CareerManager, job shift runners, work minigames
│   ├── interaction/           # InteractionManager, interactable component scripts
│   ├── npcs/                  # NPC brain, schedule evaluator, LOD handler
│   ├── vehicles/              # Vehicle controller, traffic path followers
│   ├── save/                  # SaveManager, serialization, file I/O
│   └── networking/            # NetworkManager, WebSocket transport, state replication
├── assets/
│   ├── models/                # Low-poly GLTF/OBJ buildings, characters, vehicles
│   ├── materials/             # Spatial materials using vertex colors or simple palettes
│   ├── textures/              # Texture atlases, UI icons, road markings
│   └── audio/                 # Ambient Yangon street sounds, Foley, interface clicks
├── tools/
│   └── osm_to_godot.py        # Python pipeline converting OSM data to Godot scenes
├── server/                    # Headless Godot / Node.js WebSocket coordination server
└── tests/
    ├── run_tests.gd           # Headless GDScript test runner
    ├── test_economy.gd        # Unit tests for EconomyManager
    ├── test_needs.gd          # Unit tests for NeedsManager
    ├── test_save.gd           # Unit tests for save/load serialization
    └── test_interaction.gd   # Unit tests for interaction proximity logic
```

---

## 7. Testing & Verification Rules
1. **Never mark a task `DONE` without automated or headless verification.**
2. **Headless Execution:** Test all GDScript logic and scene loading using the self-contained Godot engine executable on Drive D:
   ```powershell
   & "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" -s tests/run_tests.gd
   ```
3. **No Unhandled Errors:** Any script modification must load cleanly with zero GDScript compile errors, warnings, or broken resource dependencies.
4. **Documentation Sync:** Every test pass, bug discovery, and resolution must be recorded in `docs/TESTING.md` and summarized in `docs/PROJECT_STATE.md`.
5. **Browser Verification:** Browser builds must be hosted locally on a web server (e.g., Python `http.server` or Node.js `serve` with Cross-Origin headers) and verified for WebGL2 canvas display, pointer locking, and audio context activation.

---

## 8. Git Safety Rules
1. **Atomic Commits:** Make small, clear commits with descriptive commit messages following the Conventional Commits specification (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`).
2. **Never Commit Engine Artifacts:** Never commit `.godot/`, `.import/`, `export_presets/`, temporary dumps, or log files. Ensure `.gitignore` is strictly respected.
3. **Inspect Status:** Always execute `git status --short` before making commits to ensure no unintended files or Drive C: references are staged.
4. **Working Tree Cleanliness:** Do not leave unverified scratch files in production directories. Clean up temporary test files immediately.

---

## 9. Browser Compatibility Requirements
- **Rendering:** Strictly use the `gl_compatibility` renderer. Features like SDFGI, VoxelGI, Volumetric Fog, and Compute Shaders are incompatible with WebGL2 and are strictly forbidden.
- **Pointer Capture:** Mouse capture in browsers requires explicit user interaction (`Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)` inside an input event handler). Provide a "Click to Play" overlay screen on initial launch.
- **Audio Context Unlock:** Modern browsers block audio until the user clicks on the page canvas. Audio must be queued or enabled only after the user interacts with the canvas.
- **Memory Footprint:** Keep total web build asset size under 50MB. Reuse color palette textures, low-poly geometry, and compressed OGG audio streams.

---

## 10. Documentation Continuity Rules
Before starting any development task:
1. Read `AGENTS.md` and check `docs/PROJECT_STATE.md`.
2. Review active items in `docs/TASKS.md` and milestones in `docs/ROADMAP.md`.
3. Inspect relevant scripts in `scripts/` and scenes in `scenes/`.

After completing any development task:
1. Verify functionality via headless test script or interactive testing.
2. Update `docs/PROJECT_STATE.md` with current progress.
3. Update `docs/TASKS.md` marking completed tasks with timestamp.
4. Add an entry to `docs/CHANGELOG.md`.
5. If architectural decisions were made, record them in `docs/DECISIONS.md`.
