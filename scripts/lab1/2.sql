BEGIN
FOR i IN 1..10000 LOOP
        INSERT INTO MyTable (id, val) VAlUES (i, trunc(dbms_random.value(-100000, 100000)));
END LOOP;
END;
