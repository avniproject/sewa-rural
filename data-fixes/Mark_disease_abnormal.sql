set role none ;
with audits as (
    update concept_answer
        set abnormal = true
        where concept_id = (select id from concept where name = 'Sickling Test Result' and concept.organisation_id=1)
            and answer_concept_id = (select id from concept where name = 'Disease' and concept.organisation_id=1)
            and organisation_id=1
        returning audit_id
)
update audit
set last_modified_date_time = current_timestamp
where id = (select audit_id from audits);
