create or replace trigger students_control
    before insert or update or delete
                     on students
                         for each row
declare
    pragma autonomous_transaction;
begin
    if inserting then
        update groups set c_val = c_val + 1 where id = :new.group_id;
    elsif updating then
        if :old.group_id != :new.group_id then
            update groups set c_val = c_val - 1 where id = :old.group_id;
            update groups set c_val = c_val + 1 where id = :new.group_id;
        end if;
    elsif deleting then
        update groups set c_val = c_val - 1 where id = :old.group_id;
    end if;
    commit;
end students_control;
