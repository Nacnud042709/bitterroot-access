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

## 2026-09-11 — Bridge-to-flowline matching threshold

167 NBI structures in the study area. Distance from each to the nearest
flowline shows a clear break: 141 within 40 m, a sparse tail of 15 between
40 and 200 m, and 11 beyond 200 m.

Threshold set at 50 m, capturing 143 structures. Justification: NBI records
coordinates to the nearest second, roughly 30 m at this latitude, so offsets
under 40 m are within expected positional error. The 24 structures beyond
50 m are predominantly bridges over irrigation canals and ditches — excluded
from stage.flowline as ftype 336 — plus one wildlife underpass carrying US 93
over a game corridor rather than water.

The distance measure therefore doubles as a filter: structures over excluded
infrastructure sort themselves out without manual classification.

Boulder Creek (structure 010304000000010, USFS): 200 m from the nearest
flowline of any name, and 955 m from any segment NHD names "Boulder Creek",
despite 52 Boulder Creek segments in the basin. Either the NBI coordinate is
wrong or the USFS local name differs from the GNIS name for that drainage.
Single structure on an upper East Fork tributary; excluded by the 50 m
matching threshold and not material to the access model.

---
## 2026-09-13 — Ownership classification

50,957 parcels classified into three classes:

| Class | Method | Parcels | Acres |
|---|---|---|---|
| private | spatial | 42,894 | 445,290 |
| public | spatial | 3,416 | 1,385,212 |
| public | name_pattern | 27 | 164 |
| row | no_owner_attribution | 4,620 | 12,887 |

**Rights-of-way.** 4,620 parcels carry no owner, parcel id, or property type.
Shape index 11.6 (compact blocks would be ~4) and visual inspection confirm
these are the municipal street grid and rural section-line roads. Relevant to
Phase 4: HB 190 grants public water access at county road right-of-way, and
130 of 167 NBI bridges fall within 50 m of one of these parcels.

**Spatial threshold.** Public-land coverage per parcel is strongly bimodal:
3,893 parcels below 10%, 3,425 above 90%, 113 between. Threshold set at 50%,
which sits in the empty middle. Where parcels are entirely within public land
the two layers agree on area to within 0.1 m², indicating the cadastral and
MSDI boundaries were derived consistently.

**Name-pattern supplement.** 27 parcels (164 acres) have governmental owner
names but little or no public-land coverage — all small municipal and county
holdings. MSDI maps federal ownership thoroughly and local government
spottily. These are classified public by name rule; the method column records
which parcels this applies to.

**Validation error worth recording.** The first cross-check used ILIKE
'%USA%' and '%COUNTY%' and returned 405 apparent disagreements. Most were
false matches: '%USA%' matches "SUSAN", and '%COUNTY%' matches business names
like "Ravalli County Bank". Anchoring the patterns reduced the genuine
disagreement set to 27.
---
Access type	km of channel frontage
Private	369.8
Parallel road ROW	70.3
Open public land	85.1
Restricted (refuge)	18.3
Licensed (state trust)	16.5
Municipal	5.3
Bridge crossings	4.45
---
## 2026-09-13 — Access point model

142 modeled legal entry points:

| Type | Regime | Count | Extent |
|---|---|---|---|
| frontage | open | 78 | 85.0 km |
| frontage | restricted | 18 | 18.3 km |
| frontage | licensed | 5 | 16.5 km |
| bridge | open | 26 | 4.45 km |
| fas | open | 15 | points |

**FAS snapping.** All 15 sites snapped within 48.7 m once order-3+ flowlines
were included alongside the channel polygon — lower than the 87.2 m observed
against the polygon alone. The 100 m tolerance is conservative; 50 m would
suffice.

**Bridge crossings.** 26 NBI structures within a public road ROW parcel
touching the channel. All owner codes are 01 (state), 02 (county), or 64
(USFS) — no private structures, confirming the NBI approach succeeded where
the MSDI road layer could not. One wildlife underpass on US 93 was excluded by
feature description: it sat 9.5 m from a flowline because a small drainage runs
through the same structure, so the distance threshold alone did not catch it.

**Frontage by agency (open regime).** USFS 71.5 km across 54 parcels, FWP
11.7 km across 21. The USFS mileage is concentrated on the upper forks; FWP's
is distributed down the valley. Distribution matters more than extent for
practical access.

**Known under-count.** Municipal frontage (5.3 km) is excluded because the
class mixes parks with shop yards and treatment plants. Resolving it requires
parcel-level review.

**Duplicate-row error, third occurrence.** The bridge join returned 47 rows for
27 bridges, because a crossing typically sits where several ROW parcels meet.
Fixed with a lateral join taking the nearest parcel only. This is the same
failure mode as the 303.8 km flowline length and the public-land acreage
exceeding the basin area: a spatial join matching one feature to many, then
aggregating or keying on the result. The check that catches it is comparing
row count to distinct count of the entity being modeled.