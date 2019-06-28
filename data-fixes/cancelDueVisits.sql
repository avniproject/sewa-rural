with updates as (
  update program_encounter set cancel_date_time = current_timestamp, cancel_observations =
      '{"86e9677d-a944-4bfd-b873-224229a3a240": "Automatically cancelled", "afc5f9db-6c89-40b4-8122-02fb43c9348c": "05ea583c-51d2-412d-ad00-06c432ffe538"}'
    where earliest_visit_date_time is not null
      and max_visit_date_time is not null
      and encounter_date_time is null
      and cancel_date_time is null
      and earliest_visit_date_time < current_timestamp
      and is_voided=false
      and organisation_id = 7
    returning audit_id
)
update audit
set last_modified_date_time = current_timestamp
where id in (select updates.audit_id from updates);