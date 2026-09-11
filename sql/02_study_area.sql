-- Study area: Bitterroot subbasin, HUC8 17010205
-- Reprojected from NAD83 geographic (4269) to the project CRS (32100).

DROP TABLE IF EXISTS stage.study_area;

CREATE TABLE stage.study_area AS
SELECT
    huc8,
    name,
    areasqkm                  AS source_areasqkm,
    ST_Transform(geom, 32100) AS geom
FROM raw.wbd_huc8
WHERE huc8 = '17010205';

ALTER TABLE stage.study_area ADD PRIMARY KEY (huc8);
CREATE INDEX study_area_geom_idx ON stage.study_area USING GIST (geom);

COMMENT ON TABLE stage.study_area IS
  'Bitterroot subbasin (HUC8 17010205), EPSG:32100. Clip boundary for all other layers.';