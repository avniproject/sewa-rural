set time zone 'asia/kolkata';

with may_quarterly_scheduled_enrolments as (
    select distinct pe.id as program_enrolment_id
    from program_enrolment pe
             join program_encounter p on pe.id = p.program_enrolment_id
             join encounter_type et on p.encounter_type_id = et.id
    where et.name = 'Quarterly Visit'
      and encounter_date_time isnull
      and cancel_date_time isnull
      and extract('year' from earliest_visit_date_time) = 2020
      and extract('month' from earliest_visit_date_time) = 5
      and pe.program_exit_date_time isnull
)
insert
into program_encounter (observations,
                        earliest_visit_date_time,
                        max_visit_date_time,
                        program_enrolment_id,
                        uuid,
                        version,
                        encounter_type_id,
                        name,
                        organisation_id,
                        audit_id)
select jsonb '{}',
       TIMESTAMPTZ '2020-03-01',
       TIMESTAMPTZ '2020-04-01',
       program_enrolment_id,
       uuid_generate_v4(),
       1,
       88,
       'Endline Visit',
       7,
       create_audit((select id from users where username = 'adminsr'))
from may_quarterly_scheduled_enrolments;