-- NHDArea: channel represented as polygon where too wide for a line at 1:24k.
-- Retains StreamRiver (460) only.

DROP TABLE IF EXISTS stage.nhd_area;

CREATE TABLE stage.nhd_area AS
SELECT
    a.gid,
    a.permanent_identifier,
    a.gnis_name,
    a.ftype,
    a.fcode,
    a.areasqkm,
    ST_Transform(a.geom, 32100) AS geom
FROM raw.nhd_area a
JOIN stage.study_area s
       ON ST_Intersects(a.geom, ST_Transform(s.geom, 4269))
WHERE a.ftype = 460;

ALTER TABLE stage.nhd_area ADD PRIMARY KEY (gid);
CREATE INDEX nhd_area_geom_idx ON stage.nhd_area USING GIST (geom);

COMMENT ON TABLE stage.nhd_area IS
  'NHD polygon channel features (StreamRiver) within study area, EPSG:32100. Where present, the polygon edge approximates the channel margin better than a buffered centerline.';