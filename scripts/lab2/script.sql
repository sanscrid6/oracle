/*1*/
CREATE TABLE groups (
  id NUMBER,
  name VARCHAR2(255),
  c_val NUMBER
);

CREATE TABLE students (
  id NUMBER,
  name VARCHAR2(255),
  group_id NUMBER
);

/*2*/
CREATE SEQUENCE groups_seq START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER groups_trigger
BEFORE INSERT ON groups
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
  SELECT groups_seq.NEXTVAL
  INTO :new.id
  FROM dual;
  
  SELECT count(*) INTO id_count FROM groups where id = :new.id;

  IF id_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'ID already exists');
  END IF;
END;
/

CREATE SEQUENCE students_seq START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER students_trigger
BEFORE INSERT ON students
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
  SELECT students_seq.NEXTVAL
  INTO :new.id
  FROM dual;
  SELECT count(*) INTO id_count FROM students where id = :new.id;

  IF id_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'ID already exists');
  END IF;
END;
/

CREATE OR REPLACE TRIGGER groups_name_trigger
BEFORE INSERT OR UPDATE ON groups
FOR EACH ROW
DECLARE
  name_count INTEGER;
  pragma autonomous_transaction;
BEGIN
  SELECT COUNT(*) INTO name_count FROM groups WHERE name = :new.name;
  IF name_count > 1 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Name already exists');
  END IF;
  commit;
END;

/*3*/
CREATE OR REPLACE TRIGGER students_group_id_trigger
BEFORE DELETE ON groups
FOR EACH ROW
DECLARE
    pragma autonomous_transaction;
BEGIN
  DELETE FROM students WHERE group_id = :old.id;
  COMMIT;
END;
/

/*4*/
CREATE TABLE students_log(
    id NUMBER,
    old_name VARCHAR2(255),
    name VARCHAR2(255),
    old_group_id VARCHAR2(255),
    group_id NUMBER,
    operation VARCHAR(10),
    t TIMESTAMP
);


CREATE OR REPLACE TRIGGER students_log_trigger_i
AFTER INSERT ON students
FOR EACH ROW
DECLARE
    pragma autonomous_transaction;
BEGIN
    INSERT INTO students_log (id, old_name, old_group_id, name, group_id, operation, t)
    VALUES (:new.id, null, null, :new.name, :new.group_id, 'INSERT', SYSDATE);
  COMMIT;
END;

CREATE OR REPLACE TRIGGER students_log_trigger
BEFORE DELETE OR UPDATE ON students
FOR EACH ROW
DECLARE
    pragma autonomous_transaction;
BEGIN
  IF UPDATING THEN
    INSERT INTO students_log (id, old_name, old_group_id, name, group_id, operation, t)
    VALUES (:old.id, :old.name, :old.group_id, :new.name, :new.group_id, 'UPDATE', SYSDATE);
  ELSE 
    INSERT INTO students_log (id, old_name, old_group_id, name, group_id, operation, t)
    VALUES (:old.id, :old.name, :old.group_id, null, null, 'DELETE', SYSDATE);
  END IF;
  COMMIT;
END;

/*5*/
create or replace procedure restore_students(start_time timestamp, finish_time timestamp) is
    cursor records is
        select *
        from students_log
        where t between start_time and finish_time
        order by t desc;
begin
    execute immediate 'alter trigger students_trigger disable';
    execute immediate 'alter trigger groups_c_val_trigger disable';
    execute immediate 'alter trigger students_log_trigger_i disable';
    execute immediate 'alter trigger students_log_trigger_i disable';
    execute immediate 'alter trigger students_log_trigger disable';
    for record in records
    loop
        if record.operation = 'INSERT' then
            delete from students where id = record.id;
        elsif record.operation = 'UPDATE' then
            update students set name = record.old_name, group_id = record.old_group_id where id = record.id;
        else
            insert into students values(record.id, record.old_name, record.old_group_id);
        end if;
    end loop;
    execute immediate 'alter trigger students_trigger enable';
    execute immediate 'alter trigger groups_c_val_trigger enable';
    execute immediate 'alter trigger students_log_trigger_i enable';
    execute immediate 'alter trigger students_log_trigger_i enable';
    execute immediate 'alter trigger students_log_trigger enable';
end restore_students;

begin
    restore_students(to_timestamp('2023-03-12 11:00:51', 'yyyy-mm-dd hh24:mi:ss'), to_timestamp('2023-03-12 12:00:00', 'yyyy-mm-dd hh24:mi:ss'));
end;

/*6*/
CREATE OR REPLACE TRIGGER groups_c_val_trigger
BEFORE INSERT OR DELETE OR UPDATE ON students
FOR EACH ROW
BEGIN
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
END;
/


insert into groups(name, c_val) values ('wrt', 0);
insert into students(name, group_id) values ('qq', 21);
update students set group_id = 22 where id = 22;
delete from students where id=22;
delete from groups where id = 3;