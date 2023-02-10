CREATE OR REPLACE NONEDITIONABLE FUNCTION is_even RETURN VARCHAR2 IS
    even_count NUMBER;
    odd_count NUMBER;
    answer varchar2(10);

CURSOR ct1 IS
SELECT COUNT(*)
FROM MyTable
WHERE MOD(val, 2) = 0;

CURSOR ct2 IS
SELECT COUNT(*)
FROM MyTable
WHERE MOD(val, 2) <> 0;

BEGIN
OPEN ct1;
FETCH ct1 INTO even_count;
CLOSE ct1;

OPEN ct2;
FETCH ct2 INTO odd_count;
CLOSE ct2;

IF (even_count > odd_count) THEN
        answer := 'TRUE';
    ELSIF (even_count < odd_count) THEN
        answer := 'FALSE';
ELSE
        answer := 'EQUAL';
END IF;
RETURN answer;
END;
/

variable res varchar2(500);

begin
    select is_even()
    into :res
    from dual;
end;
/

print res;
