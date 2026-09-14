-- Access regime for public parcels.
--
-- Ownership answers "who holds title". This answers "can the public walk on
-- it, and on what terms". The two are not the same, and collapsing them would
-- overstate access on roughly 39,000 acres of State Trust Land alone.
--
-- Regimes:
--   open       - open to public recreation without permit (USFS, BLM, FWP, DNRC)
--   licensed   - public recreation requires a State Lands Recreational Use
--                License (Montana State Trust Lands, 121 parcels / 38,559 ac)
--   restricted - public land with seasonal closures, designated areas, or
--                non-recreational use (USFWS refuge, DoD, university system)
--   municipal  - city/county/local holdings; includes parks (accessible) and
--                shop yards, treatment plants, etc. (not). Not resolved here.
--   row        - road right-of-way. Not recreational land, but relevant to
--                bridge access under HB 190.
--   n/a        - private parcels

DROP TABLE IF EXISTS model.parcel_access;

CREATE TABLE model.parcel_access AS
SELECT
    o.*,
    CASE
        WHEN o.ownership_class = 'row'     THEN 'row'
        WHEN o.ownership_class = 'private' THEN 'n/a'
        WHEN o.agency = 'Montana State Trust Lands' THEN 'licensed'
        WHEN o.agency IN ('US Fish and Wildlife Service',
                          'US Department of Defense',
                          'Montana University System') THEN 'restricted'
        WHEN o.agency IN ('City Government',
                          'County Government',
                          'Local Government',
                          'Montana Department of Transportation') THEN 'municipal'
        WHEN o.agency IN ('US Forest Service',
                          'US Bureau of Land Management',
                          'Montana Fish, Wildlife, and Parks',
                          'Montana Department of Natural Resources and Conservation',
                          'State of Montana',
                          'US Government') THEN 'open'
                -- Name-pattern parcels have no agency from the spatial join;
        -- derive the regime from the owner name instead.
        WHEN o.method = 'name_pattern' AND (
                 o.ownername ILIKE '%FOREST SERVICE%'
              OR o.ownername ILIKE '%UNITED STATES OF AMERICA%'
              OR o.ownername ILIKE 'USA %'
              OR o.ownername ILIKE 'USA-%'
             )                                        THEN 'open'
        WHEN o.method = 'name_pattern' AND (
                 o.ownername ILIKE 'MONTANA STATE OF%'
              OR o.ownername ILIKE 'STATE OF MONTANA%'
             )                                        THEN 'open'
        WHEN o.method = 'name_pattern'                THEN 'municipal'
        ELSE 'unclassified'
    END AS access_regime
FROM model.parcel_ownership o;

ALTER TABLE model.parcel_access ADD PRIMARY KEY (parcel_uid);
CREATE INDEX parcel_access_regime_idx ON model.parcel_access (access_regime);

COMMENT ON TABLE model.parcel_access IS
  'Parcel ownership with access regime. Distinguishes open public land from licensed (state trust), restricted (refuge, DoD), and municipal holdings. See sql/17_access_regime.sql header.';