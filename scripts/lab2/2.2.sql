create or replace trigger students_update
    before update
                      on students
                      for each row
begin
    if :old.id != :new.id then
        RAISE_APPLICATION_ERROR(-20001, 'Student id cannot be changed.');
end if;
end students_update;
/
