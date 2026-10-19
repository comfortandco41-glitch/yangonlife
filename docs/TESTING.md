# Testing Procedures & Verification Guide — Yangon Life

**Project:** Yangon Life  
**Document Version:** 2.0.0  
**Last Updated:** 2026-10-19  
**Status:** Active QA Specification  

---

## 1. Overview & Automated Test Runner

Testing in **Yangon Life** is divided into two primary disciplines:
1. **Automated Headless Testing:** Executes deterministic unit tests, state machine transitions, economy arithmetic, save/load serialization, and scene parsing without requiring a display device or GPU window.
2. **Interactive & Manual QA Checklist:** Verifies player locomotion, spring arm camera orbital physics, interactive UI panels, browser WebGL rendering, and audio contexts.

### 1.1 Headless Test Command
Automated tests are executed using the self-contained Godot CLI located on **Drive D:**:

```powershell
& "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" -s tests/run_tests.gd
```

### 1.2 Automated Runner Architecture (`tests/run_tests.gd`)
```gdscript
extends SceneTree

func _init() -> void:
    print("=== Yangon Life Automated Test Suite ===")
    var suite := TestRunner.new()
    var exit_code: int = suite.run_all()
    quit(exit_code)
```

The test runner returns `exit code 0` on complete success, or a non-zero code on failure, facilitating automated CI/CD and git hook verification.

---

## 2. Test Verification Matrix by Category

The following tables define the formal verification suite for Yangon Life. Each test includes an identifier, test procedure, expected result, and current verification status.

---

### Category 1: Startup & Initialization (`STARTUP`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **START-01** | Scene Loading | Load `res://scenes/main/main_game.tscn` headlessly via CLI | Scene root instantiates without parse errors, script errors, or broken dependencies | **READY** |
| **START-02** | Autoload Registration | Query `GameManager`, `EconomyManager`, `NeedsManager`, `TimeManager`, `SaveManager`, `CareerManager`, `InteractionManager` | All 7 singletons are present in the scene tree root with valid references | **READY** |
| **START-03** | Display & Viewport Setup | Inspect viewport dimensions and stretch mode | Window defaults to 1280x720, `canvas_items` mode, `keep` aspect ratio | **READY** |
| **START-04** | Input Map Configuration | Call `GameManager._register_input_actions()` and check `InputMap` | Actions registered: `move_forward`, `move_backward`, `move_left`, `move_right`, `sprint`, `jump`, `interact`, `inventory`, `map`, `phone`, `pause`, `enter_vehicle` | **READY** |

---

### Category 2: Character Movement & Camera (`MOVE`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **MOVE-01** | Locomotion WASD | Inject directional input vectors into `CharacterBody3D` | Velocity accelerates smoothly in the forward/lateral direction relative to camera facing | **READY** |
| **MOVE-02** | Sprint Multiplier | Hold `Shift` (`sprint`) during forward movement | Character movement speed increases from base walk speed (3.5 m/s) to sprint speed (6.5 m/s) | **READY** |
| **MOVE-03** | Jump & Gravity | Press `Space` (`jump`) when grounded; release on peak | Character acquires upward impulse, transitions to falling state, gravity pulls character down to floor | **READY** |
| **MOVE-04** | Spring Arm Camera Orbit | Send relative mouse motion with right-mouse button held | SpringArm3D pivots yaw (360°) and pitch (-70° to +30°); camera does not invert or roll | **READY** |
| **MOVE-05** | Camera Occlusion Collision | Back player against colonial wall geometry | SpringArm3D raycast detects wall collision and smoothly retracts camera distance to prevent clipping through interior walls | **READY** |
| **MOVE-06** | World Boundary Collision | Walk character directly into concrete buildings and boundary fences | Character slides along collision normals; cannot penetrate or clip into solid world geometry | **READY** |

---

### Category 3: Interaction System (`INTERACT`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **INT-01** | Range Detection | Approach an interactable shop counter or tea stall within 2.5m | `InteractionManager` detects focus, highlights object, and displays `"Press [E] to Interact"` HUD prompt | **READY** |
| **INT-02** | Interaction Trigger | Press `E` (`interact`) while within range of a street stall | Interaction event fires; shop purchase UI modal opens; player locomotion pauses | **READY** |
| **INT-03** | Out of Range Deactivation | Walk away (> 3.5m) from interactable target | Interaction prompt vanishes; active interaction target resets to null | **READY** |
| **INT-04** | Modal Dismissal | Press `ESC` or click close button while shop UI is open | Shop dialog closes smoothly; mouse capture and character movement resume | **READY** |

---

### Category 4: Driving & Transportation (`DRIVE`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **DRV-01** | Vehicle Entry | Approach taxi/vehicle and press `F` (`enter_vehicle`) | Character model hides/attaches to driver seat; camera switches to vehicle follow mode; vehicle controls activate | **READY** |
| **DRV-02** | Steering & Acceleration | Press `W` (accelerate), `S` (brake/reverse), `A`/`D` (steer) | Vehicle accelerates along forward vector, wheels turn, speed caps at vehicle top speed (50 km/h in city) | **READY** |
| **DRV-03** | Vehicle Collision | Drive vehicle into road barricade or curb | Vehicle stops on collision with physics response; does not penetrate curb or launch into sky | **READY** |
| **DRV-04** | Vehicle Exit | Bring vehicle to stop and press `F` | Player character spawns adjacent to driver's side door on sidewalk; camera returns to third-person orbital rig | **READY** |

---

### Category 5: Career System (`CAREER`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **CAR-01** | Job Application | Approach career center / business and select career (e.g. Shopkeeper) | Player career status changes from `UNEMPLOYED` to selected career; level initializes at 1 | **READY** |
| **CAR-02** | Work Shift Initiation | Clock in at designated work station during shift hours | Active shift timer starts; shift objective UI displays current tasks | **READY** |
| **CAR-03** | Task Execution | Complete career mini-tasks (e.g., serving tea, restocking shelves, taxi fare delivery) | Task progress counter updates; performance rating increments | **READY** |
| **CAR-04** | Shift Completion & Wages | Complete shift duration or quota and clock out | Career shift calculates base salary + tips; calls `EconomyManager.add_money()` with payout in MMK | **READY** |

---

### Category 6: Economy System (`ECONOMY`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **ECON-01** | Starting Balance | Initialize game with fresh state | `EconomyManager.get_balance()` returns exactly 50,000 MMK | **READY** |
| **ECON-02** | Valid Purchase Deduction | Purchase Mohinga bowl costing 2,500 MMK with 50,000 MMK balance | `spend_money(2500, "purchase")` returns `true`; balance becomes 47,500 MMK; `money_changed` signal emits | **READY** |
| **ECON-03** | Overdraft Prevention | Attempt to purchase a 100,000 MMK luxury watch with 47,500 MMK balance | `spend_money(100000, "purchase")` returns `false`; balance remains 47,500 MMK; error signal emitted | **READY** |
| **ECON-04** | Career Wage Credit | Complete delivery wage payout of 15,000 MMK | `add_money(15000, "wage")` increments balance to 62,500 MMK; `transaction_completed` signal emits | **READY** |
| **ECON-05** | Negative Input Guard | Call `add_money(-500)` or `spend_money(-500)` | Transaction is rejected; balance remains unchanged; no negative exploits possible | **READY** |

---

### Category 7: Save & Load System (`SAVE`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **SAVE-01** | State Capture | Call `SaveManager.save_game(1)` with modified balance, position, and needs | Generates valid JSON payload containing timestamp, version number, player coords, wallet balance, and stats | **READY** |
| **SAVE-02** | State Restoration | Alter current runtime balance to 0, then call `SaveManager.load_game(1)` | Runtime balance, player position, needs, and career level restore exactly to saved values | **READY** |
| **SAVE-03** | Schema Version Handling | Feed save file with older or future version number | Save manager detects schema mismatch, applies data migration logic or returns graceful fallback without crashing | **READY** |
| **SAVE-04** | Corrupt File Recovery | Provide malformed JSON file to `load_game()` | System catches parse error, logs warning, and initializes safe default state rather than crashing | **READY** |

---

### Category 8: Non-Player Characters (`NPC`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **NPC-01** | Ambient Spawner | Spawn downtown city scene | Pedestrian NPCs populate sidewalks and tea shop stools within active streaming radius | **READY** |
| **NPC-02** | Waypoint Navigation | Observe ambient pedestrian over 30 seconds | NPC follows sidewalk waypoints, avoids roadside obstacles, and obeys traffic crossing signals | **READY** |
| **NPC-03** | LOD Behavior (Distance) | Move player > 40m away from NPC | NPC disables complex facial mesh and raycasts; switches to low-frequency kinematic updates (LOD 2) | **READY** |
| **NPC-04** | Vendor Interaction | Interact with stationary vendor NPC | NPC turns head toward player, triggers voice/greeting text, and exposes trade inventory | **READY** |

---

### Category 9: Yangon Map & OpenStreetMap Integration (`MAP`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **MAP-01** | Geographic Accuracy | Inspect coordinate origin (0,0,0) in downtown scene | Origin matches Sule Pagoda roundabout; street layout corresponds to Sule Pagoda Rd, Maha Bandula Rd, and Anawrahta Rd | **READY** |
| **MAP-02** | Static Mesh Collision | Walk along sidewalks, curbs, veranda steps, and gutters | Collision mesh accurately matches visual geometry; player does not trip or get snagged on step edges | **READY** |
| **MAP-03** | Yangon Street Dressing | Inspect urban props in downtown slice | Colonial shophouses, roadside tea tables, red/blue plastic stools, betel stalls, and bus stops render with proper materials | **READY** |

---

### Category 10: Browser & WebGL2 Compatibility (`BROWSER`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **BROW-01** | WebGL2 Initialization | Load exported build in Chrome, Edge, and Firefox | WebGL2 canvas initializes, engine shaders compile with zero errors in browser developer console | **READY** |
| **BROW-02** | Pointer Lock / Mouse Capture | Click anywhere on the game canvas in browser | Browser grants pointer lock; mouse cursor hides; orbital camera rotates smoothly | **READY** |
| **BROW-03** | WebAudio Context Unlock | Launch game and click to start | WebAudio context transitions from suspended to active without browser audio warnings | **READY** |
| **BROW-04** | Canvas Resizing | Resize browser window dynamically | Viewport scales dynamically adhering to aspect ratio constraints without black screens or stretching | **READY** |

---

### Category 11: Multiplayer Synchronization (`MULTIPLAYER`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **NET-01** | WebSocket Handshake | Connect desktop client and browser client to local server (`127.0.0.1:8080`) | Both clients establish WebSocket connection, receive unique PeerIDs, and spawn remote player avatars | **READY** |
| **NET-02** | Position Interpolation (20Hz) | Move Client A forward across Maha Bandula Park | Client B sees Client A move smoothly with cubic interpolation; latency jitter buffer suppresses jitter | **READY** |
| **NET-03** | Server Wallet Authority | Client A requests item purchase | Server validates transaction and balance; Client A receives confirmed balance; Client B sees Client A hold new item | **READY** |
| **NET-04** | Graceful Disconnect | Client A closes connection | Server logs disconnect, flushes save state to database, broadcasts despawn event to Client B | **READY** |
| **NET-05** | Reconnect Window | Drop Client A network connection for 30s, then reconnect | Server re-associates existing character state within the 120-second grace window without resetting progress | **READY** |

---

### Category 12: Regression Suite (`REGRESSION`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **REG-01** | Clean Engine Exit | Launch and quit project headlessly | Godot engine exits with code 0 without orphaned memory leaks or unfreed nodes | **READY** |
| **REG-02** | Scene Dependency Integrity | Scan all `.tscn` scenes in `res://scenes/` | Zero broken resource paths (`ext_resource`), missing scripts, or invalid UID references | **READY** |
| **REG-03** | Deprecated Combat Cleanup | Verify all old FPS combat references removed from active scenes | No weapon scripts, soldier AI, or gun raycasts attached to Yangon Life active scenes | **READY** |

---

### Category 13: Performance Benchmarks (`PERFORMANCE`)

| Test ID | System / Target | Test Procedure | Expected Result | Status |
|---|---|---|---|---|
| **PERF-01** | Desktop Framerate | Run downtown city scene with 50 NPCs on standard PC | Sustained framerate >= 60 FPS at 1080p | **READY** |
| **PERF-02** | WebGL Framerate | Run downtown city scene in Google Chrome / Firefox | Sustained framerate >= 30 FPS (target 60 FPS on dedicated GPU) | **READY** |
| **PERF-03** | Draw Call Budget | Profile rendered frames via Godot Monitor | Total draw calls per frame remain under 120 (optimized for mobile/web compatibility) | **READY** |
| **PERF-04** | Memory Footprint | Profile RAM usage over 15 minutes of gameplay | Total memory consumption remains below 500 MB (suitable for low-spec browser tabs) | **READY** |

---

## 3. Pre-Release Acceptance Checklist

Before tagging any version release:
1. [ ] Automated test runner passes: `& "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" -s tests/run_tests.gd` (`Exit code: 0`).
2. [ ] Windows Desktop build exported and launches without missing DLLs or dependencies.
3. [ ] Web build exported, served via `node server/serve_web.js`, and tested in Chrome & Firefox.
4. [ ] In-game economy balance matches starting amount (50,000 MMK) and transaction validations succeed.
5. [ ] Third-person camera collision prevents geometry clipping.
6. [ ] Save/load cycle verified with persistent JSON state.
