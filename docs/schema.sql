-- Road Traffic Accidents (STATS19) 2009–2013 – North Yorkshire
-- Relational Database Schema in Third Normal Form (3NF)
-- Source: UK Department for Transport STATS19 reporting system
--
--
-- Notes on column consolidation (CSV → schema):
--   • LAD11CD is identical to LAD12CD on every row → consolidated to lad12_code.
--   • LAD11NM is identical to LAD12NM on every row → consolidated to lad_name.
--   • Local_Auth is identical to LAD12CD on every row → not stored separately.
--   • LAD12NMW is empty (0 non-null rows out of 8358) → omitted.
--
-- Notes on coded fields:
--   • A code value of 0 appears in several CSV columns (Road_cond, Spcond,
--     Carr_haz, Junct_det, Junct_ctrl, Cross_ctrl, Cross_fac, Road_type)
--     which the official codebook lists as the NaN ("Not applicable") row.
--     We materialise this as code 0 with description 'Not applicable' so
--     that every CSV value resolves to a lookup row.

-- SECTION 1: LOOKUP / REFERENCE TABLES

CREATE TABLE severity_type (
    severity_id   SMALLINT    NOT NULL,
    description   VARCHAR(64) NOT NULL,
    CONSTRAINT pk_severity_type PRIMARY KEY (severity_id)
);
INSERT INTO severity_type VALUES
    (1, 'Fatal'),
    (2, 'Serious'),
    (3, 'Slight'),
    (4, 'Damage only');   -- in codebook; not present in this 2009–2013 subset


CREATE TABLE road_surface_condition (
    condition_id  SMALLINT    NOT NULL,
    description   VARCHAR(64) NOT NULL,
    CONSTRAINT pk_road_surface_condition PRIMARY KEY (condition_id)
);
INSERT INTO road_surface_condition VALUES
    (0, 'Not applicable'),
    (1, 'Dry'),
    (2, 'Wet or damp'),
    (3, 'Snow'),
    (4, 'Frost or ice'),
    (5, 'Flood'),
    (9, 'Unknown');


CREATE TABLE light_condition (
    condition_id  SMALLINT    NOT NULL,
    description   VARCHAR(80) NOT NULL,
    CONSTRAINT pk_light_condition PRIMARY KEY (condition_id)
);
INSERT INTO light_condition VALUES
    (1,  'Daylight'),
    (4,  'Darkness: street lights present and lit'),
    (5,  'Darkness: street lights present but unlit'),
    (6,  'Darkness: no street lighting'),
    (7,  'Darkness: street lighting unknown'),
    (10, 'Not applicable (pre-2011)'),
    (11, 'Daylight: street lights present (pre-2011)'),
    (12, 'Daylight: no street lighting (pre-2011)'),
    (13, 'Daylight: street lighting unknown (pre-2011)');


CREATE TABLE weather_condition (
    condition_id  SMALLINT    NOT NULL,
    description   VARCHAR(64) NOT NULL,
    CONSTRAINT pk_weather_condition PRIMARY KEY (condition_id)
);
INSERT INTO weather_condition VALUES
    (0, 'Not applicable'),
    (1, 'Fine without high winds'),
    (2, 'Raining without high winds'),
    (3, 'Snowing without high winds'),
    (4, 'Fine with high winds'),
    (5, 'Raining with high winds'),
    (6, 'Snowing with high winds'),
    (7, 'Fog or mist'),
    (8, 'Other'),
    (9, 'Unknown');


CREATE TABLE special_condition_at_site (
    condition_id  SMALLINT    NOT NULL,
    description   VARCHAR(80) NOT NULL,
    CONSTRAINT pk_special_condition PRIMARY KEY (condition_id)
);
INSERT INTO special_condition_at_site VALUES
    (0, 'Not applicable'),
    (1, 'Automatic traffic signal out'),
    (2, 'Automatic traffic signal partially defective'),
    (3, 'Permanent road signing or marking defective or obscured'),
    (4, 'Road works'),
    (5, 'Road surface defective'),
    (6, 'Oil or diesel'),
    (7, 'Mud'),
    (9, 'Unknown');


CREATE TABLE carriageway_hazard (
    hazard_id     SMALLINT    NOT NULL,
    description   VARCHAR(64) NOT NULL,
    CONSTRAINT pk_carriageway_hazard PRIMARY KEY (hazard_id)
);
INSERT INTO carriageway_hazard VALUES
    (0, 'Not applicable'),
    (1, 'Dislodged vehicle load in carriageway'),
    (2, 'Other object in carriageway'),
    (3, 'Involved with previous accident'),
    (6, 'Pedestrian in carriageway – not injured'),
    (7, 'Any animal in carriageway (except ridden horse)'),
    (9, 'Unknown');


CREATE TABLE road_type (
    type_id       SMALLINT    NOT NULL,
    description   VARCHAR(48) NOT NULL,
    CONSTRAINT pk_road_type PRIMARY KEY (type_id)
);
INSERT INTO road_type VALUES
    (0, 'Not coded'),
    (1, 'Roundabout'),
    (2, 'One way street'),
    (3, 'Dual carriageway'),
    (6, 'Single carriageway'),
    (7, 'Slip road'),
    (9, 'Unknown');


CREATE TABLE road_class (
    class_id      SMALLINT    NOT NULL,
    description   VARCHAR(48) NOT NULL,
    CONSTRAINT pk_road_class PRIMARY KEY (class_id)
);
INSERT INTO road_class VALUES
    (1, 'Motorway'),
    (2, 'A(M)'),
    (3, 'A road'),
    (4, 'B road'),
    (5, 'C road'),
    (6, 'Unclassified'),
    (9, 'Unknown');


CREATE TABLE junction_detail (
    detail_id     SMALLINT    NOT NULL,
    description   VARCHAR(64) NOT NULL,
    CONSTRAINT pk_junction_detail PRIMARY KEY (detail_id)
);
INSERT INTO junction_detail VALUES
    (0,  'Not within 20 metres'),
    (1,  'Roundabout'),
    (2,  'Mini roundabout'),
    (3,  'T or staggered junction'),
    (5,  'Slip road'),
    (6,  'Crossroads'),
    (7,  'Junction – more than 4 arms (not a roundabout)'),
    (8,  'Private drive or entrance'),
    (9,  'Other junction'),
    (99, 'Unknown');


CREATE TABLE junction_control (
    control_id    SMALLINT    NOT NULL,
    description   VARCHAR(64) NOT NULL,
    CONSTRAINT pk_junction_control PRIMARY KEY (control_id)
);
INSERT INTO junction_control VALUES
    (0, 'Not at junction'),
    (1, 'Authorised person'),
    (2, 'Automatic traffic signal'),
    (3, 'Stop sign'),
    (4, 'Give way or controlled'),
    (9, 'Unknown');


CREATE TABLE pedestrian_crossing_control (
    control_id    SMALLINT    NOT NULL,
    description   VARCHAR(80) NOT NULL,
    CONSTRAINT pk_ped_crossing_control PRIMARY KEY (control_id)
);
INSERT INTO pedestrian_crossing_control VALUES
    (0, 'None within 50 metres / not controlled'),
    (1, 'Controlled by school crossing patrol'),
    (2, 'Controlled by other authorised person'),
    (9, 'Unknown');


CREATE TABLE pedestrian_crossing_facility (
    facility_id   SMALLINT    NOT NULL,
    description   VARCHAR(80) NOT NULL,
    CONSTRAINT pk_ped_crossing_facility PRIMARY KEY (facility_id)
);
INSERT INTO pedestrian_crossing_facility VALUES
    (0, 'No crossing facility within 50 metres'),
    (1, 'Zebra crossing'),
    (4, 'Pelican or puffin crossing'),
    (5, 'Pedestrian phase at traffic signal junction'),
    (7, 'Footbridge or subway'),
    (8, 'Central refuge – no other controls'),
    (9, 'Unknown');


CREATE TABLE reporting_authority (
    authority_id  SMALLINT    NOT NULL,
    description   VARCHAR(80) NOT NULL,
    CONSTRAINT pk_reporting_authority PRIMARY KEY (authority_id)
);
INSERT INTO reporting_authority VALUES
    (1, 'Yes – reported at the scene'),
    (2, 'No – accident reported over the counter'),
    (3, 'No – accident reported using a self-completion form');


-- SECTION 2: ADMINISTRATIVE GEOGRAPHY HIERARCHY

CREATE TABLE police_force (
    force_id      SMALLINT     NOT NULL,
    force_name    VARCHAR(128) NOT NULL,
    CONSTRAINT pk_police_force PRIMARY KEY (force_id)
);
INSERT INTO police_force VALUES (12, 'North Yorkshire Police');


CREATE TABLE local_authority_district (
    lad12_code      VARCHAR(9)   NOT NULL,
    lad12_code_old  VARCHAR(8)   NOT NULL,
    lad_name        VARCHAR(128) NOT NULL,
    CONSTRAINT pk_local_authority_district PRIMARY KEY (lad12_code)
);


CREATE TABLE lower_super_output_area (
    lsoa_id       SMALLINT     NOT NULL,
    lsoa_name     VARCHAR(32)  NOT NULL,
    lad12_code    VARCHAR(9)   NOT NULL,
    CONSTRAINT pk_lsoa     PRIMARY KEY (lsoa_id),
    CONSTRAINT fk_lsoa_lad FOREIGN KEY (lad12_code)
                           REFERENCES local_authority_district(lad12_code)
);


CREATE TABLE output_area (
    oa11_code            VARCHAR(9)    NOT NULL,
    lsoa_id              SMALLINT      NOT NULL,
    area_hectares        NUMERIC(10,4) NOT NULL,
    rurality_code        VARCHAR(4)    NOT NULL,
    rurality_description VARCHAR(16)   NOT NULL,
    rural_urban          VARCHAR(8)    NOT NULL,
    CONSTRAINT pk_output_area  PRIMARY KEY (oa11_code),
    CONSTRAINT fk_oa_lsoa      FOREIGN KEY (lsoa_id)
                               REFERENCES lower_super_output_area(lsoa_id),
    CONSTRAINT chk_rural_urban CHECK (rural_urban IN ('Rural', 'Urban'))
);


-- SECTION 3: MAIN FACT TABLE

CREATE TABLE accident (
    police_ref              BIGINT        NOT NULL,
    accident_date           DATE          NOT NULL,
    accident_time           TIME          NOT NULL,
    day_of_week             SMALLINT      NOT NULL,  -- 1=Sunday … 7=Saturday
    easting                 INTEGER       NOT NULL,
    northing                INTEGER       NOT NULL,
    longitude               NUMERIC(10,7) NOT NULL,
    latitude                NUMERIC(10,7) NOT NULL,
    severity_id             SMALLINT      NOT NULL,
    road_cond_id            SMALLINT      NOT NULL,
    light_condition_id      SMALLINT      NOT NULL,
    weather_condition_id    SMALLINT      NOT NULL,
    special_condition_id    SMALLINT      NOT NULL,
    carriageway_hazard_id   SMALLINT      NOT NULL,
    casualties              SMALLINT      NOT NULL,
    vehicles                SMALLINT      NOT NULL,
    road_type_id            SMALLINT      NOT NULL,
    speed_limit_mph         SMALLINT      NOT NULL,
    junction_detail_id      SMALLINT      NOT NULL,
    junction_control_id     SMALLINT      NOT NULL,
    crossing_control_id     SMALLINT      NOT NULL,
    crossing_facility_id    SMALLINT      NOT NULL,
    force_id                SMALLINT      NOT NULL,
    oa11_code               VARCHAR(9)    NOT NULL,
    reporting_authority_id  SMALLINT      NOT NULL,

    CONSTRAINT pk_accident                  PRIMARY KEY (police_ref),
    CONSTRAINT fk_accident_severity         FOREIGN KEY (severity_id)
                                            REFERENCES severity_type(severity_id),
    CONSTRAINT fk_accident_road_surface     FOREIGN KEY (road_cond_id)
                                            REFERENCES road_surface_condition(condition_id),
    CONSTRAINT fk_accident_light            FOREIGN KEY (light_condition_id)
                                            REFERENCES light_condition(condition_id),
    CONSTRAINT fk_accident_weather          FOREIGN KEY (weather_condition_id)
                                            REFERENCES weather_condition(condition_id),
    CONSTRAINT fk_accident_special_cond     FOREIGN KEY (special_condition_id)
                                            REFERENCES special_condition_at_site(condition_id),
    CONSTRAINT fk_accident_carr_haz         FOREIGN KEY (carriageway_hazard_id)
                                            REFERENCES carriageway_hazard(hazard_id),
    CONSTRAINT fk_accident_road_type        FOREIGN KEY (road_type_id)
                                            REFERENCES road_type(type_id),
    CONSTRAINT fk_accident_junct_detail     FOREIGN KEY (junction_detail_id)
                                            REFERENCES junction_detail(detail_id),
    CONSTRAINT fk_accident_junct_control    FOREIGN KEY (junction_control_id)
                                            REFERENCES junction_control(control_id),
    CONSTRAINT fk_accident_cross_ctrl       FOREIGN KEY (crossing_control_id)
                                            REFERENCES pedestrian_crossing_control(control_id),
    CONSTRAINT fk_accident_cross_fac        FOREIGN KEY (crossing_facility_id)
                                            REFERENCES pedestrian_crossing_facility(facility_id),
    CONSTRAINT fk_accident_force            FOREIGN KEY (force_id)
                                            REFERENCES police_force(force_id),
    CONSTRAINT fk_accident_oa               FOREIGN KEY (oa11_code)
                                            REFERENCES output_area(oa11_code),
    CONSTRAINT fk_accident_reporting        FOREIGN KEY (reporting_authority_id)
                                            REFERENCES reporting_authority(authority_id),
    CONSTRAINT chk_day_of_week              CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_speed_limit              CHECK (speed_limit_mph IN (20, 30, 40, 50, 60, 70)),
    CONSTRAINT chk_casualties               CHECK (casualties >= 0),
    CONSTRAINT chk_vehicles                 CHECK (vehicles >= 1)
);


-- SECTION 4: ROAD INVOLVEMENT (extracted repeating group)
-- The source CSV stores up to two roads per accident (Road 1 and Road 2).
-- Modelling as a child table avoids the 1NF violation of two paired columns.

CREATE TABLE accident_road (
    accident_road_id  SERIAL       NOT NULL,
    police_ref        BIGINT       NOT NULL,
    road_sequence     SMALLINT     NOT NULL,  -- 1 = first road, 2 = second road
    road_class_id     SMALLINT     NOT NULL,
    road_number       INTEGER      NOT NULL,  -- 0 = unclassified / no number

    CONSTRAINT pk_accident_road     PRIMARY KEY (accident_road_id),
    CONSTRAINT uq_accident_road_seq UNIQUE (police_ref, road_sequence),
    CONSTRAINT fk_ar_accident       FOREIGN KEY (police_ref)
                                    REFERENCES accident(police_ref),
    CONSTRAINT fk_ar_road_class     FOREIGN KEY (road_class_id)
                                    REFERENCES road_class(class_id),
    CONSTRAINT chk_road_sequence    CHECK (road_sequence IN (1, 2))
);
