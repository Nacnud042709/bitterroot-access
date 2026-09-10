SELECT version();
SELECT postgis_full_version();

SELECT extname, extversion
FROM pg_extension
WHERE extname IN ('postgis','pgrouting')
ORDER BY 1;

SELECT nspname AS schema
FROM pg_namespace
WHERE nspname IN ('raw','stage','model','output')
ORDER BY 1;

-- Confirm the project CRS is present in the spatial reference table.
SELECT srid, LEFT(srtext, 60) AS srtext_head
FROM spatial_ref_sys
WHERE srid = 32100;

-- Reproject a point near Hamilton, MT from WGS84 to the project CRS.
-- Expect metric coordinates, not degrees.
SELECT ST_AsText(
    ST_Transform(
        ST_SetSRID(ST_MakePoint(-114.16, 46.25), 4326),
        32100
    )
) AS hamilton_mt_32100;