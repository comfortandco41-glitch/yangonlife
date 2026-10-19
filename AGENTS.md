# AGENTS.md — Instructions for Autonomous AI Engineers

## 1. Project Purpose & Scope
**Project:** Yangon Frontline  
**Genre:** Low-Poly First-Person Shooter (FPS)  
**Setting:** Stylized, fictionalized downtown Yangon, Myanmar (colonial facades, shopfronts, streets, urban atmosphere).  
**Opposing Factions:**
1. **MILITARY** (Fictionalized conventional armed forces)
2. **PDF** (People's Defence Force — fictionalized local resistance fighters)

**Play Modes:**
- **Mode A (Offline Single-Player):** 100% standalone gameplay with local AI, mission objectives, health/combat, restart flow, no internet required.
- **Mode B (Online Multiplayer):** 4–8 players, authoritative server, team selection, synchronized combat, state reconciliation.
- **Mode C (Browser Play):** Web export (Chrome, Edge, Firefox), WebGL2/Compatibility rendering, pointer lock, WebSockets transport for multiplayer.

---

## 2. Hard Storage Rule (Drive D Only)
> [!IMPORTANT]
> **ALL DOWNLOADS, DEPENDENCIES, ENGINES, CACHES, TEMPLATES, AND BUILDS MUST BE KEPT ON DISK D: (`D:\...`).**
> Never place tools, packages, or temporary files on Drive C:. Godot runs in self-contained mode (`_sc_`) at `D:\Tools\Godot` with its data in `D:\Tools\Godot\editor_data`.

---

## 3. Technical Stack
- **Engine:** Godot Engine 4.7+ (Self-contained at `D:\Tools\Godot`).
- **Renderer:** `gl_compatibility` (WebGL 2.0 compatible for Web and Desktop).
- **Language:** GDScript (statically typed where practical).
- **Version Control:** Git (`d:\Games\ygn frontier`).
- **Networking Target:** WebSockets / ENet (via WebSocket multi-target transport) for browser & desktop compatibility.
- **Authoritative Server:** Headless Godot instance or Node.js WebSocket server.

---

## 4. Architecture Principles
1. **Separation of Simulation & Transport:** Local gameplay (movement, weapons, AI, mission logic) operates independently from networking. Networking synchronizes state via well-defined interfaces (`NetworkManager`, `CombatSync`).
2. **Component & Decoupled Design:** Do not put all logic in one gigantic player script. Separate into `PlayerController`, `HealthComponent`, `WeaponManager`, `HitboxComponent`.
3. **Data-Driven Configuration:** Weapons, AI parameters, and mission parameters should be stored in Godot `Resource` files (`.tres`) or structured dictionaries.
4. **Browser-First Rendering:** Use the `gl_compatibility` renderer. Avoid desktop-only compute shaders, high-end volumetric fog, or features unsupported by WebGL2.

---

## 5. Coding & Style Conventions
- **Files & Directories:** Lowercase with underscores (`snake_case.gd`, `player_controller.gd`).
- **Classes:** `PascalCase` with `class_name` registered when reusable.
- **Variables & Functions:** `snake_case` (e.g., `current_health`, `take_damage()`).
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `MAX_AMMO = 30`).
- **Signals:** Past tense or event style (e.g., `health_changed(new_health)`, `weapon_fired`).
- **Type Hints:** Use explicit types for functions and variables (e.g., `func take_damage(amount: float) -> void:`).

---

## 6. Directory Structure
```
yangon-frontline/
├── AGENTS.md
├── README.md
├── project.godot
├── docs/
│   ├── GDD.md
│   ├── ARCHITECTURE.md
│   ├── PROJECT_STATE.md
│   ├── ROADMAP.md
│   ├── TASKS.md
│   ├── DECISIONS.md
│   ├── LEVEL_DESIGN.md
│   ├── ART_BIBLE.md
│   ├── AI_SYSTEMS.md
│   ├── CONTROLS_AND_UI.md
│   ├── MULTIPLAYER.md
│   ├── DEPLOYMENT.md
│   ├── TESTING.md
│   └── CHANGELOG.md
├── scenes/
│   ├── main/
│   ├── player/
│   ├── weapons/
│   ├── characters/
│   ├── environment/
│   ├── missions/
│   └── ui/
├── scripts/
│   ├── player/
│   ├── combat/
│   ├── ai/
│   ├── missions/
│   ├── networking/
│   └── systems/
├── assets/
│   ├── models/
│   ├── materials/
│   ├── textures/
│   ├── audio/
│   └── animations/
├── server/
└── tests/
```

---

## 7. Testing & Verification Rules
1. **Never mark a task `DONE` without verification.**
2. Run Godot in headless or test mode (`godot --headless --run-tests` or scripted verification test harness) to verify scene loading, script syntax, and logic.
3. Every test execution and result must be documented in `docs/TESTING.md` and summarized in `docs/PROJECT_STATE.md`.
4. Browser exports must be tested against real local web servers with proper MIME types.

---

## 8. Documentation Continuity
Before starting any task:
1. Read `AGENTS.md` and `docs/PROJECT_STATE.md`.
2. Inspect `docs/TASKS.md` and `docs/ROADMAP.md`.
3. Inspect the code files involved.

After finishing a task:
1. Update code and run verification tests.
2. Update `docs/PROJECT_STATE.md`, `docs/TASKS.md`, and `docs/CHANGELOG.md`.
3. Update `docs/DECISIONS.md` if architectural choices were made.
