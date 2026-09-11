-- Parcels from Ravalli and Missoula counties, clipped to the study area.
-- Source CRS EPSG:6514 (NAD83(2011) / Montana) -> project CRS EPSG:32100.

DROP TABLE IF EXISTS stage.parcel;

CREATE TABLE stage.parcel AS
WITH both_counties AS (
    SELECT * FROM raw.parcels_ravalli
    UNION ALL
    SELECT * FROM raw.parcels_missoula
)
SELECT
    p.gid,
    p.parcelid,
    p.countyname,
    p.ownername,
    p.proptype,
    p.gisacres,
    p.totalacres,
    p.taxyear,
    ST_Transform(p.geom, 32100) AS geom
FROM both_counties p
JOIN stage.study_area s
       ON ST_Intersects(p.geom, ST_Transform(s.geom, 6514));

CREATE INDEX parcel_geom_idx ON stage.parcel USING GIST (geom);
CREATE INDEX parcel_owner_idx ON stage.parcel (ownername);

COMMENT ON TABLE stage.parcel IS
  'Ravalli and Missoula county parcels intersecting HUC8 17010205, EPSG:32100. Source: MT Cadastral, published 2026-09-03.';
  ALTER TABLE stage.parcel ADD COLUMN parcel_uid bigserial PRIMARY KEY;