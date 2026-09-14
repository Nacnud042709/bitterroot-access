-- Access points: public bridge crossings.
--
-- HB 190 (2009) confirms public access to surface waters by public bridge or
-- county road right-of-way. Candidate crossings are NBI structures that fall
-- within a road ROW parcel touching the mapped channel.
--
-- NBI inventories public bridges over 20 ft only, so private structures are
-- absent by design. This avoids the MSDI road layer's problem, where the
-- Ownership attribute is unpopulated in both counties and RoadClass proved an
-- unreliable proxy (45% of privately-owned roads are classed Local).
--
-- Structures over irrigation canals and ditches are excluded by the 50 m
-- flowline-matching threshold, since ftype 336 was dropped from stage.flowline.
--
-- A bridge typically sits where several ROW parcels meet, so the ROW join uses
-- a lateral with LIMIT 1 to take the nearest parcel only. A plain join returned
-- 47 rows for 27 bridges.
-- NBI includes non-water structures such as wildlife crossings. These are
-- excluded by feature description, since the 50 m flowline threshold does not
-- catch them when a small drainage runs through the same structure.

DROP TABLE IF EXISTS model.access_bridge;

CREATE TABLE model.access_bridge AS
WITH channel AS (
    SELECT ST_Union(geom) AS g FROM stage.nhd_area
),
row_parcel AS (
    SELECT p.parcel_uid, p.geom
    FROM stage.parcel p
    JOIN model.parcel_access a USING (parcel_uid)
    WHERE a.access_regime = 'row'
)
SELECT
    b.gid                                          AS bridge_gid,
    b.structure_no,
    b.feature_crossed,
    b.facility_carried,
    b.owner_code,
    b.year_built,
    r.parcel_uid                                   AS row_parcel_uid,
    ROUND(ST_Distance(b.geom, f.geom)::numeric, 1) AS m_to_flowline,
    ST_ClosestPoint(f.geom, b.geom)                AS geom
FROM stage.bridge b
CROSS JOIN LATERAL (
    -- Nearest road ROW parcel within 50 m. LIMIT 1 keeps one row per bridge.
    SELECT parcel_uid, geom
    FROM row_parcel rp
    WHERE ST_DWithin(b.geom, rp.geom, 50)
    ORDER BY b.geom <-> rp.geom
    LIMIT 1
) r
CROSS JOIN LATERAL (
    -- Nearest flowline, used to place the entry point on the water.
    SELECT geom
    FROM stage.flowline fl
    ORDER BY b.geom <-> fl.geom
    LIMIT 1
) f
WHERE ST_Distance(b.geom, f.geom) <= 50
    AND b.feature_crossed NOT ILIKE '%UNDERPASS%'
    AND EXISTS (SELECT 1 FROM channel c WHERE ST_Intersects(r.geom, c.g));
  

ALTER TABLE model.access_bridge ADD PRIMARY KEY (bridge_gid);
CREATE INDEX access_bridge_geom_idx ON model.access_bridge USING GIST (geom);

COMMENT ON TABLE model.access_bridge IS
  'Public bridge crossings usable as legal entry under HB 190. NBI structures within a road ROW parcel touching the mapped channel. See sql/19_access_bridge.sql.';