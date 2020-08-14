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
                   enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc' hb_status,
                   g.name                                                                           gender
            from program_encounter enc
                     join encounter_type enct on enc.encounter_type_id = enct.id
                     join program_enrolment enl on enc.program_enrolment_id = enl.id
                     join program p ON p.id = enl.program_id
                     join individual i on enl.individual_id = i.id
                     join gender g on i.gender_id = g.id
            WHERE p.id = 3
              AND enct.id = 7
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
                 where enc.encounter_type_id = 47
                   and enl.is_voided = false
                   and enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             midline_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                        enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc',
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
                        enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_2_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                        enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 2
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_3_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                        enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 3
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_4_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                        enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 4
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_5_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                        enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 5
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_6_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                        enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 6
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_7_data(individual_id, hb, hb_status, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        cast(enc.observations ->> 'f9ecabbc-2df2-4bfc-a6fa-aa417c50e11b' AS FLOAT),
                        enc.observations ->> 'c5d4acdc-86f5-4b6f-b700-ef85d89108dc',
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
                     and enc.encounter_type_id = 88
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
             endline_for_baseline_mild(individual_id, gender, hb, hb_status, baseline_year, visit_number,
                                       baseline_status,
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
             endline_for_baseline_normal(individual_id, gender, hb, hb_status, baseline_year, visit_number,
                                         baseline_status,
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
             endline_for_baseline_missed(individual_id, gender, hb, hb_status, baseline_year, visit_number,
                                         baseline_status,
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
                       'baselineHBDone', hb_status = '8d161a9c-9401-4883-8cf7-ce0a8f2d7b45' AND baseline_status = 'null',
                       'baselineHBNotDone', hb_status = '474477a3-9859-4d7c-865c-e8fdc7bba9d8' AND baseline_status = 'null',
                       'baselineMissingHB', hb ISNULL AND baseline_status = 'null',
                       'baselineSevereEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Severe',
                       'baselineSevereEndlineModerate',
                       hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Severe',
                       'baselineSevereEndlineMild',
                       hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Severe',
                       'baselineSevereEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Severe',
                       'baselineSevereEndlineHBDone', hb_status = '8d161a9c-9401-4883-8cf7-ce0a8f2d7b45' AND baseline_status = 'Severe',
                       'baselineSevereEndlineHBNotDone', hb_status = '474477a3-9859-4d7c-865c-e8fdc7bba9d8' AND baseline_status = 'Severe',
                       'baselineSevereEndlineMissingHB', hb ISNULL AND hb_status ISNULL AND baseline_status = 'Severe',
                       'baselineModerateEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Moderate',
                       'baselineModerateEndlineModerate',
                       hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Moderate',
                       'baselineModerateEndlineMild',
                       hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Moderate',
                       'baselineModerateEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Moderate',
                       'baselineModerateEndlineHBDone', hb_status = '8d161a9c-9401-4883-8cf7-ce0a8f2d7b45' AND baseline_status = 'Moderate',
                       'baselineModerateEndlineHBNotDone', hb_status = '474477a3-9859-4d7c-865c-e8fdc7bba9d8' AND baseline_status = 'Moderate',
                       'baselineModerateEndlineMissingHB', hb ISNULL AND baseline_status = 'Moderate',
                       'baselineMildEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Mild',
                       'baselineMildEndlineModerate',
                       hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Mild',
                       'baselineMildEndlineMild',
                       hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Mild',
                       'baselineMildEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Mild',
                       'baselineMildEndlineHBDone', hb_status = '8d161a9c-9401-4883-8cf7-ce0a8f2d7b45' AND baseline_status = 'Mild',
                       'baselineMildEndlineHBNotDone', hb_status = '474477a3-9859-4d7c-865c-e8fdc7bba9d8' AND baseline_status = 'Mild',
                       'baselineMildEndlineMissingHB', hb ISNULL AND baseline_status = 'Mild',
                       'baselineNormalEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Normal',
                       'baselineNormalEndlineModerate',
                       hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Normal',
                       'baselineNormalEndlineMild',
                       hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Normal',
                       'baselineNormalEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Normal',
                       'baselineNormalEndlineHBDone', hb_status = '8d161a9c-9401-4883-8cf7-ce0a8f2d7b45' AND baseline_status = 'Normal',
                       'baselineNormalEndlineHBNotDone', hb_status = '474477a3-9859-4d7c-865c-e8fdc7bba9d8' AND baseline_status = 'Normal',
                       'baselineNormalEndlineMissingHB', hb ISNULL AND baseline_status = 'Normal',
                       'baselineMissedEndlineSevere', hb NOTNULL AND hb <= 7 AND baseline_status = 'Missed',
                       'baselineMissedEndlineModerate',
                       hb NOTNULL AND hb BETWEEN 7.1 AND 10 AND baseline_status = 'Missed',
                       'baselineMissedEndlineMild',
                       hb NOTNULL AND hb BETWEEN 10.1 AND 11.9 AND baseline_status = 'Missed',
                       'baselineMissedEndlineNormal', hb NOTNULL AND hb >= 12 AND baseline_status = 'Missed',
                       'baselineMissedEndlineHBDone', hb_status = '8d161a9c-9401-4883-8cf7-ce0a8f2d7b45' AND baseline_status = 'Missed',
                       'baselineMissedEndlineHBNotDone', hb_status = '474477a3-9859-4d7c-865c-e8fdc7bba9d8' AND baseline_status = 'Missed',
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

create or replace function sr_record_from_individual_indicator(status text, baseLineStatus text, transition text,
                                                               transitionTo text,
                                                               baselineYear int, lineListQuestionNumber int)
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

              from sr_individual_indicator_matrix s
              where baseline_year = $5
              group by baseline_year)
select baseline_year,
       baseline_status,
       format('%s (%s%%)', baseline_male, trunc((baseline_male::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
       format('%s (%s%%)', baseline_female,
              trunc((baseline_female::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
       format('%s (%s%%)', (baseline_male + baseline_female),
              trunc(((baseline_male + baseline_female)::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
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

-------------prevalence_substance_misuse_
create or replace view sr_individual_prevalence_substance_misuse_indicator_matrix as
    (
        with partitioned_annual as (
            SELECT i.id                                                                   individual_id,
                   row_number() OVER (PARTITION BY i.id ORDER BY enc.encounter_date_time) rank,
                   encounter_date_time,
                   enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8'             addiction,
                   g.name                                                                 gender
            from program_encounter enc
                     join encounter_type enct on enc.encounter_type_id = enct.id
                     join program_enrolment enl on enc.program_enrolment_id = enl.id
                     join program p ON p.id = enl.program_id
                     join individual i on enl.individual_id = i.id
                     join gender g on i.gender_id = g.id
            WHERE p.id = 3
              AND enct.id = 7
              AND enc.encounter_date_time NOTNULL
              and enc.is_voided = false
              and enl.program_exit_date_time ISNULL
              and enl.is_voided = false
              and i.is_voided = false
        ),
             baseline_data (individual_id, gender, addiction, quitted, baseline_year, visit_number, baseline_status,
                            endline_year)
                 as (
                 select pa.individual_id,
                        pa.gender,
                        addiction,
                        quitted,
                        extract('year' from pa.encounter_date_time),
                        0,
                        'null'::TEXT,
                        0
                 from partitioned_annual pa
                          left join sr_partitioned_addiction_view pad
                                    on pad.individual_id = pa.individual_id and pad.rank2 = 1
                 where pa.rank = 1
             ),
             midline_partitioned as (
                 select enc.program_enrolment_id,
                        enc.observations,
                        encounter_date_time,
                        row_number() OVER (PARTITION BY individual_id ORDER BY enc.encounter_date_time) rank
                 from program_encounter_view enc
                          join program_enrolment enl on enc.program_enrolment_id = enl.id
                 where encounter_type_id = 47
                   and enl.is_voided = false
                   and enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             midline_data(individual_id, addiction, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,

                        enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8',
                        enc2.quitted as quitted,
                        baseline_year,
                        1               visit_number,
                        b.gender        gender,
                        baseline_year + 1
                 from baseline_data b
                          left join program_enrolment enl on enl.individual_id = b.individual_id
                          left join midline_partitioned enc on enc.program_enrolment_id = enl.id
                     and extract('year' from enc.encounter_date_time) = baseline_year + 1
                     and rank = 1
                          left join sr_partitioned_addiction_view enc2
                                    on enc2.individual_id = enl.individual_id and rank2 = 1
                                        and extract('year' from enc2.encounter_date_time) = baseline_year + 1

                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_1_data(individual_id, addiction, quitted, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8',
                        enc2.quitted as quitted,
                        baseline_year,
                        2               visit_number,
                        b.gender        gender,
                        case
                            when baseline_year = 2018
                                then baseline_year + 2
                            else baseline_year + 1 end
                 from baseline_data b
                          left join program_enrolment enl on enl.individual_id = b.individual_id
                          left join program_encounter_view enc on enc.program_enrolment_id = enl.id
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from enc.encounter_date_time) = baseline_year + 1
                          left join sr_partitioned_addiction_view enc2
                                    on enc2.individual_id = enl.individual_id and rank2 = 1
                                        and extract('year' from enc2.encounter_date_time) = baseline_year + 1

                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_2_data(individual_id, addicted, quitted, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8',
                        enc2.quitted as quitted,
                        baseline_year,
                        3               visit_number,
                        b.gender        gender,
                        case
                            when baseline_year = 2018
                                then baseline_year + 3
                            else baseline_year + 2 end
                 from baseline_data b
                          left join program_enrolment enl on enl.individual_id = b.individual_id
                          left join program_encounter_view enc on enc.program_enrolment_id = enl.id
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from enc.encounter_date_time) = baseline_year + 1
                          left join sr_partitioned_addiction_view enc2
                                    on enc2.individual_id = enl.individual_id and rank2 = 1
                                        and extract('year' from enc2.encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_3_data(individual_id, addiction, quitted, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8',
                        enc2.quitted as quitted,
                        baseline_year,
                        4               visit_number,
                        b.gender        gender,
                        case
                            when baseline_year = 2018
                                then baseline_year + 4
                            else baseline_year + 3 end
                 from baseline_data b
                          left join program_enrolment enl on enl.individual_id = b.individual_id
                          left join program_encounter_view enc on enc.program_enrolment_id = enl.id
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from enc.encounter_date_time) = baseline_year + 1
                          left join sr_partitioned_addiction_view enc2
                                    on enc2.individual_id = enl.individual_id and rank2 = 1
                                        and extract('year' from enc2.encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_4_data(individual_id, addiction, quitted, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8',
                        enc2.quitted as quitted,
                        baseline_year,
                        5               visit_number,
                        b.gender        gender,
                        case
                            when baseline_year = 2018
                                then baseline_year + 5
                            else baseline_year + 4 end
                 from baseline_data b
                          left join program_enrolment enl on enl.individual_id = b.individual_id
                          left join program_encounter_view enc on enc.program_enrolment_id = enl.id
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from enc.encounter_date_time) = baseline_year + 1
                          left join sr_partitioned_addiction_view enc2
                                    on enc2.individual_id = enl.individual_id and rank2 = 1
                                        and extract('year' from enc2.encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_5_data(individual_id, addiction, quitted, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8',
                        enc2.quitted as quitted,
                        baseline_year,
                        6               visit_number,
                        b.gender        gender,
                        case
                            when baseline_year = 2018
                                then baseline_year + 6
                            else baseline_year + 5 end
                 from baseline_data b
                          left join program_enrolment enl on enl.individual_id = b.individual_id
                          left join program_encounter_view enc on enc.program_enrolment_id = enl.id
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from enc.encounter_date_time) = baseline_year + 1
                          left join sr_partitioned_addiction_view enc2
                                    on enc2.individual_id = enl.individual_id and rank2 = 1
                                        and extract('year' from enc2.encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_6_data(individual_id, addiction, quitted, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8',
                        enc2.quitted as quitted,
                        baseline_year,
                        7               visit_number,
                        b.gender        gender,
                        case
                            when baseline_year = 2018
                                then baseline_year + 7
                            else baseline_year + 6 end
                 from baseline_data b
                          left join program_enrolment enl on enl.individual_id = b.individual_id
                          left join program_encounter_view enc on enc.program_enrolment_id = enl.id
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from enc.encounter_date_time) = baseline_year + 1
                          left join sr_partitioned_addiction_view enc2
                                    on enc2.individual_id = enl.individual_id and rank2 = 1
                                        and extract('year' from enc2.encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_7_data(individual_id, addiction, quitted, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '2ebca9be-3be3-4d11-ada0-187563ff04f8',
                        enc2.quitted as quitted,
                        baseline_year,
                        8               visit_number,
                        b.gender        gender,
                        case
                            when baseline_year = 2018
                                then baseline_year + 8
                            else baseline_year + 7 end
                 from baseline_data b
                          left join program_enrolment enl on enl.individual_id = b.individual_id
                          left join program_encounter_view enc on enc.program_enrolment_id = enl.id
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from enc.encounter_date_time) = baseline_year + 1
                          left join sr_partitioned_addiction_view enc2
                                    on enc2.individual_id = enl.individual_id and rank2 = 1
                                        and extract('year' from enc2.encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_data
                 (individual_id, addiction, quitted, baseline_year, visit_number, gender, endline_year)
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
             endline_for_baseline_alcohol
                 (individual_id, gender, addiction, baseline_year, visit_number, baseline_status, endline_year)
                 as
                 (select b.individual_id,
                         b.gender,
                         e.addiction,
                         e.quitted,
                         b.baseline_year,
                         e.visit_number,
                         'Alcohol'::TEXT,
                         e.endline_year
                  from baseline_data b
                           join endline_data e on e.individual_id = b.individual_id
                  where b.addiction notnull
                    and b.addiction @> to_jsonb('92654fda-d485-4b6d-97c5-8a8fe2a9582a'::text)
                 ),
             endline_for_baseline_tobacco
                 (individual_id, gender, addiction, quitted, baseline_year, visit_number, baseline_status, endline_year)
                 as
                 (select b.individual_id,
                         b.gender,
                         e.addiction,
                         e.quitted,
                         b.baseline_year,
                         e.visit_number,
                         'Tobacco'::TEXT,
                         e.endline_year
                  from baseline_data b
                           join endline_data e on e.individual_id = b.individual_id
                  where b.addiction notnull
                    and b.addiction @> to_jsonb('ef29759b-5f74-4f5a-b186-fea7697cfb34'::text)
                 ),
             endline_for_baseline_both
                 (individual_id, gender, addiction, quitted, baseline_year, visit_number, baseline_status, endline_year)
                 as
                 (select b.individual_id,
                         b.gender,
                         e.addiction,
                         e.quitted,
                         b.baseline_year,
                         e.visit_number,
                         'Both'::TEXT,
                         e.endline_year
                  from baseline_data b
                           join endline_data e on e.individual_id = b.individual_id
                  where b.addiction notnull
                    and b.addiction @> to_jsonb('246df73a-07d8-4924-8cf9-787dea8278fe'::text)
                 ),

             endline_for_baseline_noAddiction
                 (individual_id, gender, addiction, quitted, baseline_year, visit_number, baseline_status, endline_year)
                 as
                 (select b.individual_id,
                         b.gender,
                         e.addiction,
                         e.quitted,
                         b.baseline_year,
                         e.visit_number,
                         'No Addiction'::TEXT,
                         e.endline_year
                  from baseline_data b
                           join endline_data e on e.individual_id = b.individual_id
                  where b.addiction notnull
                    and b.addiction @> to_jsonb('c7f89d3c-2aa3-4570-a7a5-163e002fba66'::text)
                 ),
             all_events as (select *
                            from baseline_data
                            union all
                            select *
                            from endline_for_baseline_alcohol
                            union all
                            select *
                            from endline_for_baseline_tobacco
                            union all
                            select *
                            from endline_for_baseline_both
                            union all
                            select *
                            from endline_for_baseline_noAddiction
             )

        select individual_id,
               jsonb_build_object(
                       'baselineAlcohol',
                       addiction NOTNULL AND addiction @> to_jsonb('92654fda-d485-4b6d-97c5-8a8fe2a9582a'::text) AND
                       baseline_status = 'null',
                       'baselineTobacco',
                       addiction NOTNULL AND addiction @> to_jsonb('ef29759b-5f74-4f5a-b186-fea7697cfb34'::text) AND
                       baseline_status = 'null',
                       'baselineBoth',
                       addiction NOTNULL AND addiction @> to_jsonb('246df73a-07d8-4924-8cf9-787dea8278fe'::text) AND
                       baseline_status = 'null',
                       'baselineNoAddiction',
                       addiction NOTNULL AND addiction @> to_jsonb('c7f89d3c-2aa3-4570-a7a5-163e002fba66'::text) AND
                       baseline_status = 'null',

                   -------------------------------------
                       'baselineAlcoholEndlineAlcohol',
                       addiction NOTNULL AND addiction @> to_jsonb('92654fda-d485-4b6d-97c5-8a8fe2a9582a'::text) AND
                       baseline_status = 'Alcohol',
                       'baselineAlcoholEndlineTobacco',
                       addiction NOTNULL AND addiction @> to_jsonb('ef29759b-5f74-4f5a-b186-fea7697cfb34'::text) AND
                       baseline_status = 'Alcohol',
                       'baselineAlcoholEndlineBoth',
                       addiction NOTNULL AND addiction @> to_jsonb('246df73a-07d8-4924-8cf9-787dea8278fe'::text) AND
                       baseline_status = 'Alcohol',
                       'baselineAlcoholEndlineQuitted',
                       addiction NOTNULL AND quitted @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text) AND
                       baseline_status = 'Alcohol',
                       'baselineAlcoholEndlineNoAddiction',
                       addiction NOTNULL AND addiction @> to_jsonb('c7f89d3c-2aa3-4570-a7a5-163e002fba66'::text) AND
                       baseline_status = 'Alcohol',
                       'baselineAlcoholEndlineDataNotCapture',
                       addiction ISNULL AND baseline_status = 'Alcohol',

                   -------------------
                       'baselineTobaccoEndlineAlcohol',
                       addiction NOTNULL AND addiction @> to_jsonb('92654fda-d485-4b6d-97c5-8a8fe2a9582a'::text) AND
                       baseline_status = 'Tobacco',
                       'baselineTobaccoEndlineTobacco',
                       addiction NOTNULL AND addiction @> to_jsonb('ef29759b-5f74-4f5a-b186-fea7697cfb34'::text) AND
                       baseline_status = 'Tobacco',
                       'baselineTobaccoEndlineBoth',
                       addiction NOTNULL AND addiction @> to_jsonb('246df73a-07d8-4924-8cf9-787dea8278fe'::text) AND
                       baseline_status = 'Tobacco',
                       'baselineTobaccoEndlineNoAddiction',
                       addiction NOTNULL AND addiction @> to_jsonb('c7f89d3c-2aa3-4570-a7a5-163e002fba66'::text) AND
                       baseline_status = 'Tobacco',
                       'baselineTobaccoEndlineQuitted',
                       addiction NOTNULL AND quitted @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text) AND
                       baseline_status = 'Tobacco',
                       'baselineTobaccoEndlineDataNotCapture',
                       addiction ISNULL AND baseline_status = 'Tobacco',

                   ------------------
                       'baselineBothEndlineAlcohol',
                       addiction NOTNULL AND addiction @> to_jsonb('92654fda-d485-4b6d-97c5-8a8fe2a9582a'::text) AND
                       baseline_status = 'Both',
                       'baselineBothEndlineTobacco',
                       addiction NOTNULL AND addiction @> to_jsonb('ef29759b-5f74-4f5a-b186-fea7697cfb34'::text) AND
                       baseline_status = 'Both',
                       'baselineBothEndlineBoth',
                       addiction NOTNULL AND addiction @> to_jsonb('246df73a-07d8-4924-8cf9-787dea8278fe'::text) AND
                       baseline_status = 'Both',
                       'baselineBothEndlineNoAddiction',
                       addiction NOTNULL AND addiction @> to_jsonb('c7f89d3c-2aa3-4570-a7a5-163e002fba66'::text) AND
                       baseline_status = 'Both',
                       'baselineBothEndlineQuitted',
                       addiction NOTNULL AND quitted @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text) AND
                       baseline_status = 'Both',
                       'baselineBothEndlineDataNotCapture',
                       addiction ISNULL AND baseline_status = 'Both',

                   ----------
                       'baselineNoAddictionEndlineAlcohol',
                       addiction NOTNULL AND addiction @> to_jsonb('92654fda-d485-4b6d-97c5-8a8fe2a9582a'::text) AND
                       baseline_status = 'No Addiction',
                       'baselineNoAddictionEndlineTobacco',
                       addiction NOTNULL AND addiction @> to_jsonb('ef29759b-5f74-4f5a-b186-fea7697cfb34'::text) AND
                       baseline_status = 'No Addiction',
                       'baselineNoAddictionEndlineBoth',
                       addiction NOTNULL AND addiction @> to_jsonb('246df73a-07d8-4924-8cf9-787dea8278fe'::text) AND
                       baseline_status = 'No Addiction',
                       'baselineNoAddictionEndlineNoAddiction',
                       addiction NOTNULL AND addiction @> to_jsonb('c7f89d3c-2aa3-4570-a7a5-163e002fba66'::text) AND
                       baseline_status = 'No Addiction',
                       'baselineNoAddictionEndlineQuitted',
                       addiction NOTNULL AND quitted @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text) AND
                       baseline_status = 'No Addiction',
                       'baselineNoAddictionEndlineDataNotCapture',
                       addiction ISNULL AND baseline_status = 'No Addiction'
                   ) as status_map,
               jsonb_build_object(
                       'addiction', addiction
                   ) as value_map,
               gender,
               baseline_year,
               visit_number,
               endline_year
        from all_events
    );


create or replace function sr_individual_prevalence_substance_misuse_indicator_matrix(status text, baseLineStatus text,
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

              from sr_individual_prevalence_substance_misuse_indicator_matrix s
              where baseline_year = $5
              group by baseline_year)
select baseline_year,
       baseline_status,
       format('%s (%s%%)', baseline, trunc((baseline::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
       baseline_ll,
       transition_to,
       endline_year_1,
       format('%s (%s%%)', transition_1, trunc((transition_1::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_1_ll,
       endline_year_2,
       format('%s (%s%%)', transition_2, trunc((transition_2::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_2_ll,
       endline_year_3,
       format('%s (%s%%)', transition_3, trunc((transition_3::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_3_ll,
       endline_year_4,
       format('%s (%s%%)', transition_4, trunc((transition_4::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_4_ll,
       endline_year_5,
       format('%s (%s%%)', transition_5, trunc((transition_5::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_5_ll,
       endline_year_6,
       format('%s (%s%%)', transition_6, trunc((transition_6::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_6_ll,
       endline_year_7,
       format('%s (%s%%)', transition_7, trunc((transition_7::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_7_ll
from data d;
$body$
    language sql;


------views and functions for Menstrual Hygiene Practices  reports
create or replace view sr_individual_menstrual_hygiene_indicator_matrix as
    (
        with partitioned_annual as (
            SELECT i.id                                                                   individual_id,
                   row_number() OVER (PARTITION BY i.id ORDER BY enc.encounter_date_time) rank,
                   encounter_date_time,
                   enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca'             material,
                   g.name                                                                 gender
            from program_encounter enc
                     join encounter_type enct on enc.encounter_type_id = enct.id
                     join program_enrolment enl on enc.program_enrolment_id = enl.id
                     join program p ON p.id = enl.program_id
                     join individual i on enl.individual_id = i.id
                     join gender g on i.gender_id = g.id
            WHERE p.id = 3
              AND enct.id = 7
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
                 where encounter_type_id = 47
                   and enl.is_voided = false
                   and enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             midline_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca',
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
                        enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_2_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 2
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_3_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 3
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_4_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 4
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_5_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 5
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_6_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 6
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_7_data(individual_id, material, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> 'a54fcfad-8656-46ae-9706-671a600eabca',
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
                     and enc.encounter_type_id = 88
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
                    AND b.material @> to_jsonb('6ebf2af2-38c6-4703-98c2-cba9f234b8f5'::text)
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
                   AND b.material @> to_jsonb('fa118efa-116e-471e-a9cc-f39eabbc0a57'::text)
             ),
             endline_for_baseline_old_cloth(individual_id, gender, material, baseline_year, visit_number,
                                            baseline_status,
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
                   AND b.material @> to_jsonb('968b26b8-a357-4960-8aa8-0db67a728481'::text)
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
                   AND b.material @> to_jsonb('99414d2a-b7b1-434d-9354-c3da69619d83'::text)
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
                       'baselineFalalin',
                       material NOTNULL AND material @> to_jsonb('6ebf2af2-38c6-4703-98c2-cba9f234b8f5'::text) AND
                       baseline_status = 'null',
                       'baselineSanitary',
                       material NOTNULL AND material @> to_jsonb('fa118efa-116e-471e-a9cc-f39eabbc0a57'::text) AND
                       baseline_status = 'null',
                       'baselineOldCloth',
                       material NOTNULL AND material @> to_jsonb('968b26b8-a357-4960-8aa8-0db67a728481'::text) AND
                       baseline_status = 'null',
                       'baselineKitPad',
                       material NOTNULL and material @> to_jsonb('99414d2a-b7b1-434d-9354-c3da69619d83'::text) AND
                       baseline_status = 'null',
                       'baselineDataNotCapture', material isnull AND baseline_status = 'null',
                   --------------------
                       'baselineFalalinEndlineFalalin',
                       material NOTNULL AND material @> to_jsonb('6ebf2af2-38c6-4703-98c2-cba9f234b8f5'::text) AND
                       baseline_status = 'Falalin',
                       'baselineFalalinEndlineSanitary',
                       material NOTNULL AND material @> to_jsonb('fa118efa-116e-471e-a9cc-f39eabbc0a57'::text) AND
                       baseline_status = 'Falalin',
                       'baselineFalalinEndlineOldCloth',
                       material NOTNULL AND material @> to_jsonb('968b26b8-a357-4960-8aa8-0db67a728481'::text) AND
                       baseline_status = 'Falalin',
                       'baselineFalalinEndlineKitPad',
                       material NOTNULL AND material @> to_jsonb('99414d2a-b7b1-434d-9354-c3da69619d83'::text) AND
                       baseline_status = 'Falalin',
                       'baselineFalalinEndlineDataNotCapture', material ISNULL AND baseline_status = 'Falalin',
                   -------------------
                       'baselineSanitaryEndlineFalalin',
                       material NOTNULL AND material @> to_jsonb('6ebf2af2-38c6-4703-98c2-cba9f234b8f5'::text) AND
                       baseline_status = 'Sanitary pad',
                       'baselineSanitaryEndlineSanitary',
                       material NOTNULL AND material @> to_jsonb('fa118efa-116e-471e-a9cc-f39eabbc0a57'::text) AND
                       baseline_status = 'Sanitary pad',
                       'baselineSanitaryEndlineOldCloth',
                       material NOTNULL AND material @> to_jsonb('968b26b8-a357-4960-8aa8-0db67a728481'::text) AND
                       baseline_status = 'Sanitary pad',
                       'baselineSanitaryEndlineKitPad',
                       material NOTNULL AND material @> to_jsonb('99414d2a-b7b1-434d-9354-c3da69619d83'::text) AND
                       baseline_status = 'Sanitary pad',
                       'baselineSanitaryEndlineDataNotCapture', material ISNULL AND baseline_status = 'Sanitary pad',
                   ------------------
                       'baselineOldClothEndlineFalalin',
                       material NOTNULL AND material @> to_jsonb('6ebf2af2-38c6-4703-98c2-cba9f234b8f5'::text) AND
                       baseline_status = 'Old cloth',
                       'baselineOldClothEndlineSanitary',
                       material NOTNULL AND material @> to_jsonb('fa118efa-116e-471e-a9cc-f39eabbc0a57'::text) AND
                       baseline_status = 'Old cloth',
                       'baselineOldClothEndlineOldCloth',
                       material NOTNULL AND material @> to_jsonb('968b26b8-a357-4960-8aa8-0db67a728481'::text) AND
                       baseline_status = 'Old cloth',
                       'baselineOldClothEndlineKitPad',
                       material NOTNULL AND material @> to_jsonb('99414d2a-b7b1-434d-9354-c3da69619d83'::text) AND
                       baseline_status = 'Old cloth',
                       'baselineOldClothEndlineDataNotCapture', material ISNULL AND baseline_status = 'Old cloth',
                   ------------------
                       'baselineKitPadEndlineFalalin',
                       material NOTNULL AND material @> to_jsonb('6ebf2af2-38c6-4703-98c2-cba9f234b8f5'::text) AND
                       baseline_status = 'Kit pad',
                       'baselineKitPadEndlineSanitary',
                       material NOTNULL AND material @> to_jsonb('fa118efa-116e-471e-a9cc-f39eabbc0a57'::text) AND
                       baseline_status = 'Kit pad',
                       'baselineKitPadEndlineOldCloth',
                       material NOTNULL AND material @> to_jsonb('968b26b8-a357-4960-8aa8-0db67a728481'::text) AND
                       baseline_status = 'Kit pad',
                       'baselineKitPadEndlineKitPad',
                       material NOTNULL AND material @> to_jsonb('99414d2a-b7b1-434d-9354-c3da69619d83'::text) AND
                       baseline_status = 'Kit pad',
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

              from sr_individual_menstrual_hygiene_indicator_matrix s
              where baseline_year = $5
              group by baseline_year)
select baseline_year,
       baseline_status,
       format('%s (%s%%)', baseline, trunc((baseline::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
       baseline_ll,
       transition_to,
       endline_year_1,
       format('%s (%s%%)', transition_1, trunc((transition_1::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_1_ll,
       endline_year_2,
       format('%s (%s%%)', transition_2, trunc((transition_2::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_2_ll,
       endline_year_3,
       format('%s (%s%%)', transition_3, trunc((transition_3::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_3_ll,
       endline_year_4,
       format('%s (%s%%)', transition_4, trunc((transition_4::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_4_ll,
       endline_year_5,
       format('%s (%s%%)', transition_5, trunc((transition_5::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_5_ll,
       endline_year_6,
       format('%s (%s%%)', transition_6, trunc((transition_6::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_6_ll,
       endline_year_7,
       format('%s (%s%%)', transition_7, trunc((transition_7::DECIMAL * 100) / nullif(baseline, 0), 2)),
       endline_7_ll
from data d;
$body$
    language sql;



-----views and functions for School Dropout Ratio
create or replace view sr_individual_School_Dropout_Ratio_indicator_matrix as
    (
        with partitioned_annual as (
            SELECT i.id                                                                   individual_id,
                   row_number() OVER (PARTITION BY i.id ORDER BY enc.encounter_date_time) rank,
                   encounter_date_time,
                   enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3'             schoolGoing,
                   g.name                                                                 gender
            from program_encounter enc
                     join encounter_type enct on enc.encounter_type_id = enct.id
                     join program_enrolment enl on enc.program_enrolment_id = enl.id
                     join program op ON op.id = enl.program_id
                     join individual i on enl.individual_id = i.id
                     join gender g on i.gender_id = g.id
            WHERE op.id = 3
              AND enct.id = 7
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
                 where encounter_type_id = 47
                   and enl.is_voided = false
                   and enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             midline_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3',
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
                        enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 1
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_2_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 2
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_3_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 3
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_4_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 4
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_5_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 5
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_6_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3',
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
                     and enc.encounter_type_id = 88
                     and enc.is_voided = false
                     and extract('year' from encounter_date_time) = baseline_year + 6
                 where enl.program_exit_date_time ISNULL
                   and enl.is_voided = false
             ),
             endline_7_data(individual_id, schoolGoing, baseline_year, visit_number, gender, endline_year) as (
                 select b.individual_id,
                        enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3',
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
                     and enc.encounter_type_id = 88
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
                    AND b.schoolGoing @> to_jsonb('58f789aa-6570-4aea-87a7-1f7651729c5a'::text)
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
                   AND b.schoolGoing @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text)
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
                       'baselinedropOut',
                       schoolGoing NOTNULL AND schoolGoing @> to_jsonb('58f789aa-6570-4aea-87a7-1f7651729c5a'::text) AND
                       baseline_status = 'null',
                       'baselineGoing',
                       schoolGoing NOTNULL AND schoolGoing @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text) AND
                       baseline_status = 'null',
                       'baselinedataNotCapture', schoolGoing ISNULL AND baseline_status = 'null',
                   -----DropuOut---------
                       'baselinedropOutEndlinedropOut',
                       schoolGoing NOTNULL AND schoolGoing @> to_jsonb('58f789aa-6570-4aea-87a7-1f7651729c5a'::text) AND
                       baseline_status = 'Dropped Out',
                       'baselinedropOutEndlineGoing',
                       schoolGoing NOTNULL AND schoolGoing @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text) AND
                       baseline_status = 'Dropped Out',
                       'baselinedropOutEndlineNotCapture', schoolGoing ISNULL AND baseline_status = 'Dropped Out',
                   -----SchooGoing----------
                       'baselineGoingEndlinedropOut',
                       schoolGoing NOTNULL AND schoolGoing @> to_jsonb('58f789aa-6570-4aea-87a7-1f7651729c5a'::text) AND
                       baseline_status = 'Going',
                       'baselineGoingEndlineGoing',
                       schoolGoing NOTNULL AND schoolGoing @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text) AND
                       baseline_status = 'Going',
                       'baselineGoingEndlineNotCapture', schoolGoing ISNULL AND baseline_status = 'Going',
                   ------DataNotCapture--------
                       'baselineNotCaptureEndlinedropOut',
                       schoolGoing NOTNULL AND schoolGoing @> to_jsonb('58f789aa-6570-4aea-87a7-1f7651729c5a'::text) AND
                       baseline_status = 'Data Not Capture',
                       'baselineNotCaptureEndlineGoing',
                       schoolGoing NOTNULL AND schoolGoing @> to_jsonb('04bb1773-c353-44a1-a68c-9b448e07ff70'::text) AND
                       baseline_status = 'Data Not Capture',
                       'baselineNotCaptureEndlineNotCapture',
                       schoolGoing ISNULL AND baseline_status = 'Data Not Capture'
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


--------Chronic Sickness-------------

create or replace view sr_chronic_sickness_matrix as
    (
        with partitioned_annual as (
            SELECT i.id                                                                   individual_id,
                   row_number() OVER (PARTITION BY i.id ORDER BY enc.encounter_date_time) rank,
                   encounter_date_time,
                   enc.observations -> 'b00a5ea2-e09c-43aa-b514-ac3c50474647' as          sickness,
                   enc.observations -> '575a29c3-a070-4c7d-ac96-fe58b6bddca3' as          schoolGoing,
                   g.name                                                                 gender
            from program_encounter enc
                     join encounter_type enct on enc.encounter_type_id = enct.id
                     join program_enrolment enl on enc.program_enrolment_id = enl.id
                     join program op ON op.id = enl.program_id
                     join individual i on enl.individual_id = i.id
                     join gender g on i.gender_id = g.id
            WHERE op.id = 3
              AND (enct.id = 7 or enct.id = 8)
              and enc.observations ->> 'b00a5ea2-e09c-43aa-b514-ac3c50474647' notnull
              and '[
              "3505bbe2-e276-4f1b-a0d9-5c22ce160fd4",
              "4cb9f91e-c8f8-4e9f-8c4b-544d94b5afa5",
              "00ff88d0-d8bd-493b-98e2-fe60f6f9ce66",
              "a34bf7a0-4d55-41fa-855a-0b8094f369f7",
              "05ea583c-51d2-412d-ad00-06c432ffe538"
            ]'::jsonb @> (enc.observations -> 'b00a5ea2-e09c-43aa-b514-ac3c50474647')
              AND enc.encounter_date_time NOTNULL
              and enc.is_voided = false
              and enl.program_exit_date_time ISNULL
              and enl.is_voided = false
              and i.is_voided = false
        ),
             baseline_data (individual_id, gender, schoolGoing, sickness, hospitalvisited, Reason, cured, Treatment,
                            baseline_year, visit_number, baseline_status,
                            endline_year)
                 as (
                 select pa.individual_id,
                        pa.gender,
                        pa.schoolGoing,
                        pa.sickness,
                        phd.hospitalvisited,
                        phd.Reason,
                        phd.cured,
                        phd.Treatment,
                        extract('year' from phd.enrolmentDate),
                        0,
                        'null'::TEXT,
                        0
                 from partitioned_annual pa
                          join sr_partitioned_hospital_data_view phd
                               on phd.individual_id = pa.individual_id and rank2 = 1
                 where rank = 1
             ),

             endline_for_baseline_heartProblem
                 (individual_id, gender, schoolGoing, sickness, hospitalvisited, Reason, cured, Treatment,
                  baseline_year,
                  visit_number, baseline_status,
                  endline_year)
                 as
                 (select b.individual_id,
                         b.gender,
                         b.schoolGoing,
                         b.sickness,
                         b.hospitalvisited,
                         b.Reason,
                         b.cured,
                         b.Treatment,

                         b.baseline_year,
                         0,
                         'Heart problem'::TEXT,
                         0
                  from baseline_data b

                  where b.sickness NOTNULL
                    AND b.sickness @> to_jsonb('3505bbe2-e276-4f1b-a0d9-5c22ce160fd4'::text)
                 ),
             endline_for_baseline_kidneyProblem(individual_id, gender, schoolGoing, sickness, hospitalvisited, Reason,
                                                cured,
                                                Treatment, baseline_year, visit_number, baseline_status,
                                                endline_year) as (
                 select b.individual_id,
                        b.gender,
                        b.schoolGoing,
                        b.sickness,
                        b.hospitalvisited,
                        b.Reason,
                        b.cured,
                        b.Treatment,

                        b.baseline_year,
                        0,
                        'Kidney problem'::TEXT,
                        0
                 from baseline_data b

                 where b.sickness NOTNULL
                   AND b.sickness @> to_jsonb('4cb9f91e-c8f8-4e9f-8c4b-544d94b5afa5'::text)
             ),
             endline_for_baseline_sickleCellDisease(individual_id, gender, schoolGoing, sickness, hospitalvisited,
                                                    Reason,
                                                    cured, Treatment, baseline_year, visit_number, baseline_status,
                                                    endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.schoolGoing,
                        b.sickness,
                        b.hospitalvisited,
                        b.Reason,
                        b.cured,
                        b.Treatment,

                        b.baseline_year,
                        0,
                        'Sickle cell disease'::TEXT,
                        0
                 from baseline_data b

                 where b.sickness NOTNULL
                   AND b.sickness @> to_jsonb('00ff88d0-d8bd-493b-98e2-fe60f6f9ce66'::text)
             ),
             endline_for_baseline_epilepsy(individual_id, gender, schoolGoing, sickness, hospitalvisited, Reason, cured,
                                           Treatment, baseline_year, visit_number, baseline_status,
                                           endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.schoolGoing,
                        b.sickness,
                        b.hospitalvisited,
                        b.Reason,
                        b.cured,
                        b.Treatment,

                        b.baseline_year,
                        0,
                        'Epilepsy'::TEXT,
                        0
                 from baseline_data b

                 where b.sickness NOTNULL
                   AND b.sickness @> to_jsonb('a34bf7a0-4d55-41fa-855a-0b8094f369f7'::text)
             ),
             endline_for_baseline_other(individual_id, gender, schoolGoing, sickness, hospitalvisited, Reason, cured,
                                        Treatment,
                                        baseline_year, visit_number, baseline_status,
                                        endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.schoolGoing,
                        b.sickness,
                        b.hospitalvisited,
                        b.Reason,
                        b.cured,
                        b.Treatment,

                        b.baseline_year,
                        0,
                        'Other'::TEXT,
                        0
                 from baseline_data b

                 where b.sickness NOTNULL
                   AND b.sickness @> to_jsonb('05ea583c-51d2-412d-ad00-06c432ffe538'::text)
             ),
             all_events as (select *
                            from baseline_data
                            union all
                            select *
                            from endline_for_baseline_heartProblem
                            union all
                            select *
                            from endline_for_baseline_kidneyProblem
                            union all
                            select *
                            from endline_for_baseline_sickleCellDisease
                            union all
                            select *
                            from endline_for_baseline_epilepsy
                            union all
                            select *
                            from endline_for_baseline_other
             )

        select individual_id,
               jsonb_build_object(
                       'baselineHeartProblem',
                       sickness NOTNULL AND sickness @> to_jsonb('3505bbe2-e276-4f1b-a0d9-5c22ce160fd4'::text) AND baseline_status = 'null',
                       'baselineKidneyProblem',
                       sickness NOTNULL AND sickness @> to_jsonb('4cb9f91e-c8f8-4e9f-8c4b-544d94b5afa5'::text) AND baseline_status = 'null',
                       'baselineSickleCellDisease',
                       sickness NOTNULL AND sickness @> to_jsonb('00ff88d0-d8bd-493b-98e2-fe60f6f9ce66'::text) AND baseline_status = 'null',
                       'baselineEpilepsy', sickness NOTNULL and sickness @> to_jsonb('a34bf7a0-4d55-41fa-855a-0b8094f369f7'::text) AND baseline_status = 'null',
                       'baselineOther', sickness NOTNULL and sickness @> to_jsonb('05ea583c-51d2-412d-ad00-06c432ffe538'::text) AND baseline_status = 'null'
                   ) as status_map,
               jsonb_build_object(
                       'sickness', sickness
                   ) as value_map,
               gender,
               baseline_year,
               visit_number,
               endline_year
        from all_events
    );

create or replace function sr_record_from_chronic_sickness(status text, baseLineStatus text, transition text,
                                                           transitionTo text,
                                                           baselineYear int, lineListQuestionNumber int)
    returns table
            (
                baseline_year   float,
                baseline_status text,
                baseline_male   text,
                baseline_female text,
                baseline_other  text,
                baseline        text,
                baseline_ll     text

            )
as
$body$
with data as (select baseline_year                                                             as baseline_year,
                     $1                                                                        as baseline_status,
                     count(distinct s.individual_id) filter ( where visit_number = 0 )         as baselined_individuals,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true)                       as baseline,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true and gender = 'Male')   as baseline_male,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true and gender = 'Female') as baseline_female,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true and gender = 'Other')  as baseline_other,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=0&baseline_year=%s', $6,
                            $2,
                            $5)::TEXT                                                          as baseline_ll

              from sr_chronic_sickness_matrix s
              where baseline_year = $5
              group by baseline_year)
select baseline_year,
       baseline_status,
       format('%s (%s%%)', baseline_male, trunc((baseline_male::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
       format('%s (%s%%)', baseline_female,
              trunc((baseline_female::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
       format('%s (%s%%)', baseline_other,
              trunc((baseline_other::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
       format('%s (%s%%)', (baseline_male + baseline_female + baseline_other),
              trunc(((baseline_male + baseline_female + baseline_other)::DECIMAL * 100) /
                    nullif(baselined_individuals, 0), 2)),
       baseline_ll

from data d;
$body$
    language sql;


--------Adolescent with Menstrual Disorder-------------
create or replace view sr_menstrual_disorder_matrix as
    (
        with partitioned_annual as (
            SELECT i.id                                                                   individual_id,
                   row_number() OVER (PARTITION BY i.id ORDER BY enc.encounter_date_time) rank,
                   encounter_date_time,
                   enc.observations -> '0f87eac1-cf6a-4632-8af2-29a935451fe4'             disorder,
                   g.name                                                                 gender,
                   enl.enrolment_date_time
            from program_encounter enc
                     join encounter_type enct on enc.encounter_type_id = enct.id
                     join program_enrolment enl on enc.program_enrolment_id = enl.id
                     join program op ON op.id = enl.program_id
                     join individual i on enl.individual_id = i.id
                     join gender g on i.gender_id = g.id
            WHERE op.id = 3
              AND (enct.id = 7 or enct.id = 8)
              and enc.observations -> '0f87eac1-cf6a-4632-8af2-29a935451fe4' notnull
              and '[
              "92ad8878-b476-4291-aa76-3377fa7cf19c",
              "33385edf-93bc-4513-aa03-480ce3bc7b5c",
              "1c478c50-4761-460c-b33c-a18d0c1500f7",
              "761b7f7a-5db7-4115-aa84-32fcfce5ddfc",
              "aa30fb91-4b64-438b-b09e-4c7ff2701d71",
              "ce47ae12-e61c-49cc-8ccd-715f9d5cb76d",
              "4085f165-ccb8-409b-9d6e-ea7755cf123e",
              "e27f4a35-c2ae-4d05-8930-e19e432221d1"
            ]'::jsonb @> (enc.observations -> '0f87eac1-cf6a-4632-8af2-29a935451fe4')
              AND enc.encounter_date_time NOTNULL
              and enc.is_voided = false
              and enl.program_exit_date_time ISNULL
              and enl.is_voided = false
              and i.is_voided = false
        ),

             baseline_data (individual_id, gender, disorder, baseline_year, visit_number, baseline_status,
                            endline_year)
                 as (
                 select pa.individual_id,
                        pa.gender,
                        pa.disorder,
                        extract('year' from pa.enrolment_date_time),
                        0,
                        'null'::TEXT,
                        0
                 from partitioned_annual pa

                 where rank = 1
             ),

             endline_for_baseline_lowerAbdominalPain
                 (individual_id, gender, disorder, baseline_year, visit_number, baseline_status,
                  endline_year)
                 as
                 (select b.individual_id,
                         b.gender,
                         b.disorder,
                         b.baseline_year,
                         0,
                         'Lower abdominal pain'::TEXT,
                         0
                  from baseline_data b

                  where b.disorder NOTNULL
                    AND b.disorder @> to_jsonb('92ad8878-b476-4291-aa76-3377fa7cf19c'::text)
                 ),
             endline_for_baseline_Backache(individual_id, gender, disorder, baseline_year, visit_number,
                                           baseline_status,
                                           endline_year) as (
                 select b.individual_id,
                        b.gender,
                        b.disorder,
                        b.baseline_year,
                        0,
                        'Backache'::TEXT,
                        0
                 from baseline_data b
                 where b.disorder NOTNULL
                   AND b.disorder @> to_jsonb('33385edf-93bc-4513-aa03-480ce3bc7b5c'::text)
             ),
             endline_for_baseline_legPain(individual_id, gender, disorder, baseline_year, visit_number,
                                          baseline_status,
                                          endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.disorder,
                        b.baseline_year,
                        0,
                        'Leg pain'::TEXT,
                        0
                 from baseline_data b
                 where b.disorder NOTNULL
                   AND b.disorder @> to_jsonb('1c478c50-4761-460c-b33c-a18d0c1500f7'::text)
             ),
             endline_for_baseline_nauseaAndVomiting(individual_id, gender, disorder, baseline_year, visit_number,
                                                    baseline_status,
                                                    endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.disorder,
                        b.baseline_year,
                        0,
                        'Nausea and vomiting'::TEXT,
                        0
                 from baseline_data b
                 where b.disorder NOTNULL
                   AND b.disorder @> to_jsonb('761b7f7a-5db7-4115-aa84-32fcfce5ddfc'::text)
             ),
             endline_for_baseline_Headache(individual_id, gender, disorder, baseline_year, visit_number,
                                           baseline_status,
                                           endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.disorder,
                        b.baseline_year,
                        0,
                        'Headache'::TEXT,
                        0
                 from baseline_data b
                 where b.disorder NOTNULL
                   AND b.disorder @> to_jsonb('4085f165-ccb8-409b-9d6e-ea7755cf123e'::text)
             ),
             endline_for_baseline_abnormalVaginalDischarge(individual_id, gender, disorder, baseline_year, visit_number,
                                                           baseline_status,
                                                           endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.disorder,
                        b.baseline_year,
                        0,
                        'Abnormal vaginal discharge'::TEXT,
                        0
                 from baseline_data b
                 where b.disorder NOTNULL
                   AND b.disorder @> to_jsonb('aa30fb91-4b64-438b-b09e-4c7ff2701d71'::text)
             ),
             endline_for_baseline_heavyBleeding(individual_id, gender, disorder, baseline_year, visit_number,
                                                baseline_status,
                                                endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.disorder,
                        b.baseline_year,
                        0,
                        'Heavy bleeding'::TEXT,
                        0
                 from baseline_data b
                 where b.disorder NOTNULL
                   AND b.disorder @> to_jsonb('e27f4a35-c2ae-4d05-8930-e19e432221d1'::text)
             ),
             endline_for_baseline_irregularMenses(individual_id, gender, disorder, baseline_year, visit_number,
                                                  baseline_status,
                                                  endline_year)
                 as (
                 select b.individual_id,
                        b.gender,
                        b.disorder,
                        b.baseline_year,
                        0,
                        'Irregular menses'::TEXT,
                        0
                 from baseline_data b
                 where b.disorder NOTNULL
                   AND b.disorder @> to_jsonb('ce47ae12-e61c-49cc-8ccd-715f9d5cb76d'::text)
             ),
             all_events as (select *
                            from baseline_data
                            union all
                            select *
                            from endline_for_baseline_lowerAbdominalPain
                            union all
                            select *
                            from endline_for_baseline_Backache
                            union all
                            select *
                            from endline_for_baseline_legPain
                            union all
                            select *
                            from endline_for_baseline_nauseaAndVomiting
                            union all
                            select *
                            from endline_for_baseline_Headache
                            union all
                            select *
                            from endline_for_baseline_abnormalVaginalDischarge
                            union all
                            select *
                            from endline_for_baseline_heavyBleeding
                            union all
                            select *
                            from endline_for_baseline_irregularMenses
             )

        select individual_id,
               jsonb_build_object(
                       'baselinelowerAbdominalPain',
                       disorder NOTNULL AND disorder @> to_jsonb('92ad8878-b476-4291-aa76-3377fa7cf19c'::text) AND
                       baseline_status = 'null',
                       'baselineBackache',
                       disorder NOTNULL AND disorder @> to_jsonb('33385edf-93bc-4513-aa03-480ce3bc7b5c'::text) AND
                       baseline_status = 'null',
                       'baselinelegPain',
                       disorder NOTNULL AND disorder @> to_jsonb('1c478c50-4761-460c-b33c-a18d0c1500f7'::text) AND
                       baseline_status = 'null',
                       'baselinenauseaAndVomiting',
                       disorder NOTNULL and disorder @> to_jsonb('761b7f7a-5db7-4115-aa84-32fcfce5ddfc'::text) AND
                       baseline_status = 'null',
                       'baselineHeadache',
                       disorder NOTNULL and disorder @> to_jsonb('4085f165-ccb8-409b-9d6e-ea7755cf123e'::text) AND
                       baseline_status = 'null',
                       'baselineabnormalVaginalDischarge',
                       disorder NOTNULL and disorder @> to_jsonb('aa30fb91-4b64-438b-b09e-4c7ff2701d71'::text) AND
                       baseline_status = 'null',
                       'baselineheavyBleeding',
                       disorder NOTNULL and disorder @> to_jsonb('e27f4a35-c2ae-4d05-8930-e19e432221d1'::text) AND
                       baseline_status = 'null',
                       'baselineirregularMenses',
                       disorder NOTNULL and disorder @> to_jsonb('ce47ae12-e61c-49cc-8ccd-715f9d5cb76d'::text) AND
                       baseline_status = 'null'
                   ) as status_map,
               jsonb_build_object(
                       'disorder', disorder
                   ) as value_map,
               gender,
               baseline_year,
               visit_number,
               endline_year
        from all_events
    );

create or replace function sr_record_from_menstrual_disorder_matrix(status text, baseLineStatus text, transition text,
                                                                    transitionTo text,
                                                                    baselineYear int, lineListQuestionNumber int)
    returns table
            (
                baseline_year   float,
                baseline_status text,
                baseline        text,
                baseline_ll     text

            )
as
$body$
with data as (select baseline_year                                                     as baseline_year,
                     $1                                                                as baseline_status,
                     count(distinct s.individual_id) filter ( where visit_number = 0 ) as baselined_individuals,
                     count(distinct s.individual_id)
                     filter ( where (status_map ->> $2)::boolean = true)               as baseline,
                     format('https://reporting.openchs.org/question/%s?status=%s&visit_number=0&baseline_year=%s', $6,
                            $2,
                            $5)::TEXT                                                  as baseline_ll

              from sr_menstrual_disorder_matrix s
              where baseline_year = $5
              group by baseline_year)
select baseline_year,
       baseline_status,
       format('%s (%s%%)', baseline, trunc((baseline::DECIMAL * 100) / nullif(baselined_individuals, 0), 2)),
       baseline_ll

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

create view sr_completed_program_encounters as (
    SELECT i.id             AS individual_id,
           i.address_id,
           i.observations   AS individual_observations,
           i.date_of_birth,
           i.date_of_birth_verified,
           i.gender_id,
           i.registration_date,
           i.first_name,
           i.last_name,
           i.is_voided      AS individual_voided,
           i.facility_id,
           i.registration_location,
           i.subject_type_id,
           i.full_name,
           i.gender,
           i.addresslevel_name,
           i.addresslevel_level,
           i.addresslevel_uuid,
           i.addresslevel_is_voided,
           i.addresslevel_type,
           i.addresslevel_type_uuid,
           i.addresslevel_type_is_voided,
           enl.id           AS enrolment_id,
           enl.program_id,
           enl.program_outcome_id,
           enl.observations AS program_enrolment_observations,
           enl.program_exit_observations,
           enl.enrolment_date_time,
           enl.program_exit_date_time,
           enl.is_voided    AS program_enrolment_voided,
           enl.enrolment_location,
           enl.exit_location,
           enl.operational_program_uuid,
           enl.operational_program_name,
           enl.operational_program_is_voided,
           enl.program_uuid,
           enl.program_name,
           enl.program_is_voided,
           enc.id           AS program_encounter_id,
           enc.observations AS program_encounter_observations,
           enc.earliest_visit_date_time,
           enc.encounter_date_time,
           enc.program_enrolment_id,
           enc.encounter_type_id,
           enc.name,
           enc.max_visit_date_time,
           enc.cancel_date_time,
           enc.cancel_observations,
           enc.is_voided    AS program_encounter_voided,
           enc.encounter_location,
           enc.cancel_location,
           enc.operational_encounter_type_uuid,
           enc.operational_encounter_type_name,
           enc.operational_encounter_type_is_voided,
           enc.encounter_type_uuid,
           enc.encounter_type_name,
           enc.encounter_type_is_voided
    FROM completed_program_encounter_view enc
             JOIN program_enrolment_view enl ON enl.id = enc.program_enrolment_id
             JOIN individual_gender_address_view i ON i.id = enl.individual_id
);

create or replace view sr_partitioned_addiction_view as (
    SELECT enl.individual_id                                                                        individual_id,
           row_number() OVER (PARTITION BY enl.individual_id ORDER BY enc.encounter_date_time desc) rank2,
           encounter_date_time,
           enc.observations -> '7593f241-b3c8-4b5c-8176-c9dfac3d4396'                               quitted
    from program_encounter enc
             join encounter_type enct on enc.encounter_type_id = enct.id
             join program_enrolment enl on enc.program_enrolment_id = enl.id
             join program p ON p.id = enl.program_id
    WHERE p.id = 3
      AND enct.id = 60
      AND enc.encounter_date_time NOTNULL
      and enc.is_voided = false
      and enl.program_exit_date_time ISNULL
      and enl.is_voided = false
);

create or replace view sr_partitioned_hospital_data_view as (
    select individual_id,
           enc.observations -> 'f96ee9f1-5035-4cbc-87f2-be3c6a19463f'                       as hospitalvisited,
           enc.observations -> '03400ffc-68ab-4b1e-9f45-0a38ce52ca41'                       as Treatment,
           enc.observations -> '56d43609-c80f-4ed9-8d6e-0feb8e05e368'                       as cured,
           enc.observations -> 'f6f45dde-274c-452b-9d40-ee3993303ab6'                       as Reason,
           enl.enrolment_date_time                                                          as enrolmentDate,
           row_number() over (partition by individual_id order by encounter_date_time desc) as rank2
    from program_encounter enc
             join encounter_type et on et.id = enc.encounter_type_id
             join program_enrolment enl on enc.program_enrolment_id = enl.id
    where et.id = 55
      and enl.program_exit_date_time isnull
      and enc.encounter_date_time notnull
      and not enc.is_voided
      and not enl.is_voided
);

set role none;
