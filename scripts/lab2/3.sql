create or replace trigger groups_delete
    before delete
    on groups
    for each row
begin
    delete from students where group_id = :old.id;
end groups_delete;
/
