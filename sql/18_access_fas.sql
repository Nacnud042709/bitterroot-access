-- Access points: FWP Fishing Access Sites.
--
-- FAS boundaries do not reliably touch the mapped channel: only 9 of 14
-- polygons intersect it, though all 14 sit within 87.2 m. Sites are therefore
-- snapped to the nearest water feature (channel polygon or flowline) within
-- a 100 m tolerance rather than requiring intersection.
--
-- Angler's Roost has a point record but no polygon in the FWP source, so the
-- point geometry is used where no polygon exists.

DROP TABLE IF EXISTS model.access_fas;

CREATE TABLE model.access_fas AS
WITH site AS (
    -- Prefer the polygon; fall back to the point for sites lacking one.
    SELECT g.siteid, g.name, g.boat_fac, g.camping, g.geom, 'polygon' AS src
    FROM stage.fas_poly g
    UNION ALL
    SELECT p.siteid, p.name, p.boat_fac, p.camping, p.geom, 'point'
    FROM stage.fas_point p
    WHERE NOT EXISTS (SELECT 1 FROM stage.fas_poly g WHERE g.siteid = p.siteid)
),
water AS (
    SELECT geom FROM stage.nhd_area
    UNION ALL
    SELECT geom FROM stage.flowline WHERE streamorde >= 3
)
SELECT
    s.siteid,
    s.name,
    s.boat_fac,
    s.camping,
    s.src                              AS source_geom,
    ROUND(MIN(ST_Distance(s.geom, w.geom))::numeric, 1) AS snap_dist_m,
    ST_ClosestPoint(
        (array_agg(w.geom ORDER BY ST_Distance(s.geom, w.geom)))[1],
        s.geom
    )                                  AS geom
FROM site s
JOIN water w ON ST_DWithin(s.geom, w.geom, 100)
GROUP BY s.siteid, s.name, s.boat_fac, s.camping, s.src, s.geom;

ALTER TABLE model.access_fas ADD PRIMARY KEY (siteid);
CREATE INDEX access_fas_geom_idx ON model.access_fas USING GIST (geom);

COMMENT ON TABLE model.access_fas IS
  'FWP fishing access sites snapped to nearest water within 100 m. See sql/18_access_fas.sql for tolerance rationale.';