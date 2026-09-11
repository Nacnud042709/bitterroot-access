# Findings

Running log of results as they emerge. Query included so every number
can be reproduced and re-run when source data updates.

---

## 2026-09-11 — Public land frontage on the mapped channel margin

126.4 km of the NHDArea channel boundary is fronted by public land.
Against a total channel-polygon perimeter of roughly 590 km, that puts
public frontage at roughly 20%, and private frontage at roughly 80%.

| Owner | Features | km frontage |
|---|---|---|
| US Forest Service | 5 | 71.4 |
| US Fish and Wildlife Service | 2 | 18.0 |
| Montana State Trust Lands | 4 | 15.7 |
| Montana Fish, Wildlife, and Parks | 15 | 13.1 |
| City Government | 7 | 4.2 |
| State of Montana | 3 | 1.5 |
| County Government | 5 | 1.0 |
| MT DNRC | 1 | 0.8 |
| Montana University System | 3 | 0.6 |
| US Department of Defense | 1 | 0.1 |
| MT Dept of Transportation | 2 | 0.0 |

Notes:
- Forest Service mileage is concentrated on the upper East and West Forks,
  not the valley reaches where most fishing pressure is.
- FWP's 13.1 km is spread across 15 discrete features — the fishing access
  sites. Distribution matters more than total length for practical access.
- USFWS is Lee Metcalf NWR near Stevensville; has its own access rules and
  seasonal closures.
- MDT frontage is effectively zero. Bridge access points in Phase 4 must be
  derived from road-stream intersections, not from MDT right-of-way parcels.
- State Trust Lands are public but require a state lands recreational use
  license — not the same access regime as USFS.

```sql
WITH channel AS (SELECT ST_Union(geom) AS g FROM stage.nhd_area)
SELECT p.owner,
       COUNT(DISTINCT p.gid) AS parcels,
       ROUND((SUM(ST_Length(ST_Intersection(ST_Boundary(c.g), p.geom)))/1000)::numeric,1) AS km_frontage
FROM stage.public_land p, channel c
WHERE ST_Intersects(p.geom, c.g)
GROUP BY 1 ORDER BY 3 DESC;
```

---

## 2026-09-11 — Data quality on load

| Layer | Features | Invalid geometry | Notes |
|---|---|---|---|
| stage.parcel | 50,957 | 8 (0.016%) | Ring self-intersections, repaired with ST_MakeValid |
| stage.public_land | 555 | 2 | Ring self-intersections, repaired |
| stage.flowline | — | 0 | |

Parcel area after reprojection and repair: 1,843,551 acres computed vs
1,843,552 acres in the source `gisacres` field. Agreement to seven
significant figures confirms the EPSG:6514 → 32100 datum shift and the
geometry repair introduced no measurable error.

NHDPlus VAA join: 337,153 attribute rows against 339,214 flowlines.
2,061 flowlines fall outside the connected network and have no
value-added attributes. Retained via LEFT JOIN rather than dropped.

---

## 2026-09-11 — NHD represents the mainstem as polygon, not line

The entire Bitterroot mainstem (134.6 km), both forks, and the lower
reaches of Lolo, Fred Burr, and Threemile Creeks are mapped as NHDArea
polygons with ArtificialPath centerlines threading through them.

Discovered by computing flowline length inside channel polygons and
getting 303.8 km — more than twice the mainstem length. The number was
correct; the assumption behind the query was not.

Consequence: the original Phase 5 plan (buffer the centerline, intersect
with parcels, derive bank ownership) fails on the mainstem, where the
channel is wide enough that a 30 m buffer reaches neither bank. Revised
approach uses the NHDArea polygon boundary as the channel margin, which
is a better high-water-mark proxy than any assumed buffer width.

Visual inspection confirmed the polygon hugs the wetted channel tightly
rather than enclosing the braid plain.

## 2026-09-11 — FAS point/polygon mismatch

15 Fishing Access Site points in the study area, 14 polygons. Angler's
Roost (siteid 39355988) has a point record but no polygon in the FWP
statewide layer — confirmed absent from the source, not lost in clipping.

Consequence: channel frontage cannot be computed for Angler's Roost the
way it can for the other 14 sites. Handled as a point-only entry in the
Phase 4 access model.

Statewide the layer has 337 points and 333 polygons, so the gap is not
unique to this site.

## 2026-09-11 — FAS boundaries do not reliably touch the mapped channel

Only 9 of 14 FAS polygons intersect the NHDArea channel boundary, yet all
14 are within 87 m of it, and most within 20 m. Four sites with boat ramps
(Chief Looking Glass, Poker Joe, Florence Bridge, Wally Crawford) show no
channel intersection despite being launch points.

Cross-checking against flowlines, most of the non-intersecting sites touch
a flowline at 0 m — they sit on side channels or reaches upstream of where
NHD switches from line to polygon representation. Wally Crawford touches
neither (17 m to channel, 31.8 m to flowline); its boundary appears to
cover parking and approach rather than the launch itself.

Consequence: the Phase 4 access model snaps FAS sites to the nearest water
feature within a 100 m tolerance rather than requiring intersection. The
threshold is set by the observed maximum of 87.2 m.