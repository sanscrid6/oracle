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
/
