-- Provenance for datasets loaded without source records.

INSERT INTO model.data_sources (
    layer_name, source_agency, source_url, native_crs,
    native_format, license, retrieved_on, update_cadence, notes
) VALUES
(
    'nbi',
    'FHWA / Bureau of Transportation Statistics',
    'https://geodata.bts.gov/datasets/usdot::national-bridge-inventory/explore?location=46.375098%2C-114.203193%2C9',
    'EPSG:4326',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'annual',
    'National Bridge Inventory, filtered to STATE_CODE_001 = 30 on load. 167 structures in study area. Inventories public bridges over 20 ft only; private structures absent by design. Owner codes present in basin: 01 state, 02 county, 64 USFS.'
),
(
    'msdi_transportation',
    'Montana State Library (MSDI)',
    'https://ftpgeoinfo.msl.mt.gov/Data/Spatial/MSDI/Transportation/TransportationFramework_gdb.zip',
    'EPSG:6514',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'periodic',
    'NENA-standard road centerlines, 258,186 features statewide. Ownership attribute unpopulated on 78% of records statewide and effectively absent in Ravalli and Missoula counties. RoadClass proved unreliable as a proxy: 45% of privately-owned roads in the populated subset are classed Local. Not used for bridge derivation; retained in raw for possible use in walk-in access modeling.'
);