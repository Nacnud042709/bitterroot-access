-- Unified access layer. Phase 6 traverses the flowline network from these.
--
-- Three source categories with different geometry:
--   fas      - FWP fishing access sites, snapped to water within 100 m (15)
--   bridge   - NBI structures in public road ROW touching the channel (26)
--   frontage - public land channel frontage, as line geometry (101)
--
-- Frontage is stored as lines rather than points because the entire length is
-- a legal entry. Points and lines are unioned into a single MULTI geometry
-- column; Phase 6 measures along-channel distance from whichever is nearest.

DROP TABLE IF EXISTS model.access_all;

CREATE TABLE model.access_all AS
SELECT
    'fas'                         AS access_type,
    'open'                        AS access_regime,
    f.name                        AS label,
    f.siteid::text                AS source_id,
    ST_Multi(f.geom)              AS geom
FROM model.access_fas f

UNION ALL

SELECT
    'bridge',
    'open',
    b.facility_carried || ' @ ' || b.feature_crossed,
    b.structure_no,
    ST_Multi(b.geom)
FROM model.access_bridge b

UNION ALL

SELECT
    'frontage',
    r.access_regime,
    COALESCE(r.agency, 'unknown agency'),
    r.parcel_uid::text,
    r.geom
FROM model.access_frontage r;

ALTER TABLE model.access_all ADD COLUMN access_uid bigserial PRIMARY KEY;
CREATE INDEX access_all_geom_idx ON model.access_all USING GIST (geom);
CREATE INDEX access_all_type_idx ON model.access_all (access_type, access_regime);

COMMENT ON TABLE model.access_all IS
  'All modeled legal entry points to the channel. See sql/18-20 for each category.';