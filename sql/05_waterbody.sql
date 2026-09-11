-- Waterbodies clipped to the Bitterroot study area, reprojected to EPSG:32100.
-- Retains LakePond (390) and Reservoir (436). Excludes swamp/marsh, ice, playa.

DROP TABLE IF EXISTS stage.waterbody;

CREATE TABLE stage.waterbody AS
SELECT
    w.gid,
    w.permanent_identifier,
    w.gnis_id,
    w.gnis_name,
    w.ftype,
    w.fcode,
    w.areasqkm,
    ST_Transform(w.geom, 32100) AS geom
FROM raw.nhd_waterbody w
JOIN stage.study_area s
       ON ST_Intersects(w.geom, ST_Transform(s.geom, 4269))
WHERE w.ftype IN (390, 436);

ALTER TABLE stage.waterbody ADD PRIMARY KEY (gid);
CREATE INDEX waterbody_geom_idx ON stage.waterbody USING GIST (geom);

COMMENT ON TABLE stage.waterbody IS
  'NHD lakes and reservoirs within HUC8 17010205, EPSG:32100. Cartographic context and ArtificialPath reference.';