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
create view anemia_status as (select *
                              from sr_observations
                              where concept = 'Anemia Status');

drop view if exists school_going;
create view school_going as (select *
                             from sr_observations
                             where concept = 'School going');

drop view if exists sickling_result;
create view sickling_result as (select *
                                from sr_observations
                                where concept = 'Sickling Test Result');

drop view if exists addiction_details;
create view addiction_details as (select *
                                  from sr_observations
                                  where concept = 'Addiction Details');

drop view if exists menstrual_disorders;
create view menstrual_disorders as (select *
                                    from sr_observations
                                    where concept = 'Menstrual disorders');

drop view if exists chronic_sickness;
create view chronic_sickness as (select *
                                 from sr_observations
                                 where concept = 'Chronic Sickness');

set role none;
