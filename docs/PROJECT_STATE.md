# Project State — Yangon Life (ရန်ကုန် ဘဝ)

**Last Updated:** 2026-10-19  
**Current Milestone:** M0 through M7 — All Milestones Complete, Verified & Production Released (**100% DONE**)  
**Status:** PRODUCTION READY (Desktop Standalone & WebGL2 Browser Distribution)

---

## 1. Project Classification
- **Genre:** Open-World Urban Life Simulation (Low-Poly 3D)
- **Setting:** Downtown Yangon, Myanmar (Sule Pagoda, Maha Bandula Park, Yangon City Hall, colonial shophouses, tea stalls, bus stops)
- **Combat Status:** Strictly NON-COMBAT. Previous FPS prototype safely archived in `archive/fps_prototype/`.
- **Target Platforms:** Windows 10/11 Desktop, Modern Web Browsers (WebGL2), Headless Dedicated Server

---

## 2. Milestone Tracking

### M0 — Repository Pivot & Architecture Baseline: DONE (100%)
- Hard Storage Rule: 100% isolated on Drive D: (`D:\Games\ygn frontier`, `D:\Tools\Godot`).
- Engine: Godot 4.7.2 self-contained (`_sc_`) with `gl_compatibility` WebGL2 renderer.
- Architecture Suite: 17 complete documentation specifications in `docs/`.

### M1 — Core Simulation Loop & Playable Downtown Prototype: DONE (100%)
- Autoload singletons: `GameManager`, `EconomyManager`, `NeedsManager`, `TimeManager`, `SaveManager`, `CareerManager`, `InteractionManager`.
- Player: Third-person orbit controller with spring arm camera, stamina sprint, jump, mouse capture.
- Map: Low-poly downtown Yangon with 8 buildings, roads, Maha Bandula Park, and interactables.
- UI: Dynamic HUD with currency formatting, 24-hour clock, and needs progress bars.

### M2 — City Map Expansion & Driveable Vehicles: DONE (100%)
- `VehicleController` (`scripts/vehicles/vehicle_controller.gd`): Reusable CharacterBody3D driving physics, steering, acceleration, braking, fuel consumption, taxi meter, and save/load persistence.
- `TaxiSedan` (`scenes/vehicles/taxi_sedan.tscn`): Iconic yellow-top Yangon taxi with TAXI sign, headlights, door interaction area, and chase camera.
- `DeliveryBicycle` (`scenes/vehicles/delivery_bicycle.tscn`): Courier delivery bicycle with rear cargo basket and cycling physics.
- `JigsawRouteRunner` (`scripts/careers/jigsaw_route_runner.gd`): 4-stop feeder transit loop connecting Sule, Maha Bandula Park, Botahtaung Jetty, and Chinatown.
- Downtown Map Expansion: Golden octagonal Sule Pagoda stupa, neoclassical Yangon City Hall, Independence Monument obelisk, and gas station.

### M3 — Complete Career Loops, Skills & Housing: DONE (100%)
- `SkillManager` (`scripts/skills/skill_manager.gd`): Driving, Cooking, Customer Service, Business Management, and Mechanic skills with XP progression (levels 1–5).
- `InventoryManager` (`scripts/inventory/inventory_manager.gd`): 16-slot grid backpack, consumable catalog (Mohinga, Shan Noodles, Laphet Yay, Sparks Energy Drink, Herbal Balm, Thanaka, Kun-ya), stacking, and needs integration.
- `HousingManager` (`scripts/housing/housing_manager.gd`): 5 housing tiers (Park Bench, Hostel Bunk, Shophouse Room, Modern Apartment, Heritage Shophouse), rent payments, eviction safety net, and rest/sleep restoration.
- Career runners: `DeliveryRunner`, `StreetVendorRunner`, `TaxiShiftRunner`.

### M4 — Living City NPCs, Road Traffic & Weather Dynamics: DONE (100%)
- `NPCPedestrian` (`scripts/npcs/npc_pedestrian.gd` & `scenes/npcs/npc_pedestrian.tscn`): Schedule-driven ambient NPCs with 3-tier distance LOD (Full Kinematic 3D -> Waypoint step -> Offscreen timetable) and Burmese greetings.
- `TrafficCar` (`scripts/vehicles/traffic_car.gd` & `scenes/vehicles/traffic_car.tscn`): Automated red YBS City Bus with forward obstacle RayCast3D and tire traction modulation.
- `WeatherController` (`scripts/simulation/weather_controller.gd` & `scenes/world/weather_environment.tscn`): Dynamic 24-hour celestial sun arc, lighting transitions, and WebGL2-safe `CPUParticles3D` monsoon rain.

### M5 — Full UI Suite, Phone Apps & Web Play Readiness: DONE (100%)
- `PhoneController` (`scripts/ui/phone_controller.gd` & `scenes/ui/phone_menu.tscn`): Burmese smartphone personal organizer (`P` key) with KBZPay Banking, Jobs board, GPS Map POIs, and Life Status apps.
- `InventoryMenuController` (`scripts/ui/inventory_menu_controller.gd` & `scenes/ui/inventory_menu.tscn`): 16-slot grid backpack screen (`I` key) with item detail cards and consumption triggers.
- `StartScreenController` (`scripts/ui/start_screen_controller.gd` & `scenes/ui/start_screen.tscn`): Full-screen Click-to-Play overlay unlocking WebAudio and capturing mouse pointer.
- `PauseMenuController` (`scripts/ui/pause_menu_controller.gd` & `scenes/ui/pause_menu.tscn`): Pause screen (`Escape`) with Save Game, Load Game, Restart Day, Volume, and Sensitivity settings.

### M6 — WebSocket Multiplayer Prototype (4–8 Players): DONE (100%)
- `NetworkManager` (`scripts/networking/network_manager.gd`): `WebSocketMultiplayerPeer` client/server networking running on port 8910 at 20 Hz tick rate.
- Server-authoritative economy: Zero client trust for MMK balance, purchases, and wage deposits.
- `RemotePlayer` (`scripts/networking/remote_player.gd` & `scenes/player/remote_player.tscn`): Multiplayer puppet with cubic Hermite transform interpolation and billboard name/balance label.
- Dedicated Headless Server (`server/server_main.gd` & `server/server.tscn`): Standalone server process with heartbeat logging and transaction auditing.

### M7 — Polish, Audio, Performance & Production Release: DONE (100%)
- `AudioManager` (`scripts/systems/audio_manager.gd`): Zero-dependency procedural 16-bit PCM sound synthesis for WebGL2 and Desktop (UI clicks, MMK coin chimes, footsteps, ambient city murmur, and rain hiss).
- Street aesthetics: roadside plastic tea shop stools (red & blue), YBS bus stop shelter with bench and signage, utility poles with power cable supports.
- WebGL2 budget: 59 draw meshes (<150 limit), 28 physics bodies (<100 limit), lightweight vertex-lit shaders.
- Complete regression suite: 406/406 automated master tests passing with 0 failures (797 tests across all test suites).
- Standalone distributions:
  - Desktop: `build/desktop/YangonLife.exe` (109 MB) + `YangonLife.pck` (375 KB).
  - Web: `build/web/index.html` + `index.wasm` (39.5 MB) + `index.pck` (375 KB).

---

## 3. Automated Test Verification Summary
- `tests/run_tests.gd`: **406 PASSED, 0 FAILED** (100% pass rate across 20 suites)
- `tests/test_vehicles_and_m2.gd`: **152 PASSED, 0 FAILED**
- `tests/test_multiplayer.gd`: **72 PASSED, 0 FAILED**
- `tests/test_m4_living_city.gd`: **92 PASSED, 0 FAILED**
- `tests/test_m5_ui_suite.gd`: **75 PASSED, 0 FAILED**
- `tests/test_m7_polish_suite.gd`: **35 PASSED, 0 FAILED**
- **Grand Total: 797 automated tests passing with zero errors.**

---

## 4. Production Build Verification
- **Windows Desktop Standalone:** Verified executable build at `build/desktop/YangonLife.exe`.
- **WebGL2 Browser Build:** Verified export at `build/web/index.html` (39.5 MB wasm, under 50 MB budget).
- **Local Web Server:** `server/serve_web.js` verified with COOP (`same-origin`) and COEP (`require-corp`) headers.
- **Dedicated Multiplayer Server:** Headless execution verified via `server/server.tscn` on `ws://0.0.0.0:8910`.
