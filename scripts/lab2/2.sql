create or replace trigger students_insert
    before insert
    on students
    for each row
declare
    amount number;
    last_id number;
begin
    select count(*) into amount from students;
    if amount = 0 then
        :new.id := 1;
    else
        select max(id) into last_id from students;
        if :new.id > last_id then
            :new.id := last_id + 1;
    elsif :new.id > 0 then
        select count(*) into amount from students where id = :new.id;
        if amount > 0 then
                :new.id := last_id + 1;
        end if;
        else
            :new.id := last_id + 1;
        end if;
    end if;
end students_insert;

create or replace trigger students_update
    before update
                      on students
                      for each row
begin
    if :old.id != :new.id then
        RAISE_APPLICATION_ERROR(-20001, 'Student id cannot be changed.');
    end if;
end students_update;

create or replace trigger groups_insert
    before insert
    on groups
    for each row
declare
    amount number;
    last_id number;
begin
    select count(*) into amount from groups where name = :new.name;
    if amount = 0 then
        select count(*) into amount from groups;
        if amount = 0 then
            :new.id := 1;
        else
            select max(id) into last_id from groups;
            if :new.id > last_id then
                :new.id := last_id + 1;
            elsif :new.id > 0 then
                select count(*) into amount from groups where id = :new.id;
                if amount > 0 then
                    :new.id := last_id + 1;
                end if;
            else
                :new.id := last_id + 1;
            end if;
        end if;
    else
        RAISE_APPLICATION_ERROR(-20001, 'This group name is already exists.');
    end if;
end groups_insert;

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
