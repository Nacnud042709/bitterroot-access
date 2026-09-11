INSERT INTO model.data_sources (
    layer_name, source_agency, source_url, native_crs,
    native_format, license, retrieved_on, update_cadence, notes
) VALUES (
    'wbd_region17',
    'USGS',
    'https://prd-tnm.s3.amazonaws.com/StagedProducts/Hydrography/WBD/HU2/GDB/WBD_17_HU2_GDB.zip',
    'EPSG:4269',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'periodic',
        'WBD HU-2 Region 17; published 2025-01-08; source for HUC8 17010205 Bitterroot study area boundary'
);