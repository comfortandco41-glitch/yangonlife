# Testing Procedures and Verification Checklist — Yangon Frontline

## 1. Automated Headless Verification
Automated test scripts verify engine initialization, scene parsing, and component logic without requiring a display device.
```powershell
# Run the test runner headlessly
& "D:\Tools\Godot\godot.cmd" --headless --path "D:\Games\ygn frontier" -s tests/run_tests.gd
```

---

## 2. Milestone 1 Acceptance Verification Checklist
| Test ID | System Under Test | Test Procedure | Expected Result | Result |
|---|---|---|---|---|
| **TEST-01** | Scene Loading & Syntax | Launch main scene in headless mode | Exit code 0, no GDScript parse errors or missing dependencies | **PASSED** (Suite 4) |
| **TEST-02** | Player Movement & Input | Simulate WASD vector inputs and jump | Velocity changes along correct axes, gravity applies when ungrounded | **PASSED** (Suite 4) |
| **TEST-03** | Ground & Wall Collision | Place player on ground plane and into concrete barrier | Player rests at ground plane, cannot penetrate solid obstacles | **PASSED** (Suite 4) |
| **TEST-04** | Weapon Firing & Recoil | Invoke fire method with ammunition in magazine | Ammo decrements from 30 to 29, raycast checks intersection, recoil applied | **PASSED** (Suite 3) |
| **TEST-05** | Hitbox & Damage Resolution | Raycast hit on character HitboxComponent with 25 damage | Target health drops from 100 to 75, damage signal fires | **PASSED** (Suite 2) |
| **TEST-06** | Friendly Fire Filtering | Shoot ally HitboxComponent on same team | Target health remains 100, damage rejected | **PASSED** (Suite 2) |
| **TEST-07** | AI State Transition | Spawn hostile AI in scene | AI initializes in IDLE, scans for target in FOV | **PASSED** (Suite 5) |
| **TEST-08** | AI Elimination & Death | Deal 100+ damage to AI soldier | AI transitions to `DEAD`, collision disabled, mission kill counter increments | **PASSED** (Suite 5 & 6) |
| **TEST-09** | HUD & Restart Loop | Trigger enemy eliminations -> check victory panel | Mission completes, victory panel displayed, restart flow operational | **PASSED** (Suite 6) |
| **TEST-10** | Offline Independence | Run game without network socket or server connection | Complete single-player game loop executes smoothly offline | **PASSED** |
| **TEST-11** | WebGL Browser Export | Export project to HTML5 Web preset | `index.html`, `index.js`, `index.wasm`, `index.pck` generated and served with COOP/COEP | **PASSED** |
| **TEST-12** | Desktop Export | Export project to Windows Desktop preset | Standalone `YangonFrontline.exe` and `YangonFrontline.pck` generated | **PASSED** |

---

## 3. Test Execution Summary (2026-10-19)
- **Total automated assertions:** 39
- **Passed:** 39
- **Failed:** 0
- **Exit Code:** 0
