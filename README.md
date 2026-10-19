# Yangon Life (ရန်ကုန် ဘဝ)
**Open-World Urban Life Simulation | Low-Poly Yangon, Myanmar | Offline, Online & WebGL**

[![Godot Engine](https://img.shields.io/badge/Godot_Engine-4.7.2-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Renderer](https://img.shields.io/badge/Renderer-gl__compatibility-34495e)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](#)
[![Map Data](https://img.shields.io/badge/Map_Data-OpenStreetMap_(ODbL)-7eaa55?logo=openstreetmap&logoColor=white)](https://www.openstreetmap.org/copyright)

---

## 1. Game Overview
**Yangon Life** is an open-world, third-person life simulation game set in a stylized, recognizable downtown Yangon, Myanmar. 

Players step into the shoes of an everyday citizen beginning a new chapter in the vibrant commercial capital of Myanmar. Arriving with a modest sum of 50,000 Myanmar Kyat (MMK), you must navigate the opportunities and challenges of urban existence: finding affordable shelter in a colonial shophouse, managing daily biological needs (hunger, energy, hygiene, stress), earning a living through diverse careers or small enterprise, mastering new vocational skills, and building a prosperous life in the heart of Yangon.

> [!NOTE]
> **Yangon Life is a peaceful life simulation, NOT a shooter.** There are no combat factions, firearms, or violence. Gameplay emphasizes urban survival, economic progression, small business entrepreneurship, transportation, social community ties, and local Burmese culture.

---

## 2. Key Features
- **Third-Person Locomotion & Camera:** Smooth character movement, responsive sprinting, jumping, and an orbit camera rig with collision avoidance.
- **Real-World Yangon Map via OpenStreetMap:** Faithful downtown street grid modeled from Sule Pagoda to Maha Bandula Park, Yangon City Hall, and colonial boulevards.
- **Dynamic Needs System:** Biological needs simulation including Hunger, Energy, Hygiene, and Stress. Neglected needs directly affect stamina, sprinting ability, and job productivity.
- **Burmese Kyat (MMK) Economy:** Deep financial simulation featuring cash transactions, bank accounts, daily living expenses, wholesale inventory purchasing, and retail customer sales.
- **Diverse Career Paths & Small Business:**
  - *Shopkeeper:* Manage a downtown kiosk or convenience stall, stock shelves, set prices, and serve neighborhood customers.
  - *Taxi Driver:* Navigate bustling Yangon traffic, pick up commuters, manage fuel consumption, and optimize routes.
  - *Delivery Worker:* Courier parcel and food deliveries across the downtown corridor by foot, bicycle, or motorbike.
  - *Jigsaw Route Driver:* Operate shared feeder passenger trucks along designated neighborhood commuter routes.
  - *Street Food Vendor:* Cook and serve iconic dishes like Mohinga, samosas, and Laphet-yay tea from a mobile cart.
  - *Office & Tech Worker:* Entry-level clerical and freelance digital tasks at internet cafés and business centers.
- **Skills & Vocational Education:** Improve skills through practical experience and classes—Driving, Customer Service, Business Management, Cooking, Repair, and Tech. Earn certifications to qualify for higher-paying positions.
- **Housing Progression:** Advance from a budget hostel bunk bed to a rented room in a colonial building, a private studio apartment, and eventual property ownership.
- **Transportation Variety:** Walk the sidewalks, pedal bicycles, ride motorbikes, take metered taxis, or ride the YBS (Yangon Bus Service) public transit network.
- **Living City & NPC Simulation:** Schedule-based pedestrians and shopkeepers who commute, work, dine, pray at pagodas, and return home based on a 24-hour city clock.
- **Robust Save & Load System:** Versioned JSON save format supporting multiple save slots and persistent state tracking for economy, needs, skills, and inventory.
- **Three Play Modes:**
  1. *Offline Single-Player:* 100% self-contained local experience. No internet or login required.
  2. *Online Multiplayer:* 4–8 player shared city instances with server-authoritative economy and synchronized market trades.
  3. *Browser Play (WebGL2):* Instant zero-install playability in desktop web browsers.

---

## 3. Current Development Status
- **Current Milestone:** **M0 — Foundation & Architecture** (Under active development)
- **Engine Version:** Godot Engine 4.7.2 (Self-contained at `D:\Tools\Godot`)
- **Rendering Method:** `gl_compatibility` (WebGL 2.0 / OpenGL ES 3.0)
- **Repository Location:** `D:\Games\ygn frontier` (Drive D: only)

---

## 4. System Requirements & Setup
- **Operating System:** Windows 10/11 (64-bit) or modern web browser (Chrome, Edge, Firefox)
- **Engine Binary:** Godot Engine 4.7.2 self-contained at `D:\Tools\Godot\godot.cmd`
- **Disk Storage:** Drive D: strictly required for all development tools, assets, and builds
- **Node.js:** v20+ (for local web server testing and build automation)

### Running the Desktop Game
Launch the project directly with Godot from PowerShell:
```powershell
& "D:\Tools\Godot\godot.cmd" --path "D:\Games\ygn frontier"
```

### Running Headless Automated Tests
Execute the unit test harness without opening an editor window:
```powershell
& "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" -s tests/run_tests.gd
```

### Exporting and Testing Browser (WebGL) Build
Export the WebGL2 package and serve it locally:
```powershell
# Export project for web
& "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" --export-release "Web" "build/web/index.html"

# Run local HTTP server with correct COOP/COEP headers
npx serve -l 8080 build/web
```
Navigate to `http://localhost:8080` in Chrome, Firefox, or Edge.

---

## 5. Controls
| Action | Primary Input | Secondary / Gamepad | Description |
|---|---|---|---|
| **Move Forward / Back** | `W` / `S` | Up / Down / Left Stick | Walk in camera-relative direction |
| **Move Left / Right** | `A` / `D` | Left / Right / Left Stick | Strafe / turn character |
| **Sprint** | `Shift` | Left Stick Click / Button B | Run faster (consumes Energy) |
| **Jump** | `Space` | Gamepad Button A | Vault low curbs and obstacles |
| **Interact / Talk / Use** | `E` | Gamepad Button X | Interact with objects, NPCs, doors, stalls |
| **Camera Orbit** | Mouse Movement | Right Stick | Orbit third-person camera |
| **Camera Rotate Toggle** | `Right Mouse Button` | - | Hold/drag to inspect character angle |
| **Inventory** | `I` or `Tab` | Gamepad D-Pad Up | Open personal inventory & equipment |
| **Needs & Status HUD** | `U` | Gamepad D-Pad Right | View detailed hunger, energy, hygiene, stress |
| **City Map** | `M` | Gamepad View / Select | Open Downtown Yangon street map |
| **Smartphone / Career** | `P` | Gamepad D-Pad Down | View active jobs, bank balance, app notifications |
| **Enter / Exit Vehicle** | `F` | Gamepad Button Y | Board or exit cars, taxis, bicycles, buses |
| **Pause / Game Menu** | `Escape` | Gamepad Start | Pause game, access settings, save/quit |

---

## 6. Architecture & Documentation Links
Comprehensive documentation is maintained in the `docs/` directory:
- [Game Design Document (GDD)](docs/GDD.md) — Comprehensive game design, systems, economy, and careers
- [System Architecture](docs/ARCHITECTURE.md) — Software architecture, node hierarchies, autoloads, and patterns
- [Map Data & OSM Strategy](docs/MAP_DATA.md) — Geographic data pipeline, coordinates, and procedural geometry
- [Project State & Live Health](docs/PROJECT_STATE.md) — Current development status and test logs
- [Development Roadmap](docs/ROADMAP.md) — Milestone roadmap from M0 Foundation through Release
- [Task Backlog](docs/TASKS.md) — Detailed task tracking and implementation checklist
- [Architecture Decision Records (ADR)](docs/DECISIONS.md) — Documented technical choices and rationale
- [Level Design Guide](docs/LEVEL_DESIGN.md) — Downtown Yangon zoning, landmarks, and street design
- [Art Bible](docs/ART_BIBLE.md) — Low-poly aesthetics, architectural motifs, and color palettes
- [Controls & UI Guide](docs/CONTROLS_AND_UI.md) — UI wireframes, HUD layouts, and interaction patterns
- [Multiplayer Specification](docs/MULTIPLAYER.md) — WebSocket protocol, server authority, and synchronization
- [Deployment Guide](docs/DEPLOYMENT.md) — Desktop packaging and WebGL2 deployment pipelines
- [Testing Procedures](docs/TESTING.md) — Headless test frameworks, test matrices, and test cases
- [Changelog](docs/CHANGELOG.md) — Chronological record of code changes and releases

---

## 7. Known Limitations (Milestone M0)
- **Early Foundation:** Current milestone focuses on core architecture, autoloads (`EconomyManager`, `NeedsManager`, `GameManager`), and data schemas.
- **Low-Poly Placeholder Assets:** Initial visual scenes utilize stylized low-poly primitive shapes and flat-shaded materials while custom 3D assets are modeled.
- **Downtown Yangon Scope:** The initial playable environment is bounded to a 1km x 1km downtown slice centered around Sule Pagoda. Outer townships will be introduced in future expansions.
- **Browser Audio & Pointer Unlock:** As required by modern web security policies, web builds require an initial click on the game canvas to capture mouse input and enable WebAudio playback.

---

## 8. Map Data Attribution
Map data and geographic layouts are derived from **OpenStreetMap** data:
> Data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), licensed under the [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/).
