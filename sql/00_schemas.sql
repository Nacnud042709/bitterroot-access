-- Bitterroot Public Water Access
-- Phase 0: extensions, schemas, project conventions

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting;

-- Four-schema pipeline. Data flows one direction only.
CREATE SCHEMA IF NOT EXISTS raw;     -- as-downloaded. NEVER modified.
CREATE SCHEMA IF NOT EXISTS stage;   -- cleaned, reprojected, validated
CREATE SCHEMA IF NOT EXISTS model;   -- derived analysis layers
CREATE SCHEMA IF NOT EXISTS output;  -- final published layers

COMMENT ON SCHEMA raw   IS 'Source data as loaded. Read-only by convention. Reload rather than edit.';
COMMENT ON SCHEMA stage IS 'Normalized: EPSG:32100, valid geometry, standardized columns.';
COMMENT ON SCHEMA model IS 'Derived: classifications, access points, reaches, network.';
COMMENT ON SCHEMA output IS 'Publication-ready layers for cartography and export.';

-- Project CRS: EPSG:32100  NAD83 / Montana (meters)
-- Everything in stage/ and beyond lives in this CRS. No exceptions.

-- Data source inventory. Populate as you download in Phase 1.
CREATE TABLE IF NOT EXISTS model.data_sources (
    id              serial PRIMARY KEY,
    layer_name      text NOT NULL,
    source_agency   text,
    source_url      text,
    native_crs      text,
    native_format   text,
    license         text,
    retrieved_on    date,
    update_cadence  text,
    notes           text
);

COMMENT ON TABLE model.data_sources IS
  'Provenance for every layer in raw/. Fill this in as you download, not later.';