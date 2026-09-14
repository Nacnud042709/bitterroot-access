-- Routable flowline network for accessibility analysis.
--
-- Restricted to order-3 and above. The basin has 6,108 first-order flowlines
-- totaling 6,192 km -- over half the total length in steep headwater trickles,
-- mostly in wilderness. Including them would triple the graph for water nobody
-- fishes.
--
-- pgr_createTopology assigns source and target node ids by snapping endpoints
-- within a tolerance. NHD flowlines share exact endpoints at confluences, so
-- a small tolerance is appropriate; too large would merge distinct confluences.
-- -- CONNECTIVITY CONSEQUENCE OF THE ORDER-3 THRESHOLD
-- The network resolves into one dominant component of 3,250 nodes (95%) plus
-- 21 fragments totaling 162 nodes. The fragments are order-3 reaches on valley
-- tributaries -- Gird, Birch, Dry, Bunkhouse, Willoughby, Pattee, and Saint
-- Clair Creeks -- whose connection to the mainstem runs through order-2
-- segments below the threshold. Gird Creek is the clearest case: 27 order-3
-- segments (14.4 km) reach the river only through 17 order-2 segments (9.7 km).
--
-- This is a consequence of the threshold, not a data defect. Reaches in the
-- fragments are unreachable in the accessibility model and are reported as
-- excluded rather than as remote. Dropping to order 2 would reconnect roughly
-- 45 km of small valley creek at the cost of roughly tripling the graph, which
-- is not a trade worth making for water that flows through hayfields.

DROP TABLE IF EXISTS model.network;

CREATE TABLE model.network AS
SELECT
    gid                       AS id,
    gnis_name,
    streamorde,
    nhdplusid,
    hydroseq,
    levelpathi,
    ST_Length(geom)           AS cost,
    ST_Length(geom)           AS reverse_cost,
    NULL::bigint              AS source,
    NULL::bigint              AS target,
    ST_LineMerge(geom)        AS geom
FROM stage.flowline
WHERE streamorde >= 3;

ALTER TABLE model.network ADD PRIMARY KEY (id);
CREATE INDEX network_geom_idx   ON model.network USING GIST (geom);
CREATE INDEX network_source_idx ON model.network (source);
CREATE INDEX network_target_idx ON model.network (target);

-- pgr_createTopology was removed in pgRouting 4.0. The replacement workflow
-- extracts vertices from edge endpoints, then assigns source and target by
-- matching each edge's start and end point back to the vertex table.
-- NHD flowlines share exact endpoints at confluences, so exact geometry
-- equality is sufficient and no snapping tolerance is needed.

DROP TABLE IF EXISTS model.network_vertices;

CREATE TABLE model.network_vertices AS
SELECT *
FROM pgr_extractVertices('SELECT id, geom FROM model.network');

CREATE INDEX network_vertices_geom_idx ON model.network_vertices USING GIST (geom);

UPDATE model.network n
SET source = v.id
FROM model.network_vertices v
WHERE ST_StartPoint(n.geom) = v.geom;

UPDATE model.network n
SET target = v.id
FROM model.network_vertices v
WHERE ST_EndPoint(n.geom) = v.geom;

COMMENT ON TABLE model.network IS
  'Routable flowline network, order 3+. cost and reverse_cost are segment length in metres; traversal is bidirectional since a wader can move either way. See sql/24_network.sql.';

-- Record component membership so downstream queries can exclude unreachable
-- edges explicitly rather than silently returning no route.
ALTER TABLE model.network ADD COLUMN component bigint;

WITH c AS (
    SELECT * FROM pgr_connectedComponents(
        'SELECT id, source, target, cost, reverse_cost FROM model.network'
    )
)
UPDATE model.network n
SET component = c.component
FROM c
WHERE n.source = c.node;

CREATE INDEX network_component_idx ON model.network (component);