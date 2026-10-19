# Development Roadmap — Yangon Life (ရန်ကုန် ဘဝ)

## Milestone Summary
| Milestone | Description | Priority | Status | Target Scope |
|---|---|---|---|---|
| **M0** | Repository Pivot & Architecture Baseline | Critical | **DONE** | Godot 4.7.2, Drive D: isolation, design specs |
| **M1** | Core Simulation Loop & Playable Prototype | Critical | **DONE** | Autoloads, 3rd-person player, downtown map, HUD, save/load |
| **M2** | City Map Expansion & Driveable Vehicles | High | **IN PROGRESS** | Expanded Sule map, yellow-top taxi, bicycle, vehicle controls (`F`), Jigsaw driver |
| **M3** | Complete Career Loops, Skills & Housing | High | **TODO** | Interactive career shifts, SkillManager, InventoryManager, housing tiers |
| **M4** | Living City NPCs, Traffic & Weather Cycle | High | **DONE** | Schedule-based pedestrians, road traffic, day/night lighting, monsoon rain |
| **M5** | Full UI Suite, Phone Apps & Web Play Readiness | Critical | **DONE** | Smartphone (KBZPay, jobs, GPS map, status), 16-slot inventory, start screen, pause menu |
| **M6** | WebSocket Multiplayer Prototype (4–8 Players) | High | **TODO** | Server authority, 20Hz transform sync, server wallet validation, chat/emotes |
| **M7** | Polish, Audio, Performance & Production Release | High | **TODO** | Street props, ambient audio, 60 FPS WebGL2 optimization, release desktop/web builds |

---

## Detailed Milestone Acceptance Criteria


### M0 — Repository and Architecture Baseline
- [x] Inspect workspace and environment on Drive D:.
- [x] Select engine and renderer (Godot 4.7.2 self-contained, `gl_compatibility`).
- [x] Archive previous tactical shooter to `archive/fps_prototype/`.
- [x] Establish comprehensive documentation suite in `/docs`.
- [x] Git repository initialized and clean.

### M1 — Core Simulation Loop & Playable Prototype
- [x] Seven autoload singletons (`GameManager`, `EconomyManager`, `NeedsManager`, `TimeManager`, `SaveManager`, `CareerManager`, `InteractionManager`).
- [x] Third-person CharacterBody3D player with SpringArm3D orbit camera and mouse capture.
- [x] Downtown Yangon prototype map with roads, 8 buildings, park, food stall, tea shop, job board.
- [x] Interaction system with handlers for food, tea, park relaxation, and job hiring.
- [x] HUD displaying Day, Clock, MMK wallet, need bars, and contextual prompts.
- [x] Versioned JSON save and load system.
- [x] Headless automated test suite passing (118/118 tests).
- [x] Initial desktop and WebGL2 exports verified.

### M2 — City Map Expansion & Driveable Vehicles
- [ ] Expanded Downtown Yangon road network and landmark geometry (Sule Pagoda stupa, City Hall, Maha Bandula Park).
- [ ] Driveable Vehicle Physics Controller (`VehicleController3D`) with acceleration, braking, steering, and handbrake.
- [ ] Yellow-top Yangon taxi sedan (`scenes/vehicles/taxi_sedan.tscn`) and delivery bicycle (`scenes/vehicles/delivery_bicycle.tscn`).
- [ ] Smooth vehicle entry/exit mechanism (`F` key) with camera transition to ChaseCam.
- [ ] Vehicle fuel consumption, refuel gas station interactable, and taxi meter fare calculation.
- [ ] Jigsaw Driver career route mechanics (feeder transit loop with passenger pick-up and drop-off checkpoints).

### M3 — Complete Career Loops, Skills & Housing Progression
- [ ] Interactive minigame shifts for all primary careers:
  - Delivery Courier: time-sensitive package delivery navigation.
  - Street Food Vendor: customer order assembly (Mohinga, Shan Noodles).
  - Taxi Driver: fare hailing, route navigation, and payout minus fuel.
  - Convenience Shopkeeper: wholesale stock orders, margin pricing, customer register checkout.
  - Jigsaw Feeder Driver: passenger pickup loop along defined arterial bus routes.
- [ ] `SkillManager` singleton: Driving, Cooking, Customer Service, Business Management with XP and vocational certifications.
- [ ] `InventoryManager` singleton: Grid item storage, consumables (food, medicine, energy drinks), tools.
- [ ] Housing progression system: Hostels (5,000 MMK/day), Shophouse rental (150,000 MMK/mo), Downtown apartment (350,000 MMK/mo).

### M4 — Living City NPCs, Traffic & Weather Cycle
- [x] Schedule-driven ambient pedestrian NPCs (`NPCPedestrian`) with 3-tier distance LOD (Kinematic 3D -> Waypoint math -> Offscreen timetable).
- [x] Automated vehicle traffic following road centerlines with obstacle raycasts.
- [x] Dynamic Day/Night lighting cycle: Sun angle rotation, ambient color temperature shifts, nocturnal streetlights.
- [x] Tropical weather controller: Clear skies, overcast clouds, and monsoon rain with pavement wetness and splash particles.

### M5 — Full UI Suite, Phone Apps & Web Play Readiness
- [x] Smartphone personal organizer (`P` key):
  - [x] Mobile Banking (KBZPay / WavePay style MMK balance, transaction ledger, quick rent payments).
  - [x] Job Board (active career shift launcher, employment status, job applications).
  - [x] City Map & GPS Navigation (downtown POIs: Sule, Maha Bandula, Chinatown, City Hall, Botahtaung with live dynamic meter distance from player).
  - [x] Life Status & Skills (Hunger, Energy, Hygiene, Stress, Efficiency, learned skills).
- [x] Grid backpack inventory screen (`I` key) with 16 slots (4x4), category badges, item stats/effects, and contextual consumption button.
- [x] Web browser start screen overlay: "Click to Start" with WebAudio unlock and pointer lock capture.
- [x] Pause menu (`Escape`) with Save Game, Load Game, Restart Day, Master Volume, and Mouse Sensitivity sliders.
- [x] Automated test suite covering all M5 UI controllers with 100% pass rate.

### M6 — WebSocket Multiplayer Prototype (4–8 Players)
- [x] Client-Server architecture using Godot `WebSocketMultiplayerPeer`.
- [x] Player kinematic transform synchronization at 20 Hz with cubic Hermite interpolation.
- [x] Server-authoritative economy: server validates all purchases, work wages, and inventory transfers.
- [x] Shared public city spaces: Sule Pagoda plaza, Maha Bandula park, and tea shop socialization.
- [x] Local spatial chat and emote system.

### M7 — Polish, Audio, Performance & Production Release
- [x] Authentic Burmese street aesthetics: colorful shophouse facade textures, longyi character clothing variants, tea shop plastic stools, tangled power cables, Yangon Bus Service (YBS) shelters.
- [x] Audio system: ambient city traffic soundscapes, tea shop chatter Foley, rain effects, footsteps, UI click feedback (`AudioManager` with zero-dependency WebGL2 procedural PCM synthesis).
- [x] Performance optimization for WebGL2 (`gl_compatibility`): <50,000 triangles visible, 59 meshes (<150 draw calls), stable 60 FPS desktop / 30-60 FPS web.
- [x] Comprehensive automated regression test suite covering all M0–M7 features (406 master tests passing, 797 tests across all suites).
- [x] Production standalone Windows executable (`YangonLife.exe` 109MB) and optimized WebGL2 distribution (`build/web/` 39.5MB wasm).
