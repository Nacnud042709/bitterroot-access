-- Repair the 8 ring self-intersections found in source cadastral geometry.
UPDATE stage.parcel
SET geom = ST_Multi(ST_MakeValid(geom))
WHERE NOT ST_IsValid(geom);