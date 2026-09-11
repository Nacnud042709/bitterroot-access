INSERT INTO model.data_sources (
    layer_name, source_agency, source_url, native_crs,
    native_format, license, retrieved_on, update_cadence, notes
) VALUES (
    'nhdplus_hr_1701',
    'USGS',
    'https://prd-tnm.s3.amazonaws.com/StagedProducts/Hydrography/NHDPlusHR/VPU/Current/GDB/NHDPLUS_H_1701_HU4_GDB.zip',
    'EPSG:4269',
    'FileGDB',
    'public domain',
    CURRENT_DATE,
    'periodic',
    'NHDPlus HR HUC4 1701; source for flowlines. Covers Bitterroot plus Blackfoot, Rock Creek, upper Clark Fork; clipped to study area on load to stage.'
);