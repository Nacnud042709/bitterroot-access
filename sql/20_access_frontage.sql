-- Access points: public land frontage on the channel.
--
-- Where public land abuts the mapped channel, the entire frontage is a legal
-- entry, not a discrete point. This is the largest access category by extent:
-- roughly 85 km of open-regime frontage against 4.45 km at bridge crossings.
--
-- Only the 'open' access regime is included. State Trust Lands ('licensed',
-- 16.5 km) require a State Lands Recreational Use License; refuge and DoD land
-- ('restricted', 18.3 km) carries seasonal closures and designated-area rules.
-- Both are modeled separately rather than treated as open access.
--
-- Municipal parcels ('municipal', 5.3 km) are excluded because the class mixes
-- parks with shop yards and treatment plants; resolving them requires parcel-
-- level review not yet done. Documented as a known under-count.

DROP TABLE IF EXISTS model.access_frontage;

CREATE TABLE model.access_frontage AS
WITH channel AS (
    SELECT ST_Boundary(ST_Union(geom)) AS g FROM stage.nhd_area
)
SELECT
    p.parcel_uid,
    a.agency,
    a.access_regime,
    ROUND(ST_Length(ST_Intersection(c.g, p.geom))::numeric, 1) AS frontage_m,
    ST_Multi(ST_Intersection(c.g, p.geom))                     AS geom
FROM model.parcel_access a
JOIN stage.parcel p USING (parcel_uid)
CROSS JOIN channel c
WHERE a.access_regime IN ('open', 'licensed', 'restricted')
  AND ST_Intersects(p.geom, c.g)
  AND ST_Length(ST_Intersection(c.g, p.geom)) >= 10;

ALTER TABLE model.access_frontage ADD PRIMARY KEY (parcel_uid);
CREATE INDEX access_frontage_geom_idx ON model.access_frontage USING GIST (geom);
CREATE INDEX access_frontage_regime_idx ON model.access_frontage (access_regime);

COMMENT ON TABLE model.access_frontage IS
  'Channel frontage of public land, as line geometry. Open, licensed, and restricted regimes retained separately. See sql/20_access_frontage.sql.';