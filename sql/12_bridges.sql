-- National Bridge Inventory, Montana, clipped to study area.
-- Source CRS EPSG:4326 -> project CRS EPSG:32100.
-- NBI inventories public bridges >20ft only; private structures absent by design.

DROP TABLE IF EXISTS stage.bridge;

CREATE TABLE stage.bridge AS
SELECT
    n.gid,
    n.structure_number_008        AS structure_no,
    n.features_desc_006a          AS feature_crossed,
    n.facility_carried_007        AS facility_carried,
    n.owner_022                   AS owner_code,
    n.maintenance_021             AS maint_code,
    n.county_code_003             AS county_fips,
    n.year_built_027              AS year_built,
    n.structure_len_mt_049        AS length_m,
    n.adt_029                     AS traffic_count,
    ST_Transform(n.geom, 32100)   AS geom
FROM raw.nbi n
JOIN stage.study_area s
       ON ST_Intersects(n.geom, ST_Transform(s.geom, 4326));

ALTER TABLE stage.bridge ADD PRIMARY KEY (gid);
CREATE INDEX bridge_geom_idx ON stage.bridge USING GIST (geom);

COMMENT ON TABLE stage.bridge IS
  'National Bridge Inventory structures within HUC8 17010205, EPSG:32100. Authoritative source for public bridge crossings; all owner codes in basin are public (01 state, 02 county, 64 USFS).';