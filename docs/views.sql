-- Road Traffic Accidents (STATS19) 2009-2013 – North Yorkshire
-- SQL VIEW definitions created in DBRepo via the REST API (t2_4_views.ipynb).
-- These are the actual views registered in DBRepo. DBRepo's QueryDefinition API
-- supports SELECT with JOINs and WHERE filters; GROUP BY aggregations are not
-- expressible through the API and are therefore omitted here.
--
-- Join chain: accident → output_area → local_authority_district
--
-- output_area carries lad12_code directly (denormalised) so that the join chain
-- is only 2 levels deep. DBRepo's SQL generator does not support 3-level join
-- chains where an intermediate table column is referenced in a later ON clause.
--
-- All five views share the same 25-column projection.


-- ============================================================
-- VIEW 1: ml_accident_features
-- Full de-normalised feature table for ML training.
-- One row per accident. Contains all coded attribute columns from the
-- accident fact table plus rural/urban flag, area size, and local
-- authority district name resolved from the geographic hierarchy.
-- Use as the primary training dataset.
-- ============================================================
CREATE OR REPLACE VIEW ml_accident_features AS
SELECT
    a.police_ref,
    a.accident_date,
    a.accident_time,
    a.day_of_week,
    a.easting,
    a.northing,
    a.longitude,
    a.latitude,
    a.severity_id,
    a.road_cond_id,
    a.light_condition_id,
    a.weather_condition_id,
    a.special_condition_id,
    a.carriageway_hazard_id,
    a.road_type_id,
    a.speed_limit_mph,
    a.junction_detail_id,
    a.junction_control_id,
    a.crossing_control_id,
    a.crossing_facility_id,
    a.casualties,
    a.vehicles,
    oa.rural_urban,
    oa.area_hectares,
    lad.lad_name
FROM accident a
INNER JOIN output_area              oa   ON a.oa11_code    = oa.oa11_code
INNER JOIN local_authority_district lad  ON oa.lad12_code  = lad.lad12_code;


-- ============================================================
-- VIEW 2: ml_fatal_accidents
-- Fatal accidents only (severity_id = 1).
-- Fatal is the most under-represented class (~3% of records).
-- Use this view to apply oversampling (e.g. SMOTE) when training
-- a severity classifier.
-- ============================================================
CREATE OR REPLACE VIEW ml_fatal_accidents AS
SELECT
    a.police_ref, a.accident_date, a.accident_time, a.day_of_week,
    a.easting, a.northing, a.longitude, a.latitude,
    a.severity_id, a.road_cond_id, a.light_condition_id,
    a.weather_condition_id, a.special_condition_id, a.carriageway_hazard_id,
    a.road_type_id, a.speed_limit_mph,
    a.junction_detail_id, a.junction_control_id,
    a.crossing_control_id, a.crossing_facility_id,
    a.casualties, a.vehicles,
    oa.rural_urban, oa.area_hectares, lad.lad_name
FROM accident a
INNER JOIN output_area              oa   ON a.oa11_code   = oa.oa11_code
INNER JOIN local_authority_district lad  ON oa.lad12_code = lad.lad12_code
WHERE a.severity_id = 1;


-- ============================================================
-- VIEW 3: ml_serious_accidents
-- Serious accidents only (severity_id = 2).
-- Together with ml_fatal_accidents provides the two minority
-- classes for class-balancing strategies.
-- ============================================================
CREATE OR REPLACE VIEW ml_serious_accidents AS
SELECT
    a.police_ref, a.accident_date, a.accident_time, a.day_of_week,
    a.easting, a.northing, a.longitude, a.latitude,
    a.severity_id, a.road_cond_id, a.light_condition_id,
    a.weather_condition_id, a.special_condition_id, a.carriageway_hazard_id,
    a.road_type_id, a.speed_limit_mph,
    a.junction_detail_id, a.junction_control_id,
    a.crossing_control_id, a.crossing_facility_id,
    a.casualties, a.vehicles,
    oa.rural_urban, oa.area_hectares, lad.lad_name
FROM accident a
INNER JOIN output_area              oa   ON a.oa11_code   = oa.oa11_code
INNER JOIN local_authority_district lad  ON oa.lad12_code = lad.lad12_code
WHERE a.severity_id = 2;


-- ============================================================
-- VIEW 4: ml_rural_accidents
-- Accidents in rural output areas (rural_urban = 'Rural').
-- Rural and urban accidents differ in speed limits, road types,
-- and severity rates. Use for rural-specific model training or
-- geographic stratification.
-- ============================================================
CREATE OR REPLACE VIEW ml_rural_accidents AS
SELECT
    a.police_ref, a.accident_date, a.accident_time, a.day_of_week,
    a.easting, a.northing, a.longitude, a.latitude,
    a.severity_id, a.road_cond_id, a.light_condition_id,
    a.weather_condition_id, a.special_condition_id, a.carriageway_hazard_id,
    a.road_type_id, a.speed_limit_mph,
    a.junction_detail_id, a.junction_control_id,
    a.crossing_control_id, a.crossing_facility_id,
    a.casualties, a.vehicles,
    oa.rural_urban, oa.area_hectares, lad.lad_name
FROM accident a
INNER JOIN output_area              oa   ON a.oa11_code   = oa.oa11_code
INNER JOIN local_authority_district lad  ON oa.lad12_code = lad.lad12_code
WHERE oa.rural_urban = 'Rural';


-- ============================================================
-- VIEW 5: ml_high_speed_accidents
-- Accidents on roads with posted speed limit >= 60 mph.
-- High-speed roads have a higher fatality rate and fewer
-- junction-related accidents. Use for speed-limit-conditioned
-- analysis or as a stratified evaluation slice.
-- ============================================================
CREATE OR REPLACE VIEW ml_high_speed_accidents AS
SELECT
    a.police_ref, a.accident_date, a.accident_time, a.day_of_week,
    a.easting, a.northing, a.longitude, a.latitude,
    a.severity_id, a.road_cond_id, a.light_condition_id,
    a.weather_condition_id, a.special_condition_id, a.carriageway_hazard_id,
    a.road_type_id, a.speed_limit_mph,
    a.junction_detail_id, a.junction_control_id,
    a.crossing_control_id, a.crossing_facility_id,
    a.casualties, a.vehicles,
    oa.rural_urban, oa.area_hectares, lad.lad_name
FROM accident a
INNER JOIN output_area              oa   ON a.oa11_code   = oa.oa11_code
INNER JOIN local_authority_district lad  ON oa.lad12_code = lad.lad12_code
WHERE a.speed_limit_mph >= 60;
