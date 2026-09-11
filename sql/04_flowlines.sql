-- Flowlines clipped to the Bitterroot study area, reprojected to EPSG:32100.
-- Excludes canals/ditches (336), pipelines (428), underground conduits (420).
-- Retains StreamRiver (460), ArtificialPath (558), Connector (334).

DROP TABLE IF EXISTS stage.flowline;

CREATE TABLE stage.flowline AS
SELECT
    f.gid,
    f.permanent_identifier,
    f.gnis_id,
    f.gnis_name,
    f.reachcode,
    f.ftype,
    f.fcode,
    f.lengthkm       AS source_lengthkm,
    f.nhdplusid::bigint AS nhdplusid,
    v.streamorde,
    v.streamleve,
    v.hydroseq,
    v.levelpathi,
    v.fromnode,
    v.tonode,
    v.totdasqkm,
    v.slope,
    ST_Transform(f.geom, 32100) AS geom
FROM raw.nhd_flowline f
LEFT JOIN raw.nhd_flowline_vaa v
       ON f.nhdplusid = v.nhdplusid
JOIN stage.study_area s
       ON ST_Intersects(f.geom, ST_Transform(s.geom, 4269))
WHERE f.ftype IN (460, 558, 334);

ALTER TABLE stage.flowline ADD PRIMARY KEY (gid);
CREATE INDEX flowline_geom_idx ON stage.flowline USING GIST (geom);
CREATE INDEX flowline_nhdplusid_idx ON stage.flowline (nhdplusid);
CREATE INDEX flowline_order_idx ON stage.flowline (streamorde);

COMMENT ON TABLE stage.flowline IS
  'NHDPlus HR flowlines within HUC8 17010205, EPSG:32100. Canals, pipelines, and conduits excluded.';