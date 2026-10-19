# Project State — Yangon Frontline

**Last Updated:** 2026-10-19  
**Current Milestone:** M1 — Offline FPS Prototype (**DONE & VERIFIED**)  
**Status:** READY FOR M2  

---

## 1. Milestone Tracking
- **M0 — Repository & Architecture:** DONE (100%)
  - Engine setup: Godot 4.7.2 self-contained on Drive D: (`D:\Tools\Godot`).
  - Export templates: Full templates suite installed in `D:\Tools\Godot\editor_data\export_templates\4.7.2.stable\`.
  - Storage policy: 100% of tools, temp files, and builds isolated to Drive D:.
  - Architecture documents: All 14 `/docs` files, `AGENTS.md`, and `README.md` active.
- **M1 — Offline FPS Prototype:** DONE (100%)
  - Player controller: WASD, sprint, jump, mouse-look, ADS zoom, weapon bob, ground collision.
  - Combat / Raycast weapon: MA-1 Vanguard assault rifle with raycast hit resolution, recoil, reload, muzzle flash, bullet tracer.
  - Combat components: `HealthComponent` and `HitboxComponent` with friendly-fire filtering.
  - Hostile AI: `AISoldier` with FSM (`IDLE`, `PATROL`, `CHASE`, `ATTACK`, `DEAD`), 90° FOV sight cone, burst shooting, collapse animation.
  - Environment: Low-poly downtown Yangon arena (asphalt roadway, road dividers, raised sidewalks, colonial building facades, red city bus cover, Jersey barricades, sandbag bunkers, boundary walls).
  - HUD & Restart: In-game HUD (health, ammo, crosshair, objective counter, damage flash, victory & defeat dialogs, restart via `F5` / button).
  - Automated tests: 39/39 unit & integration tests passing (`exit code 0`).
  - Web export: Verified WebGL2/WASM build (`build/web/index.html`) served with Node.js.
  - Desktop export: Verified Windows x86_64 standalone executable (`build/desktop/YangonFrontline.exe`).

---

## 2. Working Features
- Complete single-player offline game loop in `res://scenes/main/main_game.tscn`.
- Full standalone executable playable on Windows desktop without dependencies.
- Full WebGL browser export compatible with Chrome, Edge, and Firefox.
- Headless automated verification runner (`tests/run_tests.gd`).
- Zero-cost, self-contained architecture strictly on Drive D:.

---

## 3. Latest Test Results
- **Automated Headless Test Runner:**
  - 39 passed, 0 failed.
  - Exit code: 0.
- **Export Verification:**
  - Web export: `build/web/` (`index.html`, `index.js`, `index.pck`, `index.wasm`).
  - Desktop export: `build/desktop/` (`YangonFrontline.exe`, `YangonFrontline.pck`).
  - Web server test: HTTP 200 with `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.

---

## 4. Current Blockers
- None.

---

## 5. Next Recommended Task
- **M2 Milestone — Yangon Urban Environment Expansion:**
  - Add modular colonial architectural components (wooden shutter louvers, ornate verandas, shophouse awnings).
  - Add roadside tea shop props (Burmese tea tables, red/blue plastic stools, teapot props).
  - Bake static `NavigationRegion3D` navigation mesh for dynamic AI pathfinding across complex alleyways.
