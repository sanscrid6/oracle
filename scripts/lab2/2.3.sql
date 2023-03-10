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
