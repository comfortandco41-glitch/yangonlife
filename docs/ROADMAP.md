# Development Roadmap — Yangon Frontline

## Milestone Summary
| Milestone | Description | Priority | Status | Target Date |
|---|---|---|---|---|
| **M0** | Repository & Architecture Baseline | Critical | **DONE** | 2026-10-19 |
| **M1** | Offline FPS Prototype | Critical | **DONE** | 2026-10-19 |
| **M2** | Playable Yangon Environment | High | **TODO** | Milestone 2 |
| **M3** | Complete Offline Gameplay (Both Factions & Objectives) | High | **TODO** | Milestone 3 |
| **M4** | Browser Offline Build (Web Export) | Critical | **TODO** | Milestone 4 |
| **M5** | Multiplayer Prototype (4–8 Players) | High | **TODO** | Milestone 5 |
| **M6** | Browser Multiplayer Integration | High | **TODO** | Milestone 6 |
| **M7** | Polish, Optimization & Release | Medium | **TODO** | Milestone 7 |

---

## Detailed Milestone Acceptance Criteria

### M0 — Repository and Architecture
- [x] Inspect workspace and environment.
- [x] Select engine and renderer (Godot 4.7.2, `gl_compatibility`).
- [x] Configure self-contained engine and export templates on Drive D:.
- [x] Establish comprehensive documentation suite in `/docs`.
- [x] Git repository initialized with appropriate `.gitignore`.

### M1 — Offline FPS Prototype
- [x] Responsive FPS player controller (WASD, mouse-look, sprint, jump, gravity, ground detection).
- [x] Functional assault rifle weapon (shooting, raycast hit detection, ammo HUD, fire rate, recoil, reload).
- [x] Health and damage pipeline with team-aware hitboxes.
- [x] Hostile AI agent (detect, pursue, attack, take damage, die, obstacle avoidance).
- [x] Playable prototype Yangon downtown arena (streets, colonial shophouse silhouettes, cover barricades, bus).
- [x] Complete HUD with reticle, health bar, ammo counter, damage flash, and restart flow.
- [x] Headless test suite verifying clean initialization and core systems (39/39 passing).
- [x] Initial WebGL browser export & Windows desktop export verified.

### M2 — Playable Yangon Environment
- [ ] Modular low-poly colonial architecture (verandas, shuttered windows, shophouse awnings).
- [ ] Yangon street props: roadside tea shops, plastic stools, buses, tangled power lines, palm planters.
- [ ] Navigation mesh generation for complex urban routes.
- [ ] Stylized lighting and atmosphere (warm tropical sunlight, long afternoon shadows).

### M3 — Offline Gameplay (Factions & Missions)
- [ ] Faction selection: MILITARY vs. PDF.
- [ ] Mission objective system (Clear Sector, Defend Flag, VIP Escort).
- [ ] Advanced AI states: Cover seeking, flanking, suppression.
- [ ] Main menu, settings (mouse sensitivity, volume), and sound effects.

### M4 — Browser Offline Build
- [ ] Export project to WebGL2 / WebAssembly via Godot web templates.
- [ ] Browser-specific pointer lock on user interaction.
- [ ] WebAudio unlock on start screen.
- [ ] Verify execution in Chromium and Firefox via local HTTP server.

### M5 — Multiplayer Prototype
- [ ] Authoritative dedicated/listen server architecture.
- [ ] Player synchronization (movement interpolation, rotation, shooting events).
- [ ] Server-validated hit detection and damage resolution.
- [ ] Team score tracking, respawning, and match lifecycle.

### M6 — Browser Multiplayer
- [ ] WebSocket networking transport operational for web clients.
- [ ] Browser-to-server latency compensation and client-side prediction.
- [ ] Multi-client match verification across desktop and browser.

### M7 — Polish and Release Preparation
- [ ] Low-poly character visual refinement and weapon animations.
- [ ] Yangon city ambient audio, weapon foley, and Burmese voice callouts.
- [ ] Performance profiling: stable 60 FPS on mid-range hardware and web.
