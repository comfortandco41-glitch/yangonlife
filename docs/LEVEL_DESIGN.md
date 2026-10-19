# Level Design Document — Yangon Frontline

## 1. Map Overview: Downtown Yangon Prototype Arena
- **Setting:** A stylized downtown Yangon urban corridor inspired by Merchant Street and Sule Pagoda Road.
- **Dimensions:** 60 meters (East-West) by 35 meters (North-South).
- **Theme:** Colonial-era municipal facades, street-level shophouses, roadside tea shops, cracked tarmac, concrete roadblocks, and sandbag defensive positions.

```
       +-------------------------------------------------------+
       | [Colonial Tenement A]      [Colonial Tenement B]      |
       | [Tea Shop Veranda]         [Market Stall Row]         |
+------+------------------+---------+--------------------------+------+
| SPAWN| [Sidewalk]       |         | [Sidewalk]               | HOSTILE
| ZONE | =================+=========+=========================| SPAWN
| (PDF)| [Roadway - Lane 1]   (Bus)   [Roadway - Lane 2]       | (MIL)
|      | -----------------+---------+--------------------------|      |
|      | [Roadway - Lane 2]  (Crates) [Roadway - Lane 1]       |      |
|      | =================+=========+=========================|      |
|      | [Sidewalk]       |         | [Sidewalk]               |      |
+------+------------------+---------+--------------------------+------+
       | [Apartment Block C]        [Shophouse Row D]          |
       | [Concrete Wall Barrier]    [Sandbag Bunker]           |
       +-------------------------------------------------------+
```

---

## 2. Structural Elements & Zones
1. **Player Spawn Zone (West):**
   - Located behind concrete roadblocks and a low brick planter box.
   - Provides safe initial cover and line of sight down the main road.
2. **Main Road Corridor:**
   - 12-meter-wide asphalt surface with faded yellow center lines.
   - Broken down low-poly transit bus positioned mid-street as a major tactical choke and sightline breaker.
   - Scattered concrete barricades and wooden supply pallets offering crouch-height and stand-height cover.
3. **North Sidewalk & Shophouses:**
   - Elevated sidewalk (0.2m curb) lined with low-poly colonial shophouses featuring overhanging balconies and corrugated metal awnings.
   - A corner street tea shop with outdoor wooden tables and stools providing flanking routes.
4. **South Sidewalk & Perimeter:**
   - Solid brick and concrete walls with posters and graffiti decals preventing map escape.
5. **Hostile AI Spawn / Patrol Zone (East):**
   - Elevated courtyard with sandbags and an open intersection where patrol AI agents spawn.

---

## 3. Collision & Navigation Specifications
- **Collision Layers:**
  - `Layer 1 (World / Environment):` Buildings, ground, barricades, bus, curbs. Static bodies with box/convex collision shapes.
  - `Layer 2 (Characters):` Player and AI soldier capsule collision shapes (`radius: 0.4m`, `height: 1.8m`).
  - `Layer 3 (Hitboxes):` Raycast-specific hit detection bodies with distinct head/torso multipliers.
- **Navigation Mesh:**
  - Baked `NavigationRegion3D` covering street and sidewalk walkable geometry.
  - Excludes building interiors and tops of high barricades.
  - Agent radius set to `0.45m`, max climb height `0.3m`, max slope `35°`.

---

## 4. Performance & Browser Budgets
- **Total Draw Calls:** < 120 calls per frame in full view.
- **Triangle Count:** < 45,000 triangles total scene budget.
- **Shadows:** Directional sun light with Orthogonal PSSM (2 splits) or single split for browser stability.
- **Materials:** Unshaded or simple Lambert/StandardMaterial3D with roughness/metallic maps; no compute shaders.
