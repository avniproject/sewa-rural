select create_db_user('sewa_rural', 'password');

INSERT into organisation(name, db_user, uuid, parent_organisation_id)
SELECT 'Sewa Rural Old', 'sewa_rural', 'b5399a48-60c4-4cea-b19e-d824c9dd00f5', id
FROM organisation
WHERE name = 'OpenCHS' and not exists (select 1 from organisation where name = 'Sewa Rural Old');