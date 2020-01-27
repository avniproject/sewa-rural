with audit_ids as (update program_encounter set is_voided = true
    where id = 432005 returning audit_id)
update audit
set last_modified_date_time = current_timestamp
where id in ((select audit_id from audit_ids));

insert into program_encounter (observations,
                               earliest_visit_date_time,
                               max_visit_date_time,
                               program_enrolment_id,
                               uuid,
                               version,
                               encounter_type_id,
                               name,
                               organisation_id,
                               audit_id)
values (jsonb'{}',
        TIMESTAMPTZ '2020-01-27',
        TIMESTAMPTZ '2020-02-27',
        33283,
        uuid_generate_v4(),
        1,
        8,
        'Quarterly Visit',
        7,
        create_audit((select id from users where username = 'adminsr')));