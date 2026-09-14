-- Access points: USFS developed boating sites.
--
-- The FWP Fishing Access Site layer covers state-designated access only.
-- Forest Service developed recreation sites are a separate program with a
-- separate inventory (INFRA Rec_Infra_RecSite). Six BOATING SITE records fall
-- within the study area; the three on river channel are retained and the three
-- reservoir launches are excluded as out of scope.
--
-- Reservoir launches are excluded by proximity to a mapped waterbody. Distance
-- to the nearest lake separates the two groups cleanly: the three reservoir
-- sites (Painted Rocks, Lake Como) sit 0-37 m from a waterbody, the three river
-- sites 1,373-3,266 m. Threshold set at 500 m.
--
-- Distance to flowline does NOT work as a filter here: NHD runs ArtificialPath
-- lines through reservoirs to maintain network connectivity, so Slate Creek Bay
-- on Painted Rocks sits 9 m from a flowline while West Fork Boat Launch sits
-- 82 m. The flowline distance is retained only to place the access point on the
-- water, not to classify the site.
--
-- Source CRS EPSG:4269 -> project CRS EPSG:32100.

DROP TABLE IF EXISTS model.access_usfs;

CREATE TABLE model.access_usfs AS
SELECT
    r.gid,
    r.site_name,
    r.site_type,
    r.development_scale,
    ROUND(ST_Distance(ST_Transform(r.geom, 32100), f.geom)::numeric, 1) AS snap_dist_m,
    ST_ClosestPoint(f.geom, ST_Transform(r.geom, 32100))                AS geom
FROM raw.usfs_recsite r
JOIN stage.study_area s
       ON ST_Intersects(r.geom, ST_Transform(s.geom, 4269))
CROSS JOIN LATERAL (
    -- Nearest order-3+ flowline, used to place the entry point on the water.
    SELECT geom
    FROM stage.flowline fl
    WHERE fl.streamorde >= 3
    ORDER BY ST_Transform(r.geom, 32100) <-> fl.geom
    LIMIT 1
) f
WHERE r.site_type = 'BOATING SITE'
  AND ST_Distance(ST_Transform(r.geom, 32100), f.geom) <= 200
  AND NOT EXISTS (
        SELECT 1
        FROM stage.waterbody w
        WHERE ST_DWithin(ST_Transform(r.geom, 32100), w.geom, 500)
      );

ALTER TABLE model.access_usfs ADD PRIMARY KEY (gid);
CREATE INDEX access_usfs_geom_idx ON model.access_usfs USING GIST (geom);

COMMENT ON TABLE model.access_usfs IS
  'USFS developed boating sites on river channel. Complements the FWP FAS layer, which covers state-designated access only. See sql/23_access_usfs.sql.';