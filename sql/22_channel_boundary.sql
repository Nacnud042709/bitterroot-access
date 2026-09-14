-- Channel margin segmented by parcel ownership.
--
-- CHANNEL EDGE SOURCE
-- Uses the NHDArea polygon boundary as the channel edge rather than a buffered
-- centerline. The original plan buffered the flowline and intersected with
-- parcels, but NHD maps the entire Bitterroot mainstem, both forks, and the
-- lower reaches of Lolo and Fred Burr as polygon channel with ArtificialPath
-- centerlines threading through. On a channel up to 100 m wide, a 30 m buffer
-- reaches neither bank.
--
-- Visual inspection confirmed the polygon boundary hugs the wetted channel
-- rather than enclosing the braid plain, making it a better proxy for the
-- ordinary high-water mark than any assumed buffer width.
--
-- OUTER BANK VS ISLAND SHORELINE
-- ST_Boundary returns interior rings as well as the exterior ring, so island
-- shorelines are included in the channel margin. These total 71.8 km against
-- 542.4 km of outer bank -- 12% of the 614.2 km total.
--
-- The distinction matters legally. Under the Montana Stream Access Law the
-- public may use the water up to the ordinary high-water mark regardless of
-- streambed ownership, so wading a side channel past an island is permitted.
-- But the vegetated island above the high-water mark is private property,
-- typically held by the adjacent landowner or the state. For the question
-- "where can a person reach and stand on the bank", outer bank is the
-- relevant measure.
--
-- Rather than filter, ring_type flags each segment so both figures remain
-- available and the choice stays explicit in downstream queries.
--
-- ST_DumpRings returns path index 0 for the exterior ring and 1+ for interior
-- rings, which is what the ring_type CASE keys on.
-- -- ST_DumpRings returns each ring as a closed POLYGON, not a LINESTRING, so
-- ST_ExteriorRing is applied to convert. Without it, ST_Intersection against
-- a parcel returns an area and ST_Length returns 0, silently dropping every
-- segment.

DROP TABLE IF EXISTS model.channel_segment;

CREATE TABLE model.channel_segment AS
WITH parts AS (
    -- Dump the unioned channel into individual polygons so rings can be
    -- attributed per polygon rather than across the whole union.
    SELECT (ST_Dump(ST_Union(geom))).geom AS poly
    FROM stage.nhd_area
),
rings AS (
    SELECT
        ST_ExteriorRing((d).geom)                             AS g,
        CASE WHEN (d).path[1] = 0 THEN 'outer' ELSE 'island' END AS ring_type
    FROM (SELECT ST_DumpRings(poly) AS d FROM parts) x
)
SELECT
    ROW_NUMBER() OVER ()                                       AS seg_id,
    a.parcel_uid,
    r.ring_type,
    a.ownership_class,
    a.access_regime,
    a.agency,
    ROUND(ST_Length(ST_Intersection(r.g, p.geom))::numeric, 1) AS length_m,
    ST_Multi(ST_Intersection(r.g, p.geom))                     AS geom
FROM rings r
JOIN stage.parcel p        ON ST_Intersects(r.g, p.geom)
JOIN model.parcel_access a USING (parcel_uid)
WHERE ST_Length(ST_Intersection(r.g, p.geom)) >= 5;

ALTER TABLE model.channel_segment ADD PRIMARY KEY (seg_id);
CREATE INDEX channel_segment_geom_idx   ON model.channel_segment USING GIST (geom);
CREATE INDEX channel_segment_regime_idx ON model.channel_segment (access_regime);
CREATE INDEX channel_segment_ring_idx   ON model.channel_segment (ring_type);

COMMENT ON TABLE model.channel_segment IS
  'Channel margin segmented by parcel ownership. Each segment is the portion of one NHDArea boundary ring falling within one parcel. ring_type distinguishes outer bank from island shoreline. See sql/22_channel_boundary.sql.';
