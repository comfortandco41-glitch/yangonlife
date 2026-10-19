# Yangon Frontline (ရန်ကုန် ရှေ့တန်း)
**Low-Poly Urban First-Person Shooter | Offline & Online Multiplayer | WebGL Browser Play**

---

## 1. Overview
**Yangon Frontline** is a stylized low-poly tactical first-person shooter set in a fictionalized downtown Yangon, Myanmar. Featuring colonial architecture, crowded street corridors, shopfronts, and alleyways, the game pits two fictionalized opposing factions against each other in urban skirmishes:
- **MILITARY:** Fictionalized conventional military force with standardized tactical gear.
- **PDF (People's Defence Force):** Fictionalized urban resistance fighters utilizing civilian-hybrid tactical gear.

---

## 2. Core Game Modes
1. **Mode A — Offline Single-Player:** Full local game loop with responsive FPS mechanics, local AI bots, objectives, health/damage system, score tracking, and restart capability. No internet or authentication required.
2. **Mode B — Online Multiplayer:** 4–8 player urban matches, authoritative server architecture, team selection, synchronized combat, and match reconciliation.
3. **Mode C — Browser Play:** Playable directly in modern desktop web browsers (Chrome, Edge, Firefox) using WebGL2/Compatibility rendering and pointer capture.

---

## 3. Current Development Status
- **Current Milestone:** M1 — Offline FPS Prototype (In Progress)
- **Engine Version:** Godot Engine 4.7.2 (Running self-contained on Drive D: at `D:\Tools\Godot`).
- **Target Renderer:** `gl_compatibility` (WebGL2 / OpenGL ES 3.0 compatible).

---

## 4. Requirements & Setup
- **Disk Storage:** Drive D: (`D:\Games\ygn frontier` and `D:\Tools\Godot`).
- **Engine Executable:** `D:\Tools\Godot\godot.cmd` (or console binary).
- **Node.js:** v20+ (for local test servers and browser serving).

### Running in Godot (Desktop)
```powershell
# Run the project directly from project root
& "D:\Tools\Godot\godot.cmd" --path "D:\Games\ygn frontier"
```

### Running Headless Tests
```powershell
& "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" -s tests/run_tests.gd
```

---

## 5. Controls
| Action | Input |
|---|---|
| **Movement** | `W`, `A`, `S`, `D` |
| **Look** | Mouse Movement (Pointer Locked) |
| **Shoot** | `Left Mouse Button` |
| **Aim Down Sights** | `Right Mouse Button` |
| **Sprint** | `Shift` |
| **Jump** | `Space` |
| **Reload** | `R` |
| **Pause / Menu** | `Escape` |
| **Restart Mission** | `F5` / UI Button |

---

## 6. Architecture & Documentation Links
All core design and technical specifications are maintained in the `/docs` folder:
- [Game Design Document (GDD)](docs/GDD.md)
- [System Architecture](docs/ARCHITECTURE.md)
- [Project State & Live Status](docs/PROJECT_STATE.md)
- [Development Roadmap](docs/ROADMAP.md)
- [Task Backlog](docs/TASKS.md)
- [Architecture Decisions (ADR)](docs/DECISIONS.md)
- [Level Design](docs/LEVEL_DESIGN.md)
- [Art Bible](docs/ART_BIBLE.md)
- [AI Systems](docs/AI_SYSTEMS.md)
- [Controls & UI](docs/CONTROLS_AND_UI.md)
- [Multiplayer Specification](docs/MULTIPLAYER.md)
- [Deployment & Web Export](docs/DEPLOYMENT.md)
- [Testing Procedures](docs/TESTING.md)
- [Changelog](docs/CHANGELOG.md)

---

## 7. Known Limitations
- Initial prototype uses clean low-poly geometric meshes for buildings and characters.
- Browser build requires pointer lock permission and user click to activate WebAudio.
- Online multiplayer currently planned for 4–8 players using WebSocket transport for browser compatibility.
