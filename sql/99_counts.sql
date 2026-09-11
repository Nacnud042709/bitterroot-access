-- Row counts across stage. Run before and after a pipeline rebuild to
-- verify reproducibility.

SELECT 'study_area'  AS t, COUNT(*) FROM stage.study_area
UNION ALL SELECT 'flowline',    COUNT(*) FROM stage.flowline
UNION ALL SELECT 'waterbody',   COUNT(*) FROM stage.waterbody
UNION ALL SELECT 'nhd_area',    COUNT(*) FROM stage.nhd_area
UNION ALL SELECT 'parcel',      COUNT(*) FROM stage.parcel
UNION ALL SELECT 'public_land', COUNT(*) FROM stage.public_land
UNION ALL SELECT 'fas_point',   COUNT(*) FROM stage.fas_point
UNION ALL SELECT 'fas_poly',    COUNT(*) FROM stage.fas_poly
UNION ALL SELECT 'bridge',      COUNT(*) FROM stage.bridge
ORDER BY 1;