# Controls and UI/UX Specification — Yangon Frontline

## 1. Input Mapping & Control Schemes
| Action Name | Primary Input (PC / Desktop) | Browser Specifics |
|---|---|---|
| `move_forward` | `W` / Up Arrow | Native Keyboard Event |
| `move_backward` | `S` / Down Arrow | Native Keyboard Event |
| `move_left` | `A` / Left Arrow | Native Keyboard Event |
| `move_right` | `D` / Right Arrow | Native Keyboard Event |
| `jump` | `Space` | Handled to avoid browser page scrolling |
| `sprint` | `Shift` | Held down for boost |
| `fire` | `Left Mouse Button` | Requires active Pointer Lock |
| `aim_down_sights` | `Right Mouse Button` | Context menu prevented via web wrapper |
| `reload` | `R` | Reload current magazine |
| `pause` | `Escape` | Releases Pointer Lock, opens Pause Menu |
| `restart_mission` | `F5` / HUD Button | Instant scene reload |

---

## 2. Browser Pointer Capture Lifecycle
1. **Initial Screen:** An overlay modal prompts: *"Click anywhere to deploy & lock mouse"*.
2. **Click Event:** Calls `Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)`.
3. **Audio Unlock:** Concurrently triggers an empty audio sample playback to satisfy WebAudio auto-play policies.
4. **Pause Trigger:** Pressing `Escape` triggers Godot's pause screen and releases mouse to `MOUSE_MODE_VISIBLE`.

---

## 3. Heads-Up Display (HUD) Layout
```
+-------------------------------------------------------------+
| [FACTION: PDF]                             [OBJECTIVE: 3/5] |
|                                                             |
|                                                             |
|                              +                              |
|                         (Crosshair)                         |
|                                                             |
|                                                             |
| [HP: 100/100]                               [AMMO: 30 / 90] |
| [==================]                                        |
+-------------------------------------------------------------+
```
- **Crosshair:** Dynamic 4-line reticle expanding with movement and firing recoil.
- **Health Bar:** Smooth color transition from Green (`>60%`), Yellow (`30-60%`), to Flashing Red (`<30%`).
- **Ammo Counter:** Large magazine count alongside reserve pool. Shows flashing "RELOAD" when empty.
- **Directional Hit Indicators:** Red curved arcs around center screen pointing toward the attacker's azimuth.

---

## 4. Menu & Feedback Screens
- **Pause Menu:** Resume Game, Mouse Sensitivity Slider (0.05 to 1.0), Restart Mission, Return to Main Menu.
- **Victory Screen:** "SECTOR SECURED", final accuracy tally, hostiles eliminated, time elapsed.
- **Defeat Screen:** "K.I.A. (KILLED IN ACTION)", restart button (`F5`), death recap.
