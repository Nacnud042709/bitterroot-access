-- Reach classification combining access distance with bank ownership.
--
-- model.reach_access answers "how far along the channel from a legal entry".
-- It says nothing about who owns the bank once you are there, and the two are
-- different questions. A reach 400 m from an entry with public land on both
-- banks is a different proposition from one 400 m from an entry where both
-- banks are private -- in the second case the stream access law still permits
-- use of the water up to the ordinary high-water mark, but there may be no dry
-- ground to stand on and no way to leave the channel.
--
-- Bank ownership comes from model.channel_segment, which attributes the
-- NHDArea polygon boundary by parcel. Segments are matched to reaches within
-- 100 m -- wide enough to catch both banks on a channel up to ~100 m across,
-- narrow enough to avoid picking up the far bank of a parallel side channel in
-- braided sections.
--
-- WHY ONLY A PROPORTION IS REPORTED
-- Bank length per reach is not reported as an absolute figure. Segments are
-- matched within 100 m, and in braided sections a short reach picks up channel
-- edge belonging to neighbouring reaches and side channels: the median reach
-- reports 3.2x its own length in bank, the 90th percentile 19.8x, and the worst
-- case 137x. Clipping each segment to a 100 m buffer of the reach reduces this
-- but does not eliminate it, because the surrounding channel edge genuinely
-- falls within that buffer.
--
-- The proportion is robust where the absolute length is not, since numerator
-- and denominator are inflated together. Reclassifying with clipped rather than
-- unclipped lengths moved the mainstem result by under 1 km in each class.
-- Only bank_open_pct and bank_class are published.
--
-- A correct absolute measure would require attributing bank to the nearest
-- reach exclusively rather than by proximity -- a Voronoi partition of the
-- channel margin against reach midpoints, or linear referencing each segment
-- onto the network. Recorded as future work.

DROP TABLE IF EXISTS model.reach_full;

CREATE TABLE model.reach_full AS
WITH clipped AS (
    -- Clip each matched segment to the reach neighbourhood once, so the
    -- FILTER aggregates below do not each recompute the intersection.
    SELECT
        r.edge_id,
        c.access_regime,
        ST_Length(ST_Intersection(c.geom, ST_Buffer(r.geom, 100))) AS seg_m
    FROM model.reach_access r
    JOIN model.channel_segment c
           ON c.ring_type = 'outer'
          AND ST_DWithin(r.geom, c.geom, 100)
),
bank AS (
    SELECT
        edge_id,
        SUM(seg_m) FILTER (WHERE access_regime = 'open')       AS open_m,
        SUM(seg_m) FILTER (WHERE access_regime = 'n/a')        AS private_m,
        SUM(seg_m) FILTER (WHERE access_regime = 'row')        AS row_m,
        SUM(seg_m) FILTER (WHERE access_regime = 'licensed')   AS licensed_m,
        SUM(seg_m) FILTER (WHERE access_regime = 'restricted') AS restricted_m,
        SUM(seg_m) FILTER (WHERE access_regime = 'municipal')  AS municipal_m,
        SUM(seg_m)                                             AS total_bank_m
    FROM clipped
    GROUP BY edge_id
)
SELECT
    r.edge_id,
    r.gnis_name,
    r.streamorde,
    r.length_m,
    r.dist_to_access_m,
    r.access_class,
    ROUND((COALESCE(b.open_m, 0) / NULLIF(b.total_bank_m, 0) * 100)::numeric, 0)
                                                   AS bank_open_pct,
    CASE
        WHEN b.total_bank_m IS NULL                        THEN NULL
        WHEN COALESCE(b.open_m, 0) / b.total_bank_m >= 0.8 THEN 'public bank'
        WHEN COALESCE(b.open_m, 0) / b.total_bank_m >= 0.2 THEN 'mixed bank'
        ELSE                                                    'private bank'
    END                                            AS bank_class,
    r.geom
FROM model.reach_access r
LEFT JOIN bank b USING (edge_id);

ALTER TABLE model.reach_full ADD PRIMARY KEY (edge_id);
CREATE INDEX reach_full_geom_idx   ON model.reach_full USING GIST (geom);
CREATE INDEX reach_full_access_idx ON model.reach_full (access_class);
CREATE INDEX reach_full_bank_idx   ON model.reach_full (bank_class);

COMMENT ON TABLE model.reach_full IS
  'Reaches classified by along-channel distance to legal entry and by outer-bank ownership. Bank lengths are clipped to a 100 m buffer of each reach. Models legal walkability only. See sql/26_reach_full.sql.';