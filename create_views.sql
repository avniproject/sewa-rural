set role sewa_rural;

--this table holds all the concepts used in report filter
create table sr_observations
(
    name    text,
    concept varchar(256)
);

insert into sr_observations
values ('Severe', 'Anemia Status');
insert into sr_observations
values ('Moderate', 'Anemia Status');
insert into sr_observations
values ('Mild', 'Anemia Status');
insert into sr_observations
values ('All', 'Anemia Status');
insert into sr_observations
values ('Normal', 'Anemia Status');
insert into sr_observations
values ('Yes', 'School going');
insert into sr_observations
values ('Dropped Out', 'School going');
insert into sr_observations
values ('All', 'School going');
insert into sr_observations
values ('Negative', 'Sickling Test Result');
insert into sr_observations
values ('Trait', 'Sickling Test Result');
insert into sr_observations
values ('Disease', 'Sickling Test Result');
insert into sr_observations
values ('All', 'Sickling Test Result');
insert into sr_observations
values ('All', 'Addiction Details');
insert into sr_observations
values ('Alcohol', 'Addiction Details');
insert into sr_observations
values ('Tobacco', 'Addiction Details');
insert into sr_observations
values ('Both', 'Addiction Details');
insert into sr_observations
values ('No Addiction', 'Addiction Details');
insert into sr_observations
values ('Lower abdominal pain', 'Menstrual disorders');
insert into sr_observations
values ('Backache', 'Menstrual disorders');
insert into sr_observations
values ('Leg pain', 'Menstrual disorders');
insert into sr_observations
values ('Nausea and vomiting', 'Menstrual disorders');
insert into sr_observations
values ('Headache', 'Menstrual disorders');
insert into sr_observations
values ('Abnormal vaginal discharge', 'Menstrual disorders');
insert into sr_observations
values ('Heavy bleeding', 'Menstrual disorders');
insert into sr_observations
values ('Irregular menses', 'Menstrual disorders');
insert into sr_observations
values ('No problem', 'Menstrual disorders');
insert into sr_observations
values ('All', 'Menstrual disorders');
insert into sr_observations
values ('Heart problem', 'Chronic Sickness');
insert into sr_observations
values ('Kidney problem', 'Chronic Sickness');
insert into sr_observations
values ('Sickle cell disease', 'Chronic Sickness');
insert into sr_observations
values ('Epilepsy', 'Chronic Sickness');
insert into sr_observations
values ('No problem', 'Chronic Sickness');
insert into sr_observations
values ('Other', 'Chronic Sickness');
insert into sr_observations
values ('All', 'Chronic Sickness');

drop view if exists anemia_status;
create view anemia_status as
(
select *
from sr_observations
where concept = 'Anemia Status');

drop view if exists school_going;
create view school_going as
(
select *
from sr_observations
where concept = 'School going');

drop view if exists sickling_result;
create view sickling_result as
(
select *
from sr_observations
where concept = 'Sickling Test Result');

drop view if exists addiction_details;
create view addiction_details as
(
select *
from sr_observations
where concept = 'Addiction Details');

drop view if exists menstrual_disorders;
create view menstrual_disorders as
(
select *
from sr_observations
where concept = 'Menstrual disorders');

drop view if exists chronic_sickness;
create view chronic_sickness as
(
select *
from sr_observations
where concept = 'Chronic Sickness');


------views and functions for drill down reports
create or replace view sr_individual_indicator_matrix as
(
with partitioned_annual as (
    SELECT i.id                                                                             individual_id,
           row_number() OVER (PARTITION BY i.id ORDER BY enc.encounter_date_time)           rank,
           encounter_date_time,
           cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT)       hb,
           single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc') hb_status,
           g.name                                                                           gender
    from program_encounter enc
             join encounter_type enct on enc.encounter_type_id = enct.id
             join program_enrolment enl on enc.program_enrolment_id = enl.id
             join operational_program_view op ON op.program_id = enl.program_id
             join individual i on enl.individual_id = i.id
             join gender g on i.gender_id = g.id
    WHERE op.program_name = 'Adolescent'
      AND enct.name = 'Annual Visit'
      AND enc.encounter_date_time NOTNULL
      and enc.is_voided = false
      and enl.program_exit_date_time ISNULL
      and enl.is_voided = false
      and i.is_voided = false
),
     baseline_data (individual_id, gender, hb, hb_status, baseline_year, visit_number, baseline_status,
                    endline_year)
         as (
         select individual_id,
                gender,
                hb,
                hb_status,
                extract('year' from encounter_date_time),
                0,
                'null'::TEXT,
                0
         from partitioned_annual
         where rank = 1
     ),
     midline_partitioned as (
         select enc.program_enrolment_id,
                enc.observations,
                encounter_date_time,
                row_number() OVER (PARTITION BY individual_id ORDER BY enc.encounter_date_time) rank
         from program_encounter_view enc
                  join program_enrolment enl on enc.program_enrolment_id = enl.id
         where encounter_type_name = 'Midline Visit'
           and enl.is_voided = false
           and enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     midline_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc'),
                baseline_year,
                1        visit_number,
                b.gender gender,
                baseline_year + 1
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join midline_partitioned enc on enc.program_enrolment_id = enl.id
             and extract('year' from encounter_date_time) = baseline_year + 1
             and rank = 1
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_1_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc'),
                baseline_year,
                2        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 2
                    else baseline_year + 1 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 1
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_2_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc'),
                baseline_year,
                3        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 3
                    else baseline_year + 2 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 2
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_3_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc'),
                baseline_year,
                4        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 4
                    else baseline_year + 3 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 3
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_4_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc'),
                baseline_year,
                5        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 5
                    else baseline_year + 4 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 4
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_5_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc'),
                baseline_year,
                6        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 6
                    else baseline_year + 5 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 5
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_6_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc'),
                baseline_year,
                7        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 7
                    else baseline_year + 6 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 6
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_7_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                single_select_coded(enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc'),
                baseline_year,
                8        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 8
                    else baseline_year + 7 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 7
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_data
         (individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year)
         as
         (select *
          from midline_data
          union all
          select *
          from endline_1_data
          union all
          select *
          from endline_2_data
          union all
          select *
          from endline_3_data
          union all
          select *
          from endline_4_data
          union all
          select *
          from endline_5_data
          union all
          select *
          from endline_6_data
          union all
          select *
          from endline_7_data
         ),
     endline_for_baseline_severe
         (individual_id, gender, hb, hb_status, baseline_year, visit_number, baseline_status, endline_year)
         as
         (select b.individual_id,
                 b.gender,
                 e.hb,
                 e.hb_status,
                 b.baseline_year,
                 e.visit_number,
                 'Severe'::TEXT,
                 e.endline_year
          from baseline_data b
                   join endline_data e on e.individual_id = b.individual_id
          where b.hb NOTNULL
            AND b.hb <= 7
         ),
     endline_for_baseline_moderate(individual_id, gender, hb, hb_status, baseline_year, visit_number,
                                   baseline_status, endline_year) as (
         select e.individual_id,
                b.gender,
                e.hb,
                e.hb_status,
                b.baseline_year,
                e.visit_number,
                'Moderate'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.hb NOTNULL
           AND b.hb BETWEEN 7.1 AND 10
     ),
     endline_for_baseline_mild(individual_id, gender, hb, hb_status, baseline_year, visit_number, baseline_status,
                               endline_year)
         as (
         select e.individual_id,
                b.gender,
                e.hb,
                e.hb_status,
                b.baseline_year,
                e.visit_number,
                'Mild'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.hb NOTNULL
           AND b.hb BETWEEN 10.1 AND 11.9
     ),
     endline_for_baseline_normal(individual_id, gender, hb, hb_status, baseline_year, visit_number, baseline_status,
                                 endline_year)
         as (
         select e.individual_id,
                b.gender,
                e.hb,
                e.hb_status,
                b.baseline_year,
                e.visit_number,
                'Normal'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.hb NOTNULL
           AND b.hb >= 12
     ),
     endline_for_baseline_missed(individual_id, gender, hb, hb_status, baseline_year, visit_number, baseline_status,
                                 endline_year) as (
         select e.individual_id,
                b.gender,
                e.hb,
                e.hb_status,
                b.baseline_year,
                e.visit_number,
                'Missed'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.hb ISNULL
     ),
     all_events as (select *
                    from baseline_data
                    union all
                    select *
                    from endline_for_baseline_normal
                    union all
                    select *
                    from endline_for_baseline_moderate
                    union all
                    select *
                    from endline_for_baseline_mild
                    union all
                    select *
                    from endline_for_baseline_severe
                    union all
                    select *
                    from endline_for_baseline_missed
     )

select individual_id,
       jsonb_build_object(
               'baselineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'null',
               'baselineModerate', hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'null',
               'baselineMild', hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'null',
               'baselineNormal', hb NOTNULL and hb >= 12 AND baseline_status = 'null',
               'baselineHBDone', hb_status = 'Done' AND baseline_status = 'null',
               'baselineHBNotDone', hb_status = 'Not Done' AND baseline_status = 'null',
               'baselineMissingHB', hb ISNULL AND baseline_status = 'null',
               'baselineSevereEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Severe',
               'baselineSevereEndlineModerate',
               hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Severe',
               'baselineSevereEndlineMild',
               hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Severe',
               'baselineSevereEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Severe',
               'baselineSevereEndlineHBDone', hb_status = 'Done' AND baseline_status = 'Severe',
               'baselineSevereEndlineHBNotDone', hb_status = 'Not Done' AND baseline_status = 'Severe',
               'baselineSevereEndlineMissingHB', hb ISNULL AND hb_status ISNULL AND baseline_status = 'Severe',
               'baselineModerateEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Moderate',
               'baselineModerateEndlineModerate',
               hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Moderate',
               'baselineModerateEndlineMild',
               hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Moderate',
               'baselineModerateEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Moderate',
               'baselineModerateEndlineHBDone', hb_status = 'Done' AND baseline_status = 'Moderate',
               'baselineModerateEndlineHBNotDone', hb_status = 'Not Done' AND baseline_status = 'Moderate',
               'baselineModerateEndlineMissingHB', hb ISNULL AND baseline_status = 'Moderate',
               'baselineMildEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Mild',
               'baselineMildEndlineModerate',
               hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Mild',
               'baselineMildEndlineMild',
               hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Mild',
               'baselineMildEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Mild',
               'baselineMildEndlineHBDone', hb_status = 'Done' AND baseline_status = 'Mild',
               'baselineMildEndlineHBNotDone', hb_status = 'Not Done' AND baseline_status = 'Mild',
               'baselineMildEndlineMissingHB', hb ISNULL AND baseline_status = 'Mild',
               'baselineNormalEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Normal',
               'baselineNormalEndlineModerate',
               hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Normal',
               'baselineNormalEndlineMild',
               hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Normal',
               'baselineNormalEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Normal',
               'baselineNormalEndlineHBDone', hb_status = 'Done' AND baseline_status = 'Normal',
               'baselineNormalEndlineHBNotDone', hb_status = 'Not Done' AND baseline_status = 'Normal',
               'baselineNormalEndlineMissingHB', hb ISNULL AND baseline_status = 'Normal',
               'baselineMissedEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Missed',
               'baselineMissedEndlineModerate',
               hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Missed',
               'baselineMissedEndlineMild',
               hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Missed',
               'baselineMissedEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Missed',
               'baselineMissedEndlineHBDone', hb_status = 'Done' AND baseline_status = 'Missed',
               'baselineMissedEndlineHBNotDone', hb_status = 'Not Done' AND baseline_status = 'Missed',
               'baselineMissedEndlineMissingHB', hb ISNULL AND baseline_status = 'Missed'
           ) as status_map,
       jsonb_build_object(
               'hb', hb
           ) as value_map,
       gender,
       baseline_year,
       visit_number,
       endline_year
from all_events
    );


------views and functions for Menstrual Hygiene Practices  reports
create or replace view sr_individual_menstrual_hygiene_indicator_matrix as
(
with partitioned_annual as (
    SELECT i.id                                                                           individual_id,
           row_number() OVER (PARTITION BY i.id ORDER BY enc.encounter_date_time)         rank,
           encounter_date_time,
           multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca') material,
           g.name                                                                         gender
    from program_encounter enc
             join encounter_type enct on enc.encounter_type_id = enct.id
             join program_enrolment enl on enc.program_enrolment_id = enl.id
             join operational_program_view op ON op.program_id = enl.program_id
             join individual i on enl.individual_id = i.id
             join gender g on i.gender_id = g.id
    WHERE op.program_name = 'Adolescent'
      AND enct.name = 'Annual Visit'
      AND enc.encounter_date_time NOTNULL
      and enc.is_voided = false
      and enl.program_exit_date_time ISNULL
      and enl.is_voided = false
      and i.is_voided = false
),
     baseline_data (individual_id, gender, material, baseline_year, visit_number, baseline_status,
                    endline_year)
         as (
         select individual_id,
                gender,
                material,
                extract('year' from encounter_date_time),
                0,
                'null'::TEXT,
                0
         from partitioned_annual
         where rank = 1
     ),
     midline_partitioned as (
         select enc.program_enrolment_id,
                enc.observations,
                encounter_date_time,
                row_number() OVER (PARTITION BY individual_id ORDER BY enc.encounter_date_time) rank
         from program_encounter_view enc
                  join program_enrolment enl on enc.program_enrolment_id = enl.id
         where encounter_type_name = 'Midline Visit'
           and enl.is_voided = false
           and enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     midline_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'),
                baseline_year,
                1        visit_number,
                b.gender gender,
                baseline_year + 1
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join midline_partitioned enc on enc.program_enrolment_id = enl.id
             and extract('year' from encounter_date_time) = baseline_year + 1
             and rank = 1
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_1_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'),
                baseline_year,
                2        visit_number,
                b.gender gender,
                baseline_year + 1
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 1
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_2_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'),
                baseline_year,
                3        visit_number,
                b.gender gender,
                baseline_year + 2
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 2
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_3_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'),
                baseline_year,
                4        visit_number,
                b.gender gender,
                baseline_year + 3
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 3
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_4_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'),
                baseline_year,
                5        visit_number,
                b.gender gender,
                baseline_year + 4
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 4
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_5_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'),
                baseline_year,
                6        visit_number,
                b.gender gender,
                baseline_year + 5
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 5
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_6_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'),
                baseline_year,
                7        visit_number,
                b.gender gender,
                baseline_year + 6
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 6
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_7_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                multi_select_coded(enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'),
                baseline_year,
                8        visit_number,
                b.gender gender,
                baseline_year + 7
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 7
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_data
         (individual_id, material, baseline_year, visit_number, gender, endline_year)
         as
         (select *
          from midline_data
          union all
          select *
          from endline_1_data
          union all
          select *
          from endline_2_data
          union all
          select *
          from endline_3_data
          union all
          select *
          from endline_4_data
          union all
          select *
          from endline_5_data
          union all
          select *
          from endline_6_data
          union all
          select *
          from endline_7_data
         ),
     endline_for_baseline_falalin
         (individual_id, gender, material, baseline_year, visit_number, baseline_status, endline_year)
         as
         (select b.individual_id,
                 b.gender,
                 e.material,
                 b.baseline_year,
                 e.visit_number,
                 'Falalin'::TEXT,
                 e.endline_year
          from baseline_data b
                   join endline_data e on e.individual_id = b.individual_id
          where b.material NOTNULL
            AND b.material = 'Falalin'
         ),
     endline_for_baseline_sanitary_pad(individual_id, gender, material, baseline_year, visit_number,
                                       baseline_status, endline_year) as (
         select e.individual_id,
                b.gender,
                e.material,
                b.baseline_year,
                e.visit_number,
                'Sanitary pad'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.material NOTNULL
           AND b.material = 'Sanitary pad'
     ),
     endline_for_baseline_old_cloth(individual_id, gender, material, baseline_year, visit_number, baseline_status,
                                    endline_year)
         as (
         select e.individual_id,
                b.gender,
                e.material,
                b.baseline_year,
                e.visit_number,
                'Old cloth'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.material NOTNULL
           AND b.material = 'Old cloth'
     ),
     endline_for_baseline_kit_pad(individual_id, gender, material, baseline_year, visit_number, baseline_status,
                                  endline_year)
         as (
         select e.individual_id,
                b.gender,
                e.material,
                b.baseline_year,
                e.visit_number,
                'Kit pad'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.material NOTNULL
           AND b.material = 'Kit pad'
     ),
     all_events as (select *
                    from baseline_data
                    union all
                    select *
                    from endline_for_baseline_kit_pad
                    union all
                    select *
                    from endline_for_baseline_sanitary_pad
                    union all
                    select *
                    from endline_for_baseline_old_cloth
                    union all
                    select *
                    from endline_for_baseline_falalin)

select individual_id,
       jsonb_build_object(
               'baselineFalalin', material NOTNULL AND material = 'Falalin' AND baseline_status = 'null',
               'baselineSanitary', material NOTNULL AND material = 'Sanitary pad' AND baseline_status = 'null',
               'baselineOldCloth', material NOTNULL AND material = 'Old cloth' AND baseline_status = 'null',
               'baselineKitPad', material NOTNULL and material = 'Kit pad' AND baseline_status = 'null',
               'baselineDataNotCapture', material isnull AND baseline_status = 'null',
           --------------------
               'baselineFalalinEndlineFalalin',
               material NOTNULL AND material = 'Falalin' AND baseline_status = 'Falalin',
               'baselineFalalinEndlineSanitary',
               material NOTNULL AND material = 'Sanitary pad' AND baseline_status = 'Falalin',
               'baselineFalalinEndlineOldCloth',
               material NOTNULL AND material = 'Old cloth' AND baseline_status = 'Falalin',
               'baselineFalalinEndlineKitPad',
               material NOTNULL AND material = 'Kit pad' AND baseline_status = 'Falalin',
               'baselineFalalinEndlineDataNotCapture', material ISNULL AND baseline_status = 'Falalin',
           -------------------
               'baselineSanitaryEndlineFalalin',
               material NOTNULL AND material = 'Falalin' AND baseline_status = 'Sanitary pad',
               'baselineSanitaryEndlineSanitary',
               material NOTNULL AND material = 'Sanitary pad' AND baseline_status = 'Sanitary pad',
               'baselineSanitaryEndlineOldCloth',
               material NOTNULL AND material = 'Old cloth' AND baseline_status = 'Sanitary pad',
               'baselineSanitaryEndlineKitPad',
               material NOTNULL AND material = 'Kit pad' AND baseline_status = 'Sanitary pad',
               'baselineSanitaryEndlineDataNotCapture', material ISNULL AND baseline_status = 'Sanitary pad',
           ------------------
               'baselineOldClothEndlineFalalin',
               material NOTNULL AND material = 'Falalin' AND baseline_status = 'Old cloth',
               'baselineOldClothEndlineSanitary',
               material NOTNULL AND material = 'Sanitary pad' AND baseline_status = 'Old cloth',
               'baselineOldClothEndlineOldCloth',
               material NOTNULL AND material = 'Old cloth' AND baseline_status = 'Old cloth',
               'baselineOldClothEndlineKitPad',
               material NOTNULL AND material = 'Kit pad' AND baseline_status = 'Old cloth',
               'baselineOldClothEndlineDataNotCapture', material ISNULL AND baseline_status = 'Old cloth',
           ------------------
               'baselineKitPadEndlineFalalin',
               material NOTNULL AND material = 'Falalin' AND baseline_status = 'Kit pad',
               'baselineKitPadEndlineSanitary',
               material NOTNULL AND material = 'Sanitary pad' AND baseline_status = 'Kit pad',
               'baselineKitPadEndlineOldCloth',
               material NOTNULL AND material = 'Old cloth' AND baseline_status = 'Kit pad',
               'baselineKitPadEndlineKitPad', material NOTNULL AND material = 'Kit pad' AND baseline_status = 'Kit pad',
               'baselineKitPadEndlineDataNotCapture', material ISNULL AND baseline_status = 'Kit pad'
           ) as status_map,
       jsonb_build_object(
               'material', material
           ) as value_map,
       gender,
       baseline_year,
       visit_number,
       endline_year
from all_events
    );

create or replace function sr_record_from_individual_menstrual_hygiene_indicator(status text, baseLineStatus text,
                                                                                 transition text,
                                                                                 transitionTo text,
                                                                                 baselineYear int,
                                                                                 lineListQuestionNumber int)
    returns table
            (
                baseline_year   float,
                baseline_status text,
                baseline        text,
                baseline_ll     text,
                transition_to   text,
                endline_year1   text,
                transition1     text,
                year_1_ll       text,
                endline_year2   text,
                transition2     text,
                year_2_ll       text,
                endline_year3   text,
                transition3     text,
                year_3_ll       text,
                endline_year4   text,
                transition4     text,
                year_4_ll       text,
                endline_year5   text,
                transition5     text,
                year_5_ll       text,
                endline_year6   text,
                transition6     text,
                year_6_ll       text,
                endline_year7   text,
                transition7     text,
                year_7_ll       text
            )
as
$body$
with data as (select baseline_year                                                                        as baseline_year,
                     $1                                                                                   as baseline_status,
                     count(distinct s.individual_id) filter ( where visit_number = 0 )                    as baselined_individuals,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true)                                  as baseline,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=0&baseline_year=%s', $6,
                            $2,
                            $5)::TEXT                                                                     as baseline_ll,
                     $4                                                                                   as transition_to,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 1) OR ($5 <> 2018 AND visit_number = 2))) ->>
                              'year',
                              'NA')                                                                       as endline_year_1,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    (($5 = 2018 AND visit_number = 1) OR
                                                                     ($5 <> 2018 AND visit_number = 2)))  as transition_1,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 1 else 2 end,
                            $5)::TEXT                                                                     as endline_1_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 2) OR ($5 <> 2018 AND visit_number = 3))) ->>
                              'year',
                              'NA')                                                                       as endline_year_2,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    (($5 = 2018 AND visit_number = 2) OR
                                                                     ($5 <> 2018 AND visit_number = 3)) ) as transition_2,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 2 else 3 end,
                            $5)::TEXT                                                                     as endline_2_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 3) OR ($5 <> 2018 AND visit_number = 4))) ->>
                              'year',
                              'NA')                                                                       as endline_year_3,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    (($5 = 2018 AND visit_number = 3) OR
                                                                     ($5 <> 2018 AND visit_number = 4)) ) as transition_3,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 3 else 4 end,
                            $5)::TEXT                                                                     as endline_3_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 4) OR ($5 <> 2018 AND visit_number = 5))) ->>
                              'year',
                              'NA')                                                                       as endline_year_4,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    (($5 = 2018 AND visit_number = 4) OR
                                                                     ($5 <> 2018 AND visit_number = 5)) ) as transition_4,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 4 else 5 end,
                            $5)::TEXT                                                                     as endline_4_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 5) OR ($5 <> 2018 AND visit_number = 6))) ->>
                              'year',
                              'NA')                                                                       as endline_year_5,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    (($5 = 2018 AND visit_number = 5) OR
                                                                     ($5 <> 2018 AND visit_number = 6)) ) as transition_5,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 5 else 6 end,
                            $5)::TEXT                                                                     as endline_5_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 6) OR ($5 <> 2018 AND visit_number = 7))) ->>
                              'year',
                              'NA')                                                                       as endline_year_6,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    (($5 = 2018 AND visit_number = 6) OR
                                                                     ($5 <> 2018 AND visit_number = 7)) ) as transition_6,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 6 else 7 end,
                            $5)::TEXT                                                                     as endline_6_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 7) OR ($5 <> 2018 AND visit_number = 8))) ->>
                              'year',
                              'NA')                                                                       as endline_year_7,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    (($5 = 2018 AND visit_number = 7) OR
                                                                     ($5 <> 2018 AND visit_number = 8)) ) as transition_7,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 7 else 8 end,
                            $5)::TEXT                                                                     as endline_7_ll

              from sr_individual_indicator_matrix s
              where baseline_year = $5
              group by baseline_year)
select baseline_year,
       baseline_status,
       format('%s (%s%%)', baseline, trunc((baseline::DECIMAL * 100) / baselined_individuals, 2)),
       baseline_ll,
       transition_to,
       endline_year_1,
       format('%s (%s%%)', transition_1, trunc((transition_1::DECIMAL * 100) / baseline, 2)),
       endline_1_ll,
       endline_year_2,
       format('%s (%s%%)', transition_2, trunc((transition_2::DECIMAL * 100) / baseline, 2)),
       endline_2_ll,
       endline_year_3,
       format('%s (%s%%)', transition_3, trunc((transition_3::DECIMAL * 100) / baseline, 2)),
       endline_3_ll,
       endline_year_4,
       format('%s (%s%%)', transition_4, trunc((transition_4::DECIMAL * 100) / baseline, 2)),
       endline_4_ll,
       endline_year_5,
       format('%s (%s%%)', transition_5, trunc((transition_5::DECIMAL * 100) / baseline, 2)),
       endline_5_ll,
       endline_year_6,
       format('%s (%s%%)', transition_6, trunc((transition_6::DECIMAL * 100) / baseline, 2)),
       endline_6_ll,
       endline_year_7,
       format('%s (%s%%)', transition_7, trunc((transition_7::DECIMAL * 100) / baseline, 2)),
       endline_7_ll
from data d;
$body$
    language sql;



-----views and functions for School Dropout Ratio
create or replace view sr_individual_School_Dropout_Ratio_indicator_matrix as
(
with partitioned_annual as (
    SELECT i.id                                                                             individual_id,
           row_number() OVER (PARTITION BY i.id ORDER BY enc.encounter_date_time)           rank,
           encounter_date_time,
           single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3') schoolGoing,
           g.name                                                                           gender
    from program_encounter enc
             join encounter_type enct on enc.encounter_type_id = enct.id
             join program_enrolment enl on enc.program_enrolment_id = enl.id
             join operational_program_view op ON op.program_id = enl.program_id
             join individual i on enl.individual_id = i.id
             join gender g on i.gender_id = g.id
    WHERE op.program_name = 'Adolescent'
      AND enct.name = 'Annual Visit'
      AND enc.encounter_date_time NOTNULL
      and enc.is_voided = false
      and enl.program_exit_date_time ISNULL
      and enl.is_voided = false
      and i.is_voided = false
),
     baseline_data (individual_id, gender, schoolGoing, baseline_year, visit_number, baseline_status,
                    endline_year)
         as (
         select individual_id,
                gender,
                schoolGoing,
                extract('year' from encounter_date_time),
                0,
                'null'::TEXT,
                0
         from partitioned_annual
         where rank = 1
     ),
     midline_partitioned as (
         select enc.program_enrolment_id,
                enc.observations,
                encounter_date_time,
                row_number() OVER (PARTITION BY individual_id ORDER BY enc.encounter_date_time) rank
         from program_encounter_view enc
                  join program_enrolment enl on enc.program_enrolment_id = enl.id
         where encounter_type_name = 'Midline Visit'
           and enl.is_voided = false
           and enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     midline_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'),
                baseline_year,
                1        visit_number,
                b.gender gender,
                baseline_year + 1
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join midline_partitioned enc on enc.program_enrolment_id = enl.id
             and extract('year' from encounter_date_time) = baseline_year + 1
             and rank = 1
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_1_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'),
                baseline_year,
                2        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 2
                    else baseline_year + 1 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 1
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_2_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'),
                baseline_year,
                3        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 3
                    else baseline_year + 2 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 2
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_3_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'),
                baseline_year,
                4        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 4
                    else baseline_year + 3 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 3
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_4_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'),
                baseline_year,
                5        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 5
                    else baseline_year + 4 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 4
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_5_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'),
                baseline_year,
                6        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 6
                    else baseline_year + 5 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 5
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_6_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'),
                baseline_year,
                7        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 7
                    else baseline_year + 6 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 6
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_7_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
         select b.individual_id,
                single_select_coded(enc.observations ->> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'),
                baseline_year,
                8        visit_number,
                b.gender gender,
                case
                    when baseline_year = 2018
                        then baseline_year + 8
                    else baseline_year + 7 end
         from baseline_data b
                  left join program_enrolment enl on enl.individual_id = b.individual_id
                  left join program_encounter_view enc on enc.program_enrolment_id = enl.id
             and enc.encounter_type_name = 'Endline Visit'
             and enc.is_voided = false
             and extract('year' from encounter_date_time) = baseline_year + 7
         where enl.program_exit_date_time ISNULL
           and enl.is_voided = false
     ),
     endline_data
         (individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year)
         as
         (select *
          from midline_data
          union all
          select *
          from endline_1_data
          union all
          select *
          from endline_2_data
          union all
          select *
          from endline_3_data
          union all
          select *
          from endline_4_data
          union all
          select *
          from endline_5_data
          union all
          select *
          from endline_6_data
          union all
          select *
          from endline_7_data
         ),
     endline_for_baseline_dropOut
         (individual_id, gender, schoolGoing, baseline_year, visit_number, baseline_status, endline_year)
         as
         (select b.individual_id,
                 b.gender,
                 e.schoolGoing,

                 b.baseline_year,
                 e.visit_number,
                 'Dropped Out'::TEXT,
                 e.endline_year
          from baseline_data b
                   join endline_data e on e.individual_id = b.individual_id
          where b.schoolGoing NOTNULL
            AND b.schoolGoing = 'Dropped Out'
         ),
     endline_for_baseline_going(individual_id, gender, schoolGoing, baseline_year, visit_number,
                                baseline_status, endline_year) as (
         select e.individual_id,
                b.gender,
                e.schoolGoing,

                b.baseline_year,
                e.visit_number,
                'Going'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.schoolGoing NOTNULL
           AND b.schoolGoing = 'Yes'
     ),
     endline_for_baseline_dataNotCapture(individual_id, gender, schoolGoing, baseline_year, visit_number,
                                         baseline_status,
                                         endline_year) as (
         select e.individual_id,
                b.gender,
                e.schoolGoing,
                b.baseline_year,
                e.visit_number,
                'Data Not Capture'::TEXT,
                e.endline_year
         from baseline_data b
                  join endline_data e on e.individual_id = b.individual_id
         where b.schoolGoing ISNULL
     ),
     all_events as (select *
                    from baseline_data
                    union all
                    select *
                    from endline_for_baseline_dropOut
                    union all
                    select *
                    from endline_for_baseline_going
                    union all
                    select *
                    from endline_for_baseline_dataNotCapture
     )

select individual_id,
       jsonb_build_object(
               'baselinedropOut', schoolGoing NOTNULL AND schoolGoing = 'Dropped Out' AND baseline_status = 'null',
               'baselineGoing', schoolGoing NOTNULL AND schoolGoing = 'Yes' AND baseline_status = 'null',
               'baselinedataNotCapture', schoolGoing ISNULL AND baseline_status = 'null',
           -----DropuOut---------
               'baselinedropOutEndlinedropOut',schoolGoing NOTNULL AND schoolGoing = 'Dropped Out' AND baseline_status = 'Dropped Out',
               'baselinedropOutEndlineGoing', schoolGoing NOTNULL AND schoolGoing = 'Yes' AND baseline_status = 'Dropped Out',
               'baselinedropOutEndlineNotCapture',schoolGoing ISNULL AND baseline_status = 'Dropped Out'
           -----SchooGoing----------
               'baselineGoingEndlinedropOut',schoolGoing NOTNULL AND schoolGoing = 'Dropped Out' AND baseline_status = 'Going',
               'baselineGoingEndlineGoing', schoolGoing NOTNULL AND schoolGoing = 'Yes' AND baseline_status = 'Going',
               'baselineGoingEndlineNotCapture',schoolGoing ISNULL AND baseline_status = 'Going'
           ------DataNotCapture--------
               'baselineNotCaptureEndlinedropOut',schoolGoing NOTNULL AND schoolGoing = 'Dropped Out' AND baseline_status = 'NotCapture',
               'baselineNotCaptureEndlineGoing', schoolGoing NOTNULL AND schoolGoing = 'Yes' AND baseline_status = 'NotCapture',
               'baselineNotCaptureEndlineNotCapture',schoolGoing ISNULL AND baseline_status = 'NotCapture'
           ) as status_map,
       jsonb_build_object(
               'schoolGoing', schoolGoing
           ) as value_map,
       gender,
       baseline_year,
       visit_number,
       endline_year
from all_events
    );



create or replace function sr_individual_School_Dropout_Ratio_indicator_matrix(status text, baseLineStatus text,
                                                                               transition text,
                                                                               transitionTo text,
                                                                               baselineYear int,
                                                                               lineListQuestionNumber int)
    returns table
            (
                baseline_year       float,
                baseline_status     text,
                baseline_male       text,
                baseline_female     text,
                baseline            text,
                baseline_ll         text,
                transition_to       text,
                endline_year1       text,
                transition_1_male   text,
                transition_1_female text,
                transition1         text,
                year_1_ll           text,
                endline_year2       text,
                transition_2_male   text,
                transition_2_female text,
                transition2         text,
                year_2_ll           text,
                endline_year3       text,
                transition_3_male   text,
                transition_3_female text,
                transition3         text,
                year_3_ll           text,
                endline_year4       text,
                transition_4_male   text,
                transition_4_female text,
                transition4         text,
                year_4_ll           text,
                endline_year5       text,
                transition_5_male   text,
                transition_5_female text,
                transition5         text,
                year_5_ll           text,
                endline_year6       text,
                transition_6_male   text,
                transition_6_female text,
                transition6         text,
                year_6_ll           text,
                endline_year7       text,
                transition_7_male   text,
                transition_7_female text,
                transition7         text,
                year_7_ll           text
            )
as
$body$
with data as (select baseline_year                                                                        as baseline_year,
                     $1                                                                                   as baseline_status,
                     count(distinct s.individual_id) filter ( where visit_number = 0 )                    as baselined_individuals,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true)                                  as baseline,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true and gender = 'Male')              as baseline_male,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true and gender = 'Female')            as baseline_female,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=0&baseline_year=%s', $6,
                            $2,
                            $5)::TEXT                                                                     as baseline_ll,
                     $4                                                                                   as transition_to,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 1) OR ($5 <> 2018 AND visit_number = 2))) ->>
                              'year',
                              'NA')                                                                       as endline_year_1,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Male' and
                                                                    (($5 = 2018 AND visit_number = 1) OR
                                                                     ($5 <> 2018 AND visit_number = 2)))  as transition_1_male,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Female' and
                                                                    (($5 = 2018 AND visit_number = 1) OR
                                                                     ($5 <> 2018 AND visit_number = 2)))  as transition_1_female,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 1 else 2 end,
                            $5)::TEXT                                                                     as endline_1_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 2) OR ($5 <> 2018 AND visit_number = 3))) ->>
                              'year',
                              'NA')                                                                       as endline_year_2,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Male' and
                                                                    (($5 = 2018 AND visit_number = 2) OR
                                                                     ($5 <> 2018 AND visit_number = 3)) ) as transition_2_male,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Female' and
                                                                    (($5 = 2018 AND visit_number = 2) OR
                                                                     ($5 <> 2018 AND visit_number = 3)))  as transition_2_female,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 2 else 3 end,
                            $5)::TEXT                                                                     as endline_2_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 3) OR ($5 <> 2018 AND visit_number = 4))) ->>
                              'year',
                              'NA')                                                                       as endline_year_3,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Male' and
                                                                    (($5 = 2018 AND visit_number = 3) OR
                                                                     ($5 <> 2018 AND visit_number = 4)) ) as transition_3_male,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Female' and
                                                                    (($5 = 2018 AND visit_number = 3) OR
                                                                     ($5 <> 2018 AND visit_number = 4)))  as transition_3_female,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 3 else 4 end,
                            $5)::TEXT                                                                     as endline_3_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 4) OR ($5 <> 2018 AND visit_number = 5))) ->>
                              'year',
                              'NA')                                                                       as endline_year_4,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Male' and
                                                                    (($5 = 2018 AND visit_number = 4) OR
                                                                     ($5 <> 2018 AND visit_number = 5)) ) as transition_4_male,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Female' and
                                                                    (($5 = 2018 AND visit_number = 4) OR
                                                                     ($5 <> 2018 AND visit_number = 5)))  as transition_4_female,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 4 else 5 end,
                            $5)::TEXT                                                                     as endline_4_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 5) OR ($5 <> 2018 AND visit_number = 6))) ->>
                              'year',
                              'NA')                                                                       as endline_year_5,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Male' and
                                                                    (($5 = 2018 AND visit_number = 5) OR
                                                                     ($5 <> 2018 AND visit_number = 6)) ) as transition_5_male,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Female' and
                                                                    (($5 = 2018 AND visit_number = 5) OR
                                                                     ($5 <> 2018 AND visit_number = 6)))  as transition_5_female,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 5 else 6 end,
                            $5)::TEXT                                                                     as endline_5_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 6) OR ($5 <> 2018 AND visit_number = 7))) ->>
                              'year',
                              'NA')                                                                       as endline_year_6,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Male' and
                                                                    (($5 = 2018 AND visit_number = 6) OR
                                                                     ($5 <> 2018 AND visit_number = 7)) ) as transition_6_male,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Female' and
                                                                    (($5 = 2018 AND visit_number = 6) OR
                                                                     ($5 <> 2018 AND visit_number = 7)))  as transition_6_female,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 6 else 7 end,
                            $5)::TEXT                                                                     as endline_6_ll,
                     coalesce((json_object_agg('year', endline_year)
                               FILTER (WHERE ($5 = 2018 AND visit_number = 7) OR ($5 <> 2018 AND visit_number = 8))) ->>
                              'year',
                              'NA')                                                                       as endline_year_7,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Male' and
                                                                    (($5 = 2018 AND visit_number = 7) OR
                                                                     ($5 <> 2018 AND visit_number = 8)) ) as transition_7_male,
                     count(distinct s.individual_id) filter ( where (status_map ->> $3)::boolean = true and
                                                                    gender = 'Female' and
                                                                    (($5 = 2018 AND visit_number = 7) OR
                                                                     ($5 <> 2018 AND visit_number = 8)))  as transition_7_female,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=%s&baseline_year=%s', $6,
                            $3,
                            case when $5 = 2018 then 7 else 8 end,
                            $5)::TEXT                                                                     as endline_7_ll

              from sr_individual_School_Dropout_Ratio_indicator_matrix s
              where baseline_year = $5
              group by baseline_year)
select baseline_year,
       baseline_status,
       format('%s (%s%%)', baseline_male, trunc((baseline_male::DECIMAL * 100) / baselined_individuals, 2)),
       format('%s (%s%%)', baseline_female, trunc((baseline_female::DECIMAL * 100) / baselined_individuals, 2)),
       format('%s (%s%%)', (baseline_male + baseline_female),
              trunc(((baseline_male + baseline_female)::DECIMAL * 100) / baselined_individuals, 2)),
       baseline_ll,
       transition_to,
       endline_year_1,
       format('%s (%s%%)', transition_1_male, trunc((transition_1_male::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', transition_1_female, trunc((transition_1_female::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', (transition_1_female + transition_1_male),
              trunc(((transition_1_female + transition_1_male)::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_1_ll,
       endline_year_2,
       format('%s (%s%%)', transition_2_male, trunc((transition_2_male::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', transition_2_female, trunc((transition_2_female::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', (transition_2_female + transition_2_male),
              trunc(((transition_2_female + transition_2_male)::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_2_ll,
       endline_year_3,
       format('%s (%s%%)', transition_3_male, trunc((transition_3_male::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', transition_3_female, trunc((transition_3_female::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', (transition_3_female + transition_3_male),
              trunc(((transition_3_female + transition_3_male)::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_3_ll,
       endline_year_4,
       format('%s (%s%%)', transition_4_male, trunc((transition_4_male::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', transition_4_female, trunc((transition_4_female::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', (transition_4_female + transition_4_male),
              trunc(((transition_4_female + transition_4_male)::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_4_ll,
       endline_year_5,
       format('%s (%s%%)', transition_5_male, trunc((transition_5_male::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', transition_5_female, trunc((transition_5_female::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', (transition_5_female + transition_5_male),
              trunc(((transition_5_female + transition_5_male)::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_5_ll,
       endline_year_6,
       format('%s (%s%%)', transition_6_male, trunc((transition_6_male::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', transition_6_female, trunc((transition_6_female::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', (transition_6_female + transition_6_male),
              trunc(((transition_6_female + transition_6_male)::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_6_ll,
       endline_year_7,
       format('%s (%s%%)', transition_7_male, trunc((transition_7_male::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', transition_7_female, trunc((transition_7_female::DECIMAL * 100) / nullif(baseline, 0), 2)),
       format('%s (%s%%)', (transition_7_female + transition_7_male),
              trunc(((transition_7_female + transition_7_male)::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_7_ll
from data d;
$body$
    language sql;

create table sr_enrolment_year
(
    year integer
);

insert into sr_enrolment_year
values (2016),
       (2017),
       (2018),
       (2019),
       (2020),
       (2021),
       (2022),
       (2023),
       (2024),
       (2025),
       (2026),
       (2027),
       (2028),
       (2029),
       (2030);

set role none;
