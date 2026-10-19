# Architecture Decision Records (ADR) — Yangon Frontline

## ADR-001: Engine Selection — Godot Engine 4.7
- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Problem:** Select a game engine capable of desktop performance, lightweight browser export (WebGL2/WebAssembly), GDScript rapid iteration, and zero subscription costs.
- **Options Considered:**
  1. *Godot Engine 4.x:* Open-source (MIT), lightweight, built-in WebGL export, no runtime fees, native headless testing support.
  2. *Unity:* Large ecosystem, but heavier WebGL runtime, complex licensing, and slower cold-start times.
  3. *Custom Three.js / WebGL engine:* Ideal for browser, but significantly higher engineering overhead for native desktop, 3D physics, and scene tooling.
- **Decision:** Use Godot Engine 4.7.2.
- **Reasoning:** Meets all requirements across desktop, web export, and headless automated testing, with a clean MIT license.
- **Consequences:** GDScript becomes the primary codebase language; project structure conforms to Godot node/scene hierarchy.

---

## ADR-002: Rendering Backend Selection — Compatibility (`gl_compatibility`)
- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Problem:** Godot 4 offers Forward+, Mobile (Vulkan), and Compatibility (OpenGL ES 3.0 / WebGL2). Browser deployment is a primary project pillar.
- **Options Considered:**
  1. *Forward+ (Vulkan):* Highest fidelity, but completely unsupported in web browsers.
  2. *Mobile (Vulkan):* Android/iOS optimized, but experimental/unsupported on WebGL2.
  3. *Compatibility (OpenGL ES 3.0 / WebGL2):* Runs seamlessly across Windows desktop and all modern desktop web browsers (Chrome, Edge, Firefox).
- **Decision:** Mandate `gl_compatibility` as the engine renderer.
- **Reasoning:** Guarantees that scenes, shaders, and materials created for desktop run reliably in the browser without dual-codebase divergence.
- **Consequences:** Advanced Vulkan-only post-processing (SDFGI, volumetric fog) cannot be used. Visual direction must lean into clean stylized low-poly aesthetics and baked lighting.

---

## ADR-003: Storage Policy — Dedicated Drive D: Environment
- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Problem:** System storage on Drive C: must be preserved without accumulation of large game engine binaries, caches, or export templates.
- **Decision:** Place all engine executables, project workspaces, self-contained data folders (`_sc_`), export templates, and temp builds on Drive D: (`D:\Tools\Godot`, `D:\Games\ygn frontier`).
- **Consequences:** Godot runs in self-contained mode, reading export templates from `D:\Tools\Godot\editor_data\export_templates\`. Zero disk overhead on Drive C:.

---

## ADR-004: Authoritative Simulation & Decoupled Architecture
- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Problem:** Game must support both completely standalone offline single-player and server-authoritative online multiplayer without duplicating combat, movement, or damage logic.
- **Decision:** Decouple character simulation into modular components (`PlayerController`, `HealthComponent`, `WeaponManager`, `HitboxComponent`). The networking layer acts as an authoritative replication wrapper over these components rather than tightly coupling network RPCs into core physics.
- **Consequences:** Offline mode operates with zero network overhead. Online mode synchronizes state through high-level authoritative managers.
