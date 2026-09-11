-- Statewide public land ownership clipped to the study area.
-- Source CRS EPSG:6514 -> project CRS EPSG:32100.

DROP TABLE IF EXISTS stage.public_land;

CREATE TABLE stage.public_land AS
SELECT
    p.gid,
    p.owner,
    p.acreage,
    ST_Transform(p.geom, 32100) AS geom
FROM raw.public_lands p
JOIN stage.study_area s
       ON ST_Intersects(p.geom, ST_Transform(s.geom, 6514));

ALTER TABLE stage.public_land ADD PRIMARY KEY (gid);
CREATE INDEX public_land_geom_idx ON stage.public_land USING GIST (geom);
CREATE INDEX public_land_owner_idx ON stage.public_land (owner);

COMMENT ON TABLE stage.public_land IS
  'MSDI public land ownership within HUC8 17010205, EPSG:32100. Published 2026-09-04. Authoritative source for public/private classification where coverage exists.';