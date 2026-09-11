-- Backfill provenance for datasets loaded before the inventory habit stuck.

INSERT INTO model.data_sources (
    layer_name, source_agency, source_url, native_crs,
    native_format, license, retrieved_on, update_cadence, notes
) VALUES
(
    'parcels_ravalli',
    'Montana State Library (MSDI) / MT Dept of Revenue',
    'ftpgeoinfo.msl.mt.gov/Data/Spatial/MSDI/Cadastral/Parcels/Ravalli/',
    'EPSG:6514',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'monthly',
    'Published 2026-09-03. 33,271 parcels. Ravalli County maintains its own parcel data rather than DOR. Schema verified identical to Missoula.'
),
(
    'parcels_missoula',
    'Montana State Library (MSDI) / MT Dept of Revenue',
    'ftpgeoinfo.msl.mt.gov/Data/Spatial/MSDI/Cadastral/Parcels/Missoula/',
    'EPSG:6514',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'monthly',
    '60,739 parcels statewide county extent; 17,688 within study area. PropAccess attribute is entirely empty in both counties.'
),
(
    'public_lands',
    'Montana State Library (MSDI)',
    'ftpgeoinfo.msl.mt.gov/Data/Spatial/MSDI/Cadastral/PublicLands/',
    'EPSG:6514',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'periodic',
    'Published 2026-09-04. 31,091 features statewide, 555 in study area. OWNER field is a clean controlled vocabulary of 19 agency names. Authoritative source for public/private classification in Phase 3.'
),
(
    'fas_point',
    'Montana Fish, Wildlife and Parks',
    'https://gis-mtfwp.hub.arcgis.com/datasets/40c5d0eafa9343249239b71cbd4e95b6_0/explore?location=46.733206%2C-112.774811%2C6',
    'EPSG:3857',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'periodic',
    '337 sites statewide, 15 in study area. Carries boat facility, camping, and acreage attributes.'
),
(
    'fas_poly',
    'Montana Fish, Wildlife and Parks',
    'https://gis-mtfwp.hub.arcgis.com/datasets/40c5d0eafa9343249239b71cbd4e95b6_0/explore?location=46.733206%2C-112.774811%2C6',
    'EPSG:3857',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'periodic',
    '333 polygons statewide vs 337 points; 14 in study area. Angler''s Roost has a point but no polygon in the source.'
);