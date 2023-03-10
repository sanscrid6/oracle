create or replace trigger groups_update
    before update
                      on groups
                      for each row
begin
    if :old.id != :new.id then
        RAISE_APPLICATION_ERROR(-20001, 'Group id cannot be changed.');
    end if;

    if :old.name != :new.name then
        RAISE_APPLICATION_ERROR(-20001, 'Group name cannot be changed.');
    end if;
end groups_update;
/
