CREATE OR REPLACE FUNCTION year_salary(month_salary NUMBER, percent NUMBER) RETURN NUMBER IS
    float_percent NUMBER;
    year_salary NUMBER;

BEGIN
    IF trunc(percent) = percent THEN
        float_percent := percent / 100;
ELSE
        DBMS_OUTPUT.put_line('Invalid percent type');
return 0;
END IF;

    IF month_salary < 0 THEN
        DBMS_OUTPUT.put_line('Invalid salary type');
return 0;
END IF;

    year_salary := (1 + float_percent) * 12 * month_salary;

RETURN year_salary;
END;
/

variable res number;

begin
    select year_salary('qwe', 'qwe')
    into :res
    from dual;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.put_line('Invalid input');
end;
/

print res;
