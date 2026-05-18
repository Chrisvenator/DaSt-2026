-- Road Traffic Accidents (STATS19) 2009–2013 – North Yorkshire
-- SQL VIEW definitions for DBRepo — ML pipeline query layer
-- Valid PostgreSQL syntax.
-- Generated: 2026-05-13


-- ============================================================
-- VIEW 1: ml_accident_features
-- Flat, fully-decoded feature table ready for ML ingestion.
-- One row per accident. Every FK is resolved to its human-readable
-- label; the raw numeric ID is kept alongside for ordinal encoding.
-- Derived temporal columns (year, month, hour) are pre-computed.
-- Primary road class comes from accident_road (road_sequence = 1).
-- ============================================================
CREATE OR REPLACE VIEW ml_accident_features AS
SELECT
    -- identity
    a.police_ref,
    a.accident_date,
    a.accident_time,

    -- derived temporal features
    EXTRACT(YEAR  FROM a.accident_date)::SMALLINT  AS accident_year,
    EXTRACT(MONTH FROM a.accident_date)::SMALLINT  AS accident_month,
    EXTRACT(HOUR  FROM a.accident_time)::SMALLINT  AS hour_of_day,
    a.day_of_week,

    -- spatial
    a.longitude,
    a.latitude,
    a.easting,
    a.northing,

    -- geographic context
    oa.rural_urban,
    oa.area_hectares,
    lad.lad_name,

    -- target variable
    a.severity_id,
    st.description                                      AS severity_label,

    -- environmental conditions
    a.road_cond_id,
    rsc.description                                     AS road_surface_label,
    a.light_condition_id,
    lc.description                                      AS light_label,
    a.weather_condition_id,
    wc.description                                      AS weather_label,
    a.special_condition_id,
    sc.description                                      AS special_condition_label,
    a.carriageway_hazard_id,
    ch.description                                      AS carriageway_hazard_label,

    -- road geometry
    a.road_type_id,
    rt.description                                      AS road_type_label,
    a.speed_limit_mph,

    -- junction
    a.junction_detail_id,
    jd.description                                      AS junction_detail_label,
    a.junction_control_id,
    jc.description                                      AS junction_control_label,

    -- pedestrian crossing
    a.crossing_control_id,
    pcc.description                                     AS crossing_control_label,
    a.crossing_facility_id,
    pcf.description                                     AS crossing_facility_label,

    -- primary road (road_sequence = 1; NULL when no road record exists)
    ar1.road_class_id                                   AS primary_road_class_id,
    rc1.description                                     AS primary_road_class_label,
    ar1.road_number                                     AS primary_road_number,

    -- counts
    a.casualties,
    a.vehicles

FROM accident a
JOIN severity_type                 st   ON st.severity_id    = a.severity_id
JOIN road_surface_condition        rsc  ON rsc.condition_id  = a.road_cond_id
JOIN light_condition               lc   ON lc.condition_id   = a.light_condition_id
JOIN weather_condition             wc   ON wc.condition_id   = a.weather_condition_id
JOIN special_condition_at_site     sc   ON sc.condition_id   = a.special_condition_id
JOIN carriageway_hazard            ch   ON ch.hazard_id      = a.carriageway_hazard_id
JOIN road_type                     rt   ON rt.type_id        = a.road_type_id
JOIN junction_detail               jd   ON jd.detail_id      = a.junction_detail_id
JOIN junction_control              jc   ON jc.control_id     = a.junction_control_id
JOIN pedestrian_crossing_control   pcc  ON pcc.control_id    = a.crossing_control_id
JOIN pedestrian_crossing_facility  pcf  ON pcf.facility_id   = a.crossing_facility_id
JOIN output_area                   oa   ON oa.oa11_code       = a.oa11_code
JOIN lower_super_output_area       lsoa ON lsoa.lsoa_id      = oa.lsoa_id
JOIN local_authority_district      lad  ON lad.lad12_code    = lsoa.lad12_code
LEFT JOIN accident_road            ar1  ON ar1.police_ref     = a.police_ref
                                       AND ar1.road_sequence  = 1
LEFT JOIN road_class               rc1  ON rc1.class_id       = ar1.road_class_id;


-- ============================================================
-- VIEW 2: accident_severity_class_counts
-- Per-severity accident count, percentage share of total, and
-- mean casualties/vehicles per accident.
-- Use this to assess class imbalance before training a classifier.
-- ============================================================
CREATE OR REPLACE VIEW accident_severity_class_counts AS
SELECT
    a.severity_id,
    st.description                                           AS severity_label,
    COUNT(*)                                                 AS accident_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    )                                                        AS pct_of_total,
    ROUND(AVG(a.casualties)::NUMERIC, 3)                     AS avg_casualties,
    ROUND(AVG(a.vehicles)::NUMERIC,   3)                     AS avg_vehicles
FROM accident a
JOIN severity_type st ON st.severity_id = a.severity_id
GROUP BY a.severity_id, st.description
ORDER BY a.severity_id;


-- ============================================================
-- VIEW 3: accidents_by_road_type
-- Accident totals grouped by road geometry type, with per-severity
-- sub-counts and a fatality rate percentage.
-- Useful for road-safety reporting and feature importance analysis.
-- ============================================================
CREATE OR REPLACE VIEW accidents_by_road_type AS
SELECT
    a.road_type_id,
    rt.description                                           AS road_type_label,
    COUNT(*)                                                 AS accident_count,
    SUM(CASE WHEN a.severity_id = 1 THEN 1 ELSE 0 END)      AS fatal_count,
    SUM(CASE WHEN a.severity_id = 2 THEN 1 ELSE 0 END)      AS serious_count,
    SUM(CASE WHEN a.severity_id = 3 THEN 1 ELSE 0 END)      AS slight_count,
    ROUND(
        SUM(CASE WHEN a.severity_id = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    )                                                        AS fatality_rate_pct,
    SUM(a.casualties)                                        AS total_casualties
FROM accident a
JOIN road_type rt ON rt.type_id = a.road_type_id
GROUP BY a.road_type_id, rt.description
ORDER BY accident_count DESC;


-- ============================================================
-- VIEW 4: accidents_by_weather_condition
-- Accident counts and casualty statistics grouped by weather.
-- Supports analysis of environmental risk factors and evaluation
-- of weather as a predictive feature in the ML pipeline.
-- ============================================================
CREATE OR REPLACE VIEW accidents_by_weather_condition AS
SELECT
    a.weather_condition_id,
    wc.description                                           AS weather_label,
    COUNT(*)                                                 AS accident_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    )                                                        AS pct_of_total,
    SUM(CASE WHEN a.severity_id = 1 THEN 1 ELSE 0 END)      AS fatal_count,
    ROUND(AVG(a.casualties)::NUMERIC, 3)                     AS avg_casualties
FROM accident a
JOIN weather_condition wc ON wc.condition_id = a.weather_condition_id
GROUP BY a.weather_condition_id, wc.description
ORDER BY accident_count DESC;


-- ============================================================
-- VIEW 5: accidents_by_hour_of_day
-- Accident and casualty totals aggregated by hour of day (0–23).
-- Reveals daily risk patterns and supports time-of-day feature
-- engineering for the ML pipeline.
-- ============================================================
CREATE OR REPLACE VIEW accidents_by_hour_of_day AS
SELECT
    EXTRACT(HOUR FROM a.accident_time)::SMALLINT             AS hour_of_day,
    COUNT(*)                                                 AS accident_count,
    SUM(CASE WHEN a.severity_id = 1 THEN 1 ELSE 0 END)      AS fatal_count,
    SUM(CASE WHEN a.severity_id = 2 THEN 1 ELSE 0 END)      AS serious_count,
    SUM(a.casualties)                                        AS total_casualties,
    ROUND(AVG(a.casualties)::NUMERIC, 3)                     AS avg_casualties
FROM accident a
GROUP BY EXTRACT(HOUR FROM a.accident_time)
ORDER BY hour_of_day;
