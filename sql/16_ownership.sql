-- Ownership classification for parcels in the study area.
--
-- Method, in order of precedence:
--   1. Road rights-of-way, identified by absent owner attribution. The
--      cadastral layers carry these as unassessed polygons with no parcel id,
--      owner, or property type. 4,620 parcels, 12,887 acres. Verified visually
--      as the municipal street grid and rural section-line roads.
--   2. Spatial overlap with stage.public_land (MSDI, 19-value controlled
--      vocabulary of agency names). Threshold 50%: the coverage distribution
--      is strongly bimodal, with 3,893 parcels below 10%, 3,425 above 90%,
--      and only 113 in between.
--   3. Owner-name patterns, as a supplement. Catches 27 parcels (163 acres)
--      the spatial layer misses, all small municipal and county holdings.
--      MSDI maps federal ownership thoroughly and local government spottily.
--
-- The method column records which rule decided each parcel.

DROP TABLE IF EXISTS model.parcel_ownership;

CREATE TABLE model.parcel_ownership AS
WITH overlap AS (
    SELECT
        p.parcel_uid,
        ST_Area(ST_Intersection(p.geom, ST_Union(l.geom)))
            / NULLIF(ST_Area(p.geom), 0)                     AS public_frac,
        (array_agg(l.owner ORDER BY ST_Area(ST_Intersection(p.geom, l.geom)) DESC))[1]
                                                             AS dominant_agency
    FROM stage.parcel p
    JOIN stage.public_land l ON ST_Intersects(p.geom, l.geom)
    GROUP BY p.parcel_uid, p.geom
),
flagged AS (
    SELECT
        p.parcel_uid,
        p.parcelid,
        p.countyname,
        p.ownername,
        p.gisacres,
        COALESCE(o.public_frac, 0) AS public_frac,
        o.dominant_agency,
        (p.ownername IS NULL OR p.ownername = '') AS is_row,
        (COALESCE(o.public_frac, 0) >= 0.5)       AS is_spatial_public,
        (    p.ownername ILIKE 'USA %'
          OR p.ownername ILIKE 'USA-%'
          OR p.ownername ILIKE '%UNITED STATES OF AMERICA%'
          OR p.ownername ILIKE '%FOREST SERVICE%'
          OR p.ownername ILIKE 'MONTANA STATE OF%'
          OR p.ownername ILIKE 'STATE OF MONTANA%'
          OR p.ownername ~ '^(RAVALLI|MISSOULA) COUNTY$'
          OR p.ownername ILIKE '%CITY OF %'
          OR p.ownername ILIKE '%TOWN OF %'
        ) AS is_name_public
    FROM stage.parcel p
    LEFT JOIN overlap o ON o.parcel_uid = p.parcel_uid
)
SELECT
    parcel_uid,
    parcelid,
    countyname,
    ownername,
    gisacres,
    public_frac,
    CASE
        WHEN is_row            THEN 'row'
        WHEN is_spatial_public THEN 'public'
        WHEN is_name_public    THEN 'public'
        ELSE 'private'
    END AS ownership_class,
    CASE
        WHEN is_row            THEN 'no_owner_attribution'
        WHEN is_spatial_public THEN 'spatial'
        WHEN is_name_public    THEN 'name_pattern'
        ELSE 'spatial'
    END AS method,
    CASE
        WHEN is_spatial_public THEN dominant_agency
    END AS agency
FROM flagged;

ALTER TABLE model.parcel_ownership ADD PRIMARY KEY (parcel_uid);
CREATE INDEX parcel_ownership_class_idx  ON model.parcel_ownership (ownership_class);
CREATE INDEX parcel_ownership_method_idx ON model.parcel_ownership (method);

COMMENT ON TABLE model.parcel_ownership IS
  'Public/private/ROW classification for study area parcels. Spatial method against MSDI public lands with owner-name supplement; see sql/16_ownership.sql header for thresholds and rationale.';