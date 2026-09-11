-- Repair ring self-intersections in MSDI public lands geometry.
-- 2 of 555 features affected.

UPDATE stage.public_land
SET geom = ST_Multi(ST_MakeValid(geom))
WHERE NOT ST_IsValid(geom);