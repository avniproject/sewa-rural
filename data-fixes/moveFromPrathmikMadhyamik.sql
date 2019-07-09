with updates as (
  update individual
    set address_id = (select id from address_level where title='કપલસાડી માધ્યમિક')
    where address_id=(select id from address_level where title='કપલસાડી પ્રાથમિક')
    returning audit_id
)
update audit
set last_modified_date_time=current_timestamp
where id in (select updates.audit_id from updates);

with updates as (
  update individual
    set address_id = (select id from address_level where title='ગોવાલી માધ્યમિક')
    where address_id=(select id from address_level where title='ગોવાલી પ્રાથમિક')
    returning audit_id
)
update audit
set last_modified_date_time=current_timestamp
where id in (select updates.audit_id from updates);

with updates as (
  update individual
    set address_id = (select id from address_level where title='દરિયા માધ્યમિક')
    where address_id=(select id from address_level where title='દરિયા પ્રાથમિક')
    returning audit_id
)
update audit
set last_modified_date_time=current_timestamp
where id in (select updates.audit_id from updates);

with updates as (
  update individual
    set address_id = (select id from address_level where title='અમલઝર માધ્યમિક')
    where address_id=(select id from address_level where title='અમલઝર પ્રાથમિક')
    returning audit_id
)
update audit
set last_modified_date_time=current_timestamp
where id in (select updates.audit_id from updates)

with updates as (
  update individual
    set address_id = (select id from address_level where title='ધારોલી માધ્યમિક')
    where address_id=(select id from address_level where title='ધારોલી પ્રાથમિક')
    returning audit_id
)
update audit
set last_modified_date_time=current_timestamp
where id in (select updates.audit_id from updates)