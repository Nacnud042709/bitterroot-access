-- FAS polygons. 333 statewide vs 337 points; four sites lack polygon extent.
-- FWP Fishing Access Sites (points), clipped to study area.
-- Source CRS EPSG:3857 (Web Mercator) -> project CRS EPSG:32100.

DROP TABLE IF EXISTS stage.fas_point;

CREATE TABLE stage.fas_point AS
SELECT
    f.gid,
    f.siteid,
    f.name,
    f.boat_fac,
    f.camping,
    f.acres,
    f.latitude   AS src_latitude,
    f.longitude  AS src_longitude,
    f.web_page,
    ST_Transform(f.geom, 32100) AS geom
FROM raw.fas_point f
JOIN stage.study_area s
       ON ST_Intersects(f.geom, ST_Transform(s.geom, 3857));

ALTER TABLE stage.fas_point ADD PRIMARY KEY (gid);
CREATE INDEX fas_point_geom_idx ON stage.fas_point USING GIST (geom);

COMMENT ON TABLE stage.fas_point IS
  'FWP Fishing Access Sites within HUC8 17010205, EPSG:32100. Primary legal entry points for the access model.';
DROP TABLE IF EXISTS stage.fas_poly;

CREATE TABLE stage.fas_poly AS
SELECT
    f.gid,
    f.siteid,
    f.name,
    f.fwpreg,
    f.acres,
    f.camping,
    f.boat_fac,
    f.acqdate,
    ST_Transform(f.geom, 32100) AS geom
FROM raw.fas_poly f
JOIN stage.study_area s
       ON ST_Intersects(f.geom, ST_Transform(s.geom, 3857));

ALTER TABLE stage.fas_poly ADD PRIMARY KEY (gid);
CREATE INDEX fas_poly_geom_idx ON stage.fas_poly USING GIST (geom);
CREATE INDEX fas_poly_siteid_idx ON stage.fas_poly (siteid);

COMMENT ON TABLE stage.fas_poly IS
  'FWP Fishing Access Site boundaries within HUC8 17010205, EPSG:32100. Used for channel frontage; paired to fas_point by siteid.';