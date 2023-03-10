create or replace procedure restore_students(start_time date, finish_time date) is
    cursor records is
    select *
    from students_logs
    where time between start_time and finish_time
    order by time desc;
begin
    execute immediate 'alter trigger students_insert disable';
    execute immediate 'alter trigger students_logs disable';
    for record in records
        loop
            if record.action = 'insert' then
                delete from students where id = record.student_id;
            elsif record.action = 'update' then
                update students set name = record.old_name, group_id = record.old_group_id where id = record.student_id;
            else
                insert into students values(record.student_id, record.old_name, record.old_group_id);
            end if;
        end loop;
    execute immediate 'alter trigger students_insert enable';
    execute immediate 'alter trigger students_logs enable';
end restore_students;

begin
    restore_students(to_date('2023-02-00 00:00:00', 'yyyy-mm-dd hh24:mi:ss'), to_date('2023-02-00 00:00:00', 'yyyy-mm-dd hh24:mi:ss'));
end;
