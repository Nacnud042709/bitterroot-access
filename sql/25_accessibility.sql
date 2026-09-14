-- Along-channel distance from every network edge to the nearest legal entry.
--
-- Distance is measured along the flowline network, not straight-line. On a
-- river this meandering, 500 m across a bend can be 2 km along the water, and
-- access is constrained to the channel -- a person cannot cut across private
-- ground to shorten the walk.
--
-- ENTRY POINT SELECTION
-- Only the 'open' access regime seeds the traversal. Licensed entries (State
-- Trust Lands, which require a recreational use license) and restricted entries
-- (refuge, DoD) are excluded, so the result reports access available without a
-- permit or seasonal check.
--
-- Frontage entries are line geometry covering a whole reach, so each is snapped
-- from its centroid. This understates frontage access slightly, since the
-- entire length is legally usable.
--
-- Where two entries snap to the same vertex -- a bridge and an FAS at the same
-- crossing, which happens at six locations including Bell Crossing, Darby
-- Bridge, and Angler's Roost -- only one is retained. 122 open-regime entries
-- collapse to 100 distinct network nodes.
--
-- SNAP CORRECTION
-- Network vertices exist only at confluences, so an access point mid-reach
-- snaps to the nearest confluence rather than its true position. Snap offsets
-- have a median of 116 m and a mean of 166 m, but 27 of 100 access nodes exceed
-- 200 m and one bridge on East Fork Road sits 908 m from its vertex.
--
-- The offset is subtracted from the routed cost and clamped at zero. This
-- assumes the access point lies between its vertex and the destination reach,
-- which holds in the common case but not always. The exact fix is to split
-- edges at access points so a vertex exists at each; that is a few hours of
-- work to correct a mean error under 200 m, and is recorded as future work.
--
-- Because the correction can reorder which entry is nearest -- a closer vertex
-- with a large snap offset may lose to a farther one with none -- the minimum
-- is taken after correction, not before.

-- ---------------------------------------------------------------------------
-- Access points snapped to network vertices
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS model.access_node;

CREATE TABLE model.access_node AS
SELECT DISTINCT ON (v.id)
    v.id                                     AS node_id,
    a.access_uid,
    a.access_type,
    a.label,
    ST_Distance(v.geom, ST_Centroid(a.geom)) AS snap_m
FROM model.access_all a
CROSS JOIN LATERAL (
    SELECT id, geom
    FROM model.network_vertices nv
    ORDER BY ST_Centroid(a.geom) <-> nv.geom
    LIMIT 1
) v
WHERE a.access_regime = 'open'
ORDER BY v.id, ST_Distance(v.geom, ST_Centroid(a.geom));

ALTER TABLE model.access_node ADD PRIMARY KEY (node_id);

COMMENT ON TABLE model.access_node IS
  'Open-regime access points snapped to network vertices. snap_m records the offset, which is subtracted from routed distance in model.reach_access.';

-- ---------------------------------------------------------------------------
-- Reach accessibility
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS model.reach_access;

CREATE TABLE model.reach_access AS
WITH costs AS (
    SELECT *
    FROM pgr_dijkstraCost(
        'SELECT id, source, target, cost, reverse_cost
           FROM model.network WHERE component = 1',
        (SELECT array_agg(node_id) FROM model.access_node),
        (SELECT array_agg(id) FROM model.network_vertices),
        directed := false
    )
),
nearest AS (
    -- Corrected distance per destination vertex, taking the minimum after
    -- the snap offset is applied.
    SELECT DISTINCT ON (c.end_vid)
        c.end_vid                                AS node_id,
        GREATEST(c.agg_cost - an.snap_m, 0)      AS dist_m
    FROM costs c
    JOIN model.access_node an ON an.node_id = c.start_vid
    ORDER BY c.end_vid, GREATEST(c.agg_cost - an.snap_m, 0)
)
SELECT
    n.id                                          AS edge_id,
    n.gnis_name,
    n.streamorde,
    ROUND(n.cost::numeric, 1)                     AS length_m,
    ROUND(LEAST(s.dist_m, t.dist_m)::numeric, 1)  AS dist_to_access_m,
    CASE
        WHEN LEAST(s.dist_m, t.dist_m) <=  800 THEN 'easy walk-in'
        WHEN LEAST(s.dist_m, t.dist_m) <= 3000 THEN 'moderate'
        WHEN LEAST(s.dist_m, t.dist_m) <= 8000 THEN 'long walk'
        ELSE 'remote'
    END                                           AS access_class,
    n.geom
FROM model.network n
LEFT JOIN nearest s ON s.node_id = n.source
LEFT JOIN nearest t ON t.node_id = n.target
WHERE n.component = 1;

ALTER TABLE model.reach_access ADD PRIMARY KEY (edge_id);
CREATE INDEX reach_access_geom_idx  ON model.reach_access USING GIST (geom);
CREATE INDEX reach_access_class_idx ON model.reach_access (access_class);

COMMENT ON TABLE model.reach_access IS
  'Flowline reaches classified by along-channel distance to the nearest open-regime access point, corrected for vertex snap offset. See sql/25_accessibility.sql.';