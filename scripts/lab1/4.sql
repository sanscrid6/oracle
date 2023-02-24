CREATE OR REPLACE FUNCTION generate_insert(ex_id NUMBER) RETURN VARCHAR2 IS
    ex_val NUMBER;
    answer VARCHAR2(30);

CURSOR ct1 IS
    SELECT val
    FROM MyTable
    WHERE id = ex_id;

BEGIN
    OPEN ct1;
    FETCH ct1 INTO ex_val;
    IF ct1%NOTFOUND THEN
        RETURN 'not found id';
    END IF;
    CLOSE ct1;

    RETURN utl_lms.format_message('INSERT INTO MyTable(id, val) VALUES(%s, %s)', TO_CHAR(ex_id), TO_CHAR(ex_val));
END;
/

variable res varchar2(500);

begin
    select generate_insert(1)
    into :res
    from dual;
end;
/

print res;
