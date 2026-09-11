ALTER TABLE model.data_sources ADD COLUMN raw_table text;

UPDATE model.data_sources SET raw_table = 'wbd_huc8'          WHERE layer_name = 'wbd_region17';
UPDATE model.data_sources SET raw_table = 'nhd_flowline'      WHERE layer_name = 'nhdplus_hr_1701';
UPDATE model.data_sources SET raw_table = 'nhd_waterbody'     WHERE layer_name = 'nhd_waterbody';
UPDATE model.data_sources SET raw_table = 'nhd_area'          WHERE layer_name = 'nhd_area';
UPDATE model.data_sources SET raw_table = 'nbi'               WHERE layer_name = 'nbi';
UPDATE model.data_sources SET raw_table = 'roads'             WHERE layer_name = 'msdi_transportation';
UPDATE model.data_sources SET raw_table = 'parcels_ravalli'   WHERE layer_name = 'parcels_ravalli';
UPDATE model.data_sources SET raw_table = 'parcels_missoula'  WHERE layer_name = 'parcels_missoula';
UPDATE model.data_sources SET raw_table = 'public_lands'      WHERE layer_name = 'public_lands';
UPDATE model.data_sources SET raw_table = 'fas_point'         WHERE layer_name = 'fas_point';
UPDATE model.data_sources SET raw_table = 'fas_poly'          WHERE layer_name = 'fas_poly';

-- VAA comes from the same download as the flowlines; separate row, same source.
INSERT INTO model.data_sources (layer_name, raw_table, source_agency, source_url, native_crs, native_format, license, retrieved_on, notes)
SELECT 'nhdplus_hr_1701_vaa', 'nhd_flowline_vaa', source_agency, source_url, 'n/a (table)', native_format, license, retrieved_on,
       'Value-added attributes from the same HUC4 1701 download. 337,153 rows vs 339,214 flowlines; 2,061 flowlines fall outside the connected network.'
FROM model.data_sources WHERE layer_name = 'nhdplus_hr_1701';