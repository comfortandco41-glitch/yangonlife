# Architecture Decision Records (ADRs) — Yangon Life

**Project:** Yangon Life  
**Document Version:** 2.0.0  
**Last Updated:** 2026-10-19  
**Status:** Living Architectural Record  

This document logs all foundational architectural and design decisions made for **Yangon Life**, including historical decisions inherited from the initial prototype and pivotal decisions driving the life simulation transformation.

---

## Index of Decisions
- [ADR-001: Engine Selection — Godot Engine 4.7.2](#adr-001-engine-selection--godot-engine-472)
- [ADR-002: Renderer Selection — Compatibility (`gl_compatibility`)](#adr-002-renderer-selection--compatibility-gl_compatibility)
- [ADR-003: Storage Policy — Dedicated Drive D: Isolation](#adr-003-storage-policy--dedicated-drive-d-isolation)
- [ADR-004: Game Direction Pivot — Life Simulation Replaces FPS](#adr-004-game-direction-pivot--life-simulation-replaces-fps)
- [ADR-005: Map Data Source — OpenStreetMap (ODbL)](#adr-005-map-data-source--openstreetmap-odbl)
- [ADR-006: Coordinate System — Local Metric Grid Centered on Sule Pagoda](#adr-006-coordinate-system--local-metric-grid-centered-on-sule-pagoda)
- [ADR-007: Currency Standard — Myanmar Kyat (MMK)](#adr-007-currency-standard--myanmar-kyat-mmk)
- [ADR-008: Camera Rig — Spring Arm Orbital Third-Person Camera](#adr-008-camera-rig--spring-arm-orbital-third-person-camera)
- [ADR-009: Save State Format — Versioned JSON Serialization](#adr-009-save-state-format--versioned-json-serialization)
- [ADR-010: NPC LOD System — Distance-Based Behavioral Complexity](#adr-010-npc-lod-system--distance-based-behavioral-complexity)

---

## ADR-001: Engine Selection — Godot Engine 4.7.2

- **Date:** 2026-10-19
- **Status:** ACCEPTED (Retained)
- **Context:** The project requires a performant 3D game engine capable of desktop delivery, lightweight browser export (WebGL2/WebAssembly), fast GDScript iteration, headless automated testing, and zero licensing fees.
- **Options Considered:**
  1. *Godot Engine 4.7.2:* Open-source (MIT), lightweight (~100MB self-contained executable), native WebGL export, built-in headless CLI testing, no runtime fees.
  2. *Unity Engine:* Extensive asset store, but heavy WebGL runtime (slow loading times), telemetry bloat, and restrictive runtime fee policies.
  3. *Unreal Engine 5:* Exceptional visual fidelity, but massive binary footprint, zero viable web browser export target, and unsuitable for low-spec hardware.
- **Decision:** Use Godot Engine 4.7.2.
- **Consequences:**
  - Fast iteration with statically typed GDScript 2.0.
  - Seamless compilation to Windows desktop and WebAssembly.
  - Complete engine self-containment on Drive D:.

---

## ADR-002: Renderer Selection — Compatibility (`gl_compatibility`)

- **Date:** 2026-10-19
- **Status:** ACCEPTED (Retained)
- **Context:** Godot 4 offers three rendering pipelines: Forward+ (Vulkan), Mobile (Vulkan/Vulkan Mobile), and Compatibility (OpenGL ES 3.0 / WebGL2). The project mandates cross-platform playability in standard desktop web browsers (Chrome, Edge, Firefox) alongside desktop executables.
- **Options Considered:**
  1. *Forward+ (Vulkan):* High-end desktop visual features (volumetric fog, SDFGI), but completely inoperable in HTML5/WebGL browsers.
  2. *Mobile (Vulkan):* Android/iOS targeting, but incompatible with WebGL2 web export.
  3. *Compatibility (`gl_compatibility`):* Compiles to OpenGL ES 3.0 on desktop and WebGL2 in web browsers, sharing 100% of materials and shaders.
- **Decision:** Mandate `gl_compatibility` as the universal renderer across desktop and web export presets.
- **Consequences:**
  - Desktop and browser builds use identical shaders and visual assets without divergence.
  - Advanced Vulkan-only post-processing is unavailable. Art direction relies on clean low-poly models, baked lighting, stylized vertex colors, and atmospheric ambient illumination.

---

## ADR-003: Storage Policy — Dedicated Drive D: Isolation

- **Date:** 2026-10-19
- **Status:** ACCEPTED (Retained)
- **Context:** User environment requires strict preservation of storage on system Drive C:. Game engine binaries, export templates, development caches, and build packages must not touch Drive C:.
- **Options Considered:**
  1. *Default Windows AppData (`C:\Users\...`):* Accumulates gigabytes of editor templates and caches on Drive C:.
  2. *Strict Drive D: Isolation:* Godot runs in self-contained mode (`_sc_` marker file in `D:\Tools\Godot\`), storing all templates, logs, and cache on Drive D:. Project code and builds reside in `D:\Games\ygn frontier\`.
- **Decision:** Enforce 100% isolation on Drive D:.
- **Consequences:**
  - Zero storage impact on Drive C:.
  - Portable, self-contained development ecosystem that can be moved or backed up cleanly.

---

## ADR-004: Game Direction Pivot — Life Simulation Replaces FPS

- **Date:** 2026-10-19
- **Status:** ACCEPTED (Pivotal Change)
- **Context:** Following completion of the Milestone 1 combat prototype ("Yangon Frontline"), the user decided on a complete creative and architectural pivot from a tactical urban shooter to an open-world low-poly life simulation ("Yangon Life").
- **Options Considered:**
  1. *Continue Tactical FPS:* Urban combat skirmishes between fictional factions. High operational complexity, content saturation in shooter genre, limited cultural depth.
  2. *Pivot to Open-World Life Simulation:* Non-violent, highly immersive social simulation celebrating Yangon's cultural identity (street teashops, delivery careers, taxi driving, housing progression, authentic economy, shopkeeping). Broad accessibility and appealing sandbox gameplay.
- **Decision:** Perform a complete project pivot to **Yangon Life**. Archive all military combat, firearm raycasts, and soldier AI systems. Rebuild the core loop around character needs, economic transactions, careers, vehicle transportation, and urban social simulation.
- **Consequences:**
  - Previous FPS code safely archived to `archive/fps_prototype/`.
  - Elimination of weapon mechanics, muzzle flashes, and combat damage pipelines.
  - Introduction of needs systems (hunger, energy, hygiene, stress), career progression, interaction systems, and vehicle physics.

---

## ADR-005: Map Data Source — OpenStreetMap (ODbL)

- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Context:** Creating an accurate, recognizable downtown Yangon urban layout requires real-world GIS and road network data. The data source must legally permit distribution within a game binary.
- **Options Considered:**
  1. *Google Maps Platform / Google Earth:* Highly detailed 3D photogrammetry, but Google Maps Terms of Service explicitly prohibit downloading, caching, extracting 3D geometry, or redistributing map assets inside commercial or offline software.
  2. *OpenStreetMap (OSM):* Open-source community GIS database licensed under the Open Database License (ODbL). Allows derivative works, 3D mesh generation, and commercial distribution with proper attribution.
  3. *Completely Fictional Procedural Layout:* Zero legal risk, but fails to capture the cultural authenticity of Yangon's iconic downtown colonial grid, Sule Pagoda roundabout, and Maha Bandula Park.
- **Decision:** Use **OpenStreetMap (OSM)** as the foundational geographic data source.
- **Consequences:**
  - Exported building footprints, road vectors, and park boundaries from OSM are processed into low-poly 3D meshes.
  - License compliance: Full attribution to OpenStreetMap contributors included in game credits and documentation.
  - Google Maps legal restrictions and API fee liabilities are completely eliminated.

---

## ADR-006: Coordinate System — Local Metric Grid Centered on Sule Pagoda

- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Context:** Geographic GIS coordinates are represented in spherical latitude/longitude (EPSG:4326 - WGS 84). Game physics engines operate on Cartesian metric grids (X, Y, Z in meters) centered around origin `(0, 0, 0)`. Large coordinate offsets cause single-precision floating-point rendering jitter.
- **Options Considered:**
  1. *Raw UTM Coordinates:* Preserves global coordinates, but numbers in the millions cause vertex jitter and collision inaccuracy in 32-bit floats.
  2. *Local Metric Offset Centered on Sule Pagoda:* Convert GPS coordinates to meters via transverse Mercator projection, setting Sule Pagoda (16.7745° N, 96.1587° E) as World Origin `Vector3(0, 0, 0)`.
- **Decision:** Set Sule Pagoda roundabout as the local `(0, 0, 0)` reference origin.
- **Consequences:**
  - +X axis aligns with True East (toward Pansodan & Thetford streets).
  - +Z axis aligns with True South (toward Strand Road and Yangon River).
  - -Z axis aligns with True North (toward Anawrahta Rd, Bogyoke Rd, and Shwedagon).
  - +Y axis represents vertical elevation in meters above street level.
  - All downtown locations reside within a compact 1,500m radius of origin, guaranteeing millimeter floating-point precision.

---

## ADR-007: Currency Standard — Myanmar Kyat (MMK)

- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Context:** The life simulation requires an in-game currency for purchasing street food, paying taxi fares, renting apartments, and receiving career salaries.
- **Options Considered:**
  1. *Generic "Gold" or "Credits":* Typical game abstraction, but destroys cultural authenticity and immersion.
  2. *US Dollars (USD):* Unrealistic for local daily street commerce in Yangon.
  3. *Myanmar Kyat (MMK):* Authentic national currency of Myanmar.
- **Decision:** Standardize on **Myanmar Kyat (MMK)** using integer values (e.g., 500 MMK, 2,500 MMK, 50,000 MMK).
- **Consequences:**
  - All prices reflect realistic Yangon price tiers (e.g., Mohinga bowl: 2,000–3,000 MMK, bus ride: 500 MMK, starter daily rent: 15,000 MMK).
  - Starting player balance initialized to **50,000 MMK** (adequate for starting food and transit).
  - Stored strictly as 64-bit integer values (`int`) to avoid floating-point rounding errors in transactions.

---

## ADR-008: Character Perspective & Camera — Spring Arm Orbital Third-Person Camera

- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Context:** The previous prototype used a first-person shooter camera attached directly to player eye height. Life simulation games demand strong character presence, situational awareness, and visibility of clothing and customization.
- **Options Considered:**
  1. *First-Person Perspective:* High personal immersion, but poor spatial awareness in busy markets, hides player clothing/character customization, and makes driving vehicles awkward.
  2. *Fixed Isometric / Top-Down Camera:* Good overview, but loses the immersive street-level grandeur of colonial Yangon architecture and golden pagodas.
  3. *Orbital Third-Person Camera with SpringArm3D:* Camera orbits behind player character with collision raycasts to prevent clipping into walls, adjustable zoom distance, and smooth pitch/yaw control.
- **Decision:** Implement a **SpringArm3D orbital third-person camera**.
- **Consequences:**
  - Players can inspect their avatar, clothing, and custom accessories.
  - Smooth navigation through bustling sidewalks, crowded tea stalls, and interiors.
  - Seamless transition between on-foot locomotion and vehicle driving cameras.

---

## ADR-009: Save State Format — Versioned JSON Serialization

- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Context:** Single-player game state (wallet balance, career levels, inventory, needs, player location) must be persisted reliably on both Windows desktop filesystems and browser Web storage (`IndexedDB` / `localStorage`).
- **Options Considered:**
  1. *Binary Serialization (Godot `var_to_bytes` / `.res`):* Compact, but opaque, difficult to inspect or repair, and vulnerable to deserialization breaks across engine versions.
  2. *SQLite Database on Client:* Powerful relational queries, but heavy overhead for browser WebAssembly builds.
  3. *Versioned JSON Dictionary:* Human-readable, structured, easily validated against schemas, supported natively across GDScript and Web APIs, and straightforward to migrate between versions.
- **Decision:** Use **Versioned JSON Serialization** for client save files.
- **Format Structure:**
  ```json
  {
    "version": 2,
    "timestamp": 1774004400,
    "player": {
      "name": "Thura",
      "position": [14.2, 0.0, -32.8],
      "rotation_y": 1.57
    },
    "economy": {
      "balance": 52500
    },
    "needs": {
      "hunger": 82.0,
      "energy": 90.0,
      "hygiene": 75.0,
      "stress": 12.0
    },
    "career": {
      "current_job": "taxi_driver",
      "level": 2,
      "reputation": 45
    }
  }
  ```
- **Consequences:**
  - Save files are easily inspected and debugged during development.
  - The `version` integer enables automated data migrations when new systems are introduced.

---

## ADR-010: NPC LOD System — Distance-Based Behavioral Complexity

- **Date:** 2026-10-19
- **Status:** ACCEPTED
- **Context:** An authentic Yangon streetscape requires 50–100 simultaneous pedestrian NPCs and vehicles (monks in saffron robes, office workers, trishaw drivers, roadside vendors). Simulating high-frequency AI, pathfinding, and skeletal animations for all NPCs simultaneously would severely degrade performance in browser WebGL environments.
- **Options Considered:**
  1. *Full Simulation for All NPCs:* Full physics and 60 Hz AI processing for all entities. Causes severe frame drops (< 20 FPS) in browser tabs.
  2. *Aggressive Despawning:* Spawning NPCs only within 15 meters of the player. Causes jarring pop-in and depopulates the city skyline.
  3. *Three-Tier Distance-Based LOD System:*
     - **LOD 0 (0m – 15m):** Full mesh, facial details, skeletal animations, continuous collision, active greeting raycasts.
     - **LOD 1 (15m – 45m):** Simplified mesh, reduced animation tick rate (15 Hz), simplified collision box, waypoint navigation.
     - **LOD 2 (45m – 90m):** Billboard or ultra-low poly proxy, no physics raycasts, 2 Hz linear interpolation along designated road spline.
     - **Beyond 90m:** Despawned or pooled into background statistical density simulator.
- **Decision:** Implement the **Three-Tier Distance-Based NPC LOD System**.
- **Consequences:**
  - Maintains a dense, vibrant urban atmosphere without exceeding browser CPU and draw-call budgets.
  - Sustained 60 FPS on desktop and 30+ FPS in WebGL2 browser tabs.
