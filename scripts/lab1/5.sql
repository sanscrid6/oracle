CREATE OR REPLACE PROCEDURE insert_table(new_id NUMBER, new_val NUMBER) IS

    BEGIN
        INSERT INTO MYTABLE(id, val) VALUES (new_id, new_val);
    END insert_table;
/

CREATE OR REPLACE PROCEDURE update_table(new_id NUMBER, new_val NUMBER) IS

    BEGIN
        UPDATE MYTABLE
        SET val = new_val
        WHERE id = new_id;
    END update_table;
/

CREATE OR REPLACE PROCEDURE delete_table(new_id NUMBER) IS

    BEGIN
        DELETE FROM MYTABLE
        WHERE id = new_id;
    END delete_table;
/
