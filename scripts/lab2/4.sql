create table students_logs(
                              student_id number,
                              old_name varchar2(100),
                              new_name varchar2(100),
                              old_group_id number,
                              new_group_id number,
                              action varchar2(6),
                              time date
);

create or replace trigger students_logs
    before insert or update or delete
    on students
    for each row
declare
    pragma autonomous_transaction;
begin
    if inserting then
        insert into students_logs values(:new.id, null, :new.name, null, :new.group_id, 'insert', sysdate);
    elsif updating then
        insert into students_logs values(:old.id, :old.name, :new.name, :old.group_id, :new.group_id, 'update', sysdate);
    elsif deleting then
        insert into students_logs values(:old.id, :old.name, null, :old.group_id, null, 'delete', sysdate);
    end if;
    commit;
end students_logs;
/
