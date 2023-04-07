create or replace procedure get_differences(dev_schema_name varchar2, prod_schema_name varchar2) is
begin
    get_tables(dev_schema_name, prod_schema_name);
    get_procedures(dev_schema_name, prod_schema_name);
    get_functions(dev_schema_name, prod_schema_name);
    get_indexes(dev_schema_name, prod_schema_name);
    get_packages(dev_schema_name, prod_schema_name);
end get_differences;

create or replace procedure ddl_create_table(dev_schema_name varchar2, tab_name varchar2, prod_schema_name varchar2) is
    cursor table_columns is
        select column_name, data_type, data_length, nullable
        from all_tab_columns
        where owner = dev_schema_name
            and table_name = tab_name
        order by column_name;
    cursor table_constraints is
        select all_constraints.constraint_name, all_constraints.constraint_type, all_constraints.search_condition, all_ind_columns.column_name
        from all_constraints
        inner join all_ind_columns
        on all_constraints.constraint_name = all_ind_columns.index_name
        where owner = dev_schema_name
            and all_constraints.table_name = tab_name
        order by all_constraints.constraint_name;
    cursor table_foreign_keys(pr varchar2) is
        select all_constraints.constraint_name, all_constraints.constraint_type, all_constraints.search_condition, all_ind_columns.column_name
        from all_constraints
        inner join all_ind_columns
        on all_constraints.constraint_name = all_ind_columns.index_name
        where owner = dev_schema_name
            and all_constraints.constraint_name = pr
        order by all_constraints.constraint_name;
    result all_source.text%TYPE;
    pr_key all_constraints.r_constraint_name%TYPE;
    tab2_name all_constraints.table_name%TYPE;
    c_name all_constraints.constraint_name%TYPE;
    amount number;
begin
    result := concat('DROP TABLE ', prod_schema_name || '.' || UPPER(tab_name) || ';' || chr(10));
    result := concat(result, 'CREATE TABLE ' || prod_schema_name || '.' || UPPER(tab_name) || '(' || chr(10));
    for table_column in table_columns
    loop
        result := concat(result, chr(9) || table_column.column_name || ' ' || table_column.data_type || '(' || table_column.data_length || ')');
        if table_column.nullable = 'N' then
            result := concat(result, ' NOT NULL');
        end if;
        result := concat(result, ',' || chr(10));
    end loop;
    for table_constraint in table_constraints
    loop
        c_name := table_constraint.constraint_name;
        result := concat(result, chr(9) || 'CONSTRAINT ' || table_constraint.constraint_name || ' ');
        if table_constraint.constraint_type = 'U' then
            result := concat(result, 'UNIQUE ');
        end if;
        if table_constraint.constraint_type = 'P' then
            result := concat(result, 'PRIMARY KEY ');
        end if;
        result := concat(result, '(' || table_constraint.column_name || ' ' || table_constraint.search_condition || '),' || chr(10));
    end loop;
    select count(*) into amount from all_constraints where owner = dev_schema_name and table_name = tab_name and constraint_type = 'R';
    if amount <> 0 then
        select r_constraint_name into pr_key from all_constraints where owner = dev_schema_name and table_name = tab_name and constraint_type = 'R';
        result := concat(result, chr(9) || 'CONSTRAINT ' || c_name || ' FOREIGN KEY (');
        for key in table_foreign_keys(pr_key)
        loop
            result := concat(result, key.column_name || ', ');
        end loop;
        result := concat(result, ') ');
        result := concat(result, 'REFERENCES ' || prod_schema_name || '.');
        select table_name into tab2_name from all_constraints where constraint_name = pr_key;
        result := concat(result, tab2_name);
        result := concat(result, '(');
        for key in table_foreign_keys(pr_key)
        loop
            result := concat(result, key.column_name || ', ');
        end loop;
        result := concat(result, '),' || chr(10));
    end if;
    result := concat(result, ');');
    result := replace(result, ',' || chr(10) || ')', chr(10) || ')');
    result := replace(result, ', )', ')');
    dbms_output.put_line(result);
end ddl_create_table;

create or replace procedure ddl_create_procedure(dev_schema_name varchar2, procedure_name varchar2, prod_schema_name varchar2) is
    cursor procedure_text is
        select text
        from all_source
        where owner = dev_schema_name
            and name = procedure_name
            and type = 'PROCEDURE'
            and line <> 1;
    cursor procedure_args is
        select argument_name, data_type
        from all_arguments
        where owner = dev_schema_name
            and object_name = procedure_name
            and position <> 0;
    result all_source.text%TYPE;
begin
    result := concat('CREATE OR REPLACE PROCEDURE ' || prod_schema_name || '.' || procedure_name, '(');
    for arg in procedure_args
    loop
        result := concat(result, arg.argument_name || ' ' || arg.data_type || ', ');
    end loop;
    result := concat(result, ') IS' || chr(10));

    for line in procedure_text
    loop
        result := concat(result, line.text);
    end loop;
    result := replace(result, ', )', ')');
    result := replace(result, '()');
    dbms_output.put_line(result);
end ddl_create_procedure;

create or replace procedure ddl_create_function(dev_schema_name varchar2, function_name varchar2, prod_schema_name varchar2) is
    cursor procedure_text is
        select text
        from all_source
        where owner = dev_schema_name
            and name = function_name
            and type = 'FUNCTION'
            and line <> 1;
    cursor procedure_args is
        select argument_name, data_type
        from all_arguments
        where owner = dev_schema_name
            and object_name = function_name
            and position <> 0;
    arg_type all_arguments.data_type%TYPE;
    result all_source.text%TYPE;
begin
    result := concat('CREATE OR REPLACE FUNCTION ' || prod_schema_name || '.' || function_name, '(');
    for arg in procedure_args
    loop
        result := concat(result, arg.argument_name || ' ' || arg.data_type || ', ');
    end loop;
    select data_type into arg_type from all_arguments where owner = dev_schema_name and object_name = function_name and position = 0;
    result := concat(result, ') RETURN ' || arg_type || ' IS' || chr(10));

    for line in procedure_text
    loop
        result := concat(result, line.text);
    end loop;
    result := replace(result, ', )', ')');
    result := replace(result, '()');
    dbms_output.put_line(result);
end ddl_create_function;

create or replace procedure ddl_create_index(dev_schema_name varchar2, ind_name varchar2, prod_schema_name varchar2) is
    tab_name all_indexes.table_name%TYPE;

    cursor index_columns is
        select column_name
        from all_ind_columns
        inner join all_indexes
        on all_ind_columns.index_name = all_indexes.index_name
            and all_ind_columns.index_owner = all_indexes.owner
        where index_owner = dev_schema_name
            and all_indexes.index_name = ind_name;
    result all_source.text%TYPE;
begin
    select table_name into tab_name from all_indexes where owner = dev_schema_name and index_name = ind_name;
    result := concat('DROP INDEX ' || prod_schema_name || '.' || ind_name || ';' || chr(10), 'CREATE INDEX ' || prod_schema_name || '.' || ind_name || ' ON ' || prod_schema_name || '.' || tab_name || '(');
    for index_column in index_columns
    loop
        result := concat(result, index_column.column_name || ', ');
    end loop;
    result := concat(result, ');');
    result := replace(result, ', )', ')');
    dbms_output.put_line(result);
end ddl_create_index;

create or replace procedure ddl_create_package(dev_schema_name varchar2, package_name varchar2, prod_schema_name varchar2) is
    cursor package_text is
        select text
        from all_source
        where owner = dev_schema_name
            and name = package_name
            and type = 'PACKAGE'
            and line <> 1;
    result all_source.text%TYPE;
begin
    result := concat('CREATE OR REPLACE PACKAGE ' || prod_schema_name || '.' || package_name, ' IS');

    for line in package_text
    loop
        result := concat(result, line.text);
    end loop;
    dbms_output.put_line(result);
end ddl_create_package;

create or replace procedure get_tables(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor dev_schema_tables is
        select *
        from all_tables
        where owner = dev_schema_name;

    dev_table_columns SYS_REFCURSOR;
    prod_table_columns SYS_REFCURSOR;

    dev_table_constraints SYS_REFCURSOR;
    prod_table_constraints SYS_REFCURSOR;

    amount number;

    columns_amount1 number;
    columns_amount2 number;

    column_name1 all_tab_columns.column_name%TYPE;
    data_type1 all_tab_columns.data_type%TYPE;
    data_length1 all_tab_columns.data_length%TYPE;
    nullable1 all_tab_columns.nullable%TYPE;

    column_name2 all_tab_columns.column_name%TYPE;
    data_type2 all_tab_columns.data_type%TYPE;
    data_length2 all_tab_columns.data_length%TYPE;
    nullable2 all_tab_columns.nullable%TYPE;

    constraints_amount1 number;
    constraints_amount2 number;

    constraint_name1 all_constraints.constraint_name%TYPE;
    constraint_type1 all_constraints.constraint_type%TYPE;
    search_condition1 all_constraints.search_condition%TYPE;

    constraint_name2 all_constraints.constraint_name%TYPE;
    constraint_type2 all_constraints.constraint_type%TYPE;
    search_condition2 all_constraints.search_condition%TYPE;

    checked boolean;
begin
    for dev_schema_table in dev_schema_tables
    loop
        checked := false;
        select count(*) into amount from all_tables where owner = prod_schema_name and table_name = dev_schema_table.table_name;
        if amount = 0 then
            dbms_output.put_line('TABLE: ' || dev_schema_table.table_name);
            ddl_create_table(dev_schema_name, dev_schema_table.table_name, prod_schema_name);
        else
            select count(*) into columns_amount1 from all_tab_columns where owner = dev_schema_name and table_name = dev_schema_table.table_name;
            select count(*) into columns_amount2 from all_tab_columns where owner = prod_schema_name and table_name = dev_schema_table.table_name;
            if columns_amount1 = columns_amount2 then
                open dev_table_columns for
                    select column_name, data_type, data_length, nullable
                    from all_tab_columns
                    where owner = dev_schema_name
                        and table_name = dev_schema_table.table_name
                    order by column_name;
                open prod_table_columns for
                    select column_name, data_type, data_length, nullable
                    from all_tab_columns
                    where owner = prod_schema_name
                        and table_name = dev_schema_table.table_name
                    order by column_name;

                loop
                    fetch dev_table_columns into column_name1, data_type1, data_length1, nullable1;
                    fetch prod_table_columns into column_name2, data_type2, data_length2, nullable2;
                    
                    if column_name1 <> column_name2 or data_type1 <> data_type2 or data_length1 <> data_length2 or nullable1 <> nullable2 then
                        dbms_output.put_line('TABLE: ' || dev_schema_table.table_name);
                        ddl_create_table(dev_schema_name, dev_schema_table.table_name, prod_schema_name);
                        checked := true;
                        exit;
                    end if;

                    exit when dev_table_columns%NOTFOUND and prod_table_columns%NOTFOUND;
                end loop;

                close dev_table_columns;
                close prod_table_columns;
            else
                dbms_output.put_line('TABLE: ' || dev_schema_table.table_name);
                ddl_create_table(dev_schema_name, dev_schema_table.table_name, prod_schema_name);
                checked := true;
            end if;

            if checked = false then
                select count(*) into constraints_amount1 from all_constraints where owner = dev_schema_name and table_name = dev_schema_table.table_name;
                select count(*) into constraints_amount2 from all_constraints where owner = prod_schema_name and table_name = dev_schema_table.table_name;
                if constraints_amount1 = constraints_amount2 then
                    open dev_table_constraints for
                        select constraint_name, constraint_type, search_condition
                        from all_constraints
                        where owner = dev_schema_name
                            and table_name = dev_schema_table.table_name
                        order by constraint_name;
                    open prod_table_constraints for
                        select constraint_name, constraint_type, search_condition
                        from all_constraints
                        where owner = prod_schema_name
                            and table_name = dev_schema_table.table_name
                        order by constraint_name;

                    loop
                        fetch dev_table_constraints into constraint_name1, constraint_type1, search_condition1;
                        fetch prod_table_constraints into constraint_name2, constraint_type2, search_condition2;
                        
                        if constraint_name1 <> constraint_name2 or constraint_type1 <> constraint_type2 or search_condition1 <> search_condition2 then
                            dbms_output.put_line('TABLE: ' || dev_schema_table.table_name);
                            ddl_create_table(dev_schema_name, dev_schema_table.table_name, prod_schema_name);
                            exit;
                        end if;

                        exit when dev_table_constraints%NOTFOUND and prod_table_constraints%NOTFOUND;
                    end loop;

                    close dev_table_constraints;
                    close prod_table_constraints;
                else
                    dbms_output.put_line('TABLE: ' || dev_schema_table.table_name);
                    ddl_create_table(dev_schema_name, dev_schema_table.table_name, prod_schema_name);
                end if;
            end if;
        end if;
    end loop;
end get_tables;

create or replace procedure get_procedures(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor dev_schema_procedures is
        select distinct name
        from all_source
        where owner = dev_schema_name
            and type = 'PROCEDURE';

    dev_procedure_text SYS_REFCURSOR;
    prod_procedure_text SYS_REFCURSOR;

    dev_procedure_args SYS_REFCURSOR;
    prod_procedure_args SYS_REFCURSOR;

    amount number;

    args_amount1 number;
    args_amount2 number;

    arg1 all_arguments.argument_name%TYPE;
    type1 all_arguments.data_type%TYPE;

    arg2 all_arguments.argument_name%TYPE;
    type2 all_arguments.data_type%TYPE;

    lines_amount1 number;
    lines_amount2 number;

    line1 all_source.text%TYPE;
    line2 all_source.text%TYPE;

    checked boolean;
begin
    for dev_schema_procedure in dev_schema_procedures
    loop
        checked := false;
        select count(*) into amount from all_source where owner = prod_schema_name and type = 'PROCEDURE' and name = dev_schema_procedure.name;
        if amount = 0 then
            dbms_output.put_line('PROCEDURE: ' || dev_schema_procedure.name);
            ddl_create_procedure(dev_schema_name, dev_schema_procedure.name, prod_schema_name);
        else
            select count(*) into args_amount1 from all_arguments where owner = dev_schema_name and object_name = dev_schema_procedure.name;
            select count(*) into args_amount2 from all_arguments where owner = prod_schema_name and object_name = dev_schema_procedure.name;
            if args_amount1 = args_amount2 then
                open dev_procedure_args for
                    select argument_name, data_type
                    from all_arguments
                    where owner = dev_schema_name
                        and object_name = dev_schema_procedure.name
                    order by position;
                open prod_procedure_args for
                    select argument_name, data_type
                    from all_arguments
                    where owner = prod_schema_name
                        and object_name = dev_schema_procedure.name
                    order by position;

                loop
                    fetch dev_procedure_args into arg1, type1;
                    fetch prod_procedure_args into arg2, type2;
                    
                    if arg1 <> arg2 or type1 <> type2 then
                        dbms_output.put_line('PROCEDURE: ' || dev_schema_procedure.name);
                        ddl_create_procedure(dev_schema_name, dev_schema_procedure.name, prod_schema_name);
                        checked := true;
                        exit;
                    end if;

                    exit when dev_procedure_args%NOTFOUND and prod_procedure_args%NOTFOUND;
                end loop;

                close dev_procedure_args;
                close prod_procedure_args;
            else
                dbms_output.put_line('PROCEDURE: ' || dev_schema_procedure.name);
                ddl_create_procedure(dev_schema_name, dev_schema_procedure.name, prod_schema_name);
                checked := true;
            end if;

            if checked = false then
                select count(*) into lines_amount1 from all_source where owner = dev_schema_name and type = 'PROCEDURE' and name = dev_schema_procedure.name;
                select count(*) into lines_amount2 from all_source where owner = prod_schema_name and type = 'PROCEDURE' and name = dev_schema_procedure.name;
                if lines_amount1 = lines_amount2 then
                    open dev_procedure_text for
                        select text
                        from all_source
                        where owner = dev_schema_name
                            and name = dev_schema_procedure.name
                            and line <> 1
                        order by line;
                    open prod_procedure_text for
                        select text
                        from all_source
                        where owner = prod_schema_name
                            and name = dev_schema_procedure.name
                            and line <> 1
                        order by line;

                    loop
                        fetch dev_procedure_text into line1;
                        fetch prod_procedure_text into line2;
                        
                        if line1 <> line2 then
                            dbms_output.put_line('PROCEDURE: ' || dev_schema_procedure.name);
                            ddl_create_procedure(dev_schema_name, dev_schema_procedure.name, prod_schema_name);
                            exit;
                        end if;

                        exit when dev_procedure_text%NOTFOUND and prod_procedure_text%NOTFOUND;
                    end loop;

                    close dev_procedure_text;
                    close prod_procedure_text;
                else
                    dbms_output.put_line('PROCEDURE: ' || dev_schema_procedure.name);
                    ddl_create_procedure(dev_schema_name, dev_schema_procedure.name, prod_schema_name);
                end if;
            end if;
        end if;
    end loop;
end get_procedures;

create or replace procedure get_functions(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor dev_schema_functions is
        select distinct name
        from all_source
        where owner = dev_schema_name
            and type = 'FUNCTION';

    dev_function_text SYS_REFCURSOR;
    prod_function_text SYS_REFCURSOR;

    dev_function_args SYS_REFCURSOR;
    prod_function_args SYS_REFCURSOR;

    amount number;

    args_amount1 number;
    args_amount2 number;

    arg1 all_arguments.argument_name%TYPE;
    type1 all_arguments.data_type%TYPE;

    arg2 all_arguments.argument_name%TYPE;
    type2 all_arguments.data_type%TYPE;

    lines_amount1 number;
    lines_amount2 number;

    line1 all_source.text%TYPE;
    line2 all_source.text%TYPE;

    checked boolean;
begin
    for dev_schema_function in dev_schema_functions
    loop
        checked := false;
        select count(*) into amount from all_source where owner = prod_schema_name and type = 'FUNCTION' and name = dev_schema_function.name;
        if amount = 0 then
            dbms_output.put_line('FUNCTION: ' || dev_schema_function.name);
            ddl_create_function(dev_schema_name, dev_schema_function.name, prod_schema_name);
        else
            select count(*) into args_amount1 from all_arguments where owner = dev_schema_name and object_name = dev_schema_function.name;
            select count(*) into args_amount2 from all_arguments where owner = prod_schema_name and object_name = dev_schema_function.name;
            if args_amount1 = args_amount2 then
                open dev_function_args for
                    select argument_name, data_type
                    from all_arguments
                    where owner = dev_schema_name
                        and object_name = dev_schema_function.name
                    order by position;
                open prod_function_args for
                    select argument_name, data_type
                    from all_arguments
                    where owner = prod_schema_name
                        and object_name = dev_schema_function.name
                    order by position;

                loop
                    fetch dev_function_args into arg1, type1;
                    fetch prod_function_args into arg2, type2;
                    
                    if arg1 <> arg2 or type1 <> type2 then
                        dbms_output.put_line('FUNCTION: ' || dev_schema_function.name);
                        ddl_create_function(dev_schema_name, dev_schema_function.name, prod_schema_name);
                        checked := true;
                        exit;
                    end if;

                    exit when dev_function_args%NOTFOUND and prod_function_args%NOTFOUND;
                end loop;

                close dev_function_args;
                close prod_function_args;
            else
                dbms_output.put_line('FUNCTION: ' || dev_schema_function.name);
                ddl_create_function(dev_schema_name, dev_schema_function.name, prod_schema_name);
                checked := true;
            end if;

            if checked = false then
                select count(*) into lines_amount1 from all_source where owner = dev_schema_name and type = 'FUNCTION' and name = dev_schema_function.name;
                select count(*) into lines_amount2 from all_source where owner = prod_schema_name and type = 'FUNCTION' and name = dev_schema_function.name;
                if lines_amount1 = lines_amount2 then
                    open dev_function_text for
                        select text
                        from all_source
                        where owner = dev_schema_name
                            and name = dev_schema_function.name
                            and line <> 1
                        order by line;
                    open prod_function_text for
                        select text
                        from all_source
                        where owner = prod_schema_name
                            and name = dev_schema_function.name
                            and line <> 1
                        order by line;

                    loop
                        fetch dev_function_text into line1;
                        fetch prod_function_text into line2;
                        
                        if line1 <> line2 then
                            dbms_output.put_line('FUNCTION: ' || dev_schema_function.name);
                            ddl_create_function(dev_schema_name, dev_schema_function.name, prod_schema_name);
                            exit;
                        end if;

                        exit when dev_function_text%NOTFOUND and prod_function_text%NOTFOUND;
                    end loop;

                    close dev_function_text;
                    close prod_function_text;
                else
                    dbms_output.put_line('FUNCTION: ' || dev_schema_function.name);
                    ddl_create_function(dev_schema_name, dev_schema_function.name, prod_schema_name);
                end if;
            end if;
        end if;
    end loop;
end get_functions;

create or replace procedure get_indexes(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor dev_schema_indexes is
        select index_name
        from all_indexes
        where owner = dev_schema_name;

    amount number;

    index1_columns SYS_REFCURSOR;
    index2_columns SYS_REFCURSOR;

    columns_amount1 number;
    columns_amount2 number;

    index_type1 all_indexes.index_type%TYPE;
    table_name1 all_indexes.table_name%TYPE;
    uniqueness1 all_indexes.uniqueness%TYPE;
    column_name1 all_ind_columns.column_name%TYPE;

    index_type2 all_indexes.index_type%TYPE;
    table_name2 all_indexes.table_name%TYPE;
    uniqueness2 all_indexes.uniqueness%TYPE;
    column_name2 all_ind_columns.column_name%TYPE;
begin
    for dev_schema_index in dev_schema_indexes
    loop
        select count(*) into amount from all_indexes where owner = prod_schema_name and index_name = dev_schema_index.index_name;
        if amount = 0 then
            dbms_output.put_line('INDEX: ' || dev_schema_index.index_name);
            ddl_create_index(dev_schema_name, dev_schema_index.index_name, prod_schema_name);
        else
            select index_type, table_name, uniqueness
            into index_type1, table_name1, uniqueness1
            from all_indexes
            where owner = dev_schema_name
                and index_name = dev_schema_index.index_name;

            select index_type, table_name, uniqueness
            into index_type2, table_name2, uniqueness2
            from all_indexes
            where owner = prod_schema_name
                and index_name = dev_schema_index.index_name;

            if index_type1 = index_type2 and table_name1 = table_name2 and uniqueness1 = uniqueness2 then
                select count(*)
                into columns_amount1
                from all_indexes
                inner join all_ind_columns
                on all_indexes.index_name = all_ind_columns.index_name and all_indexes.owner = all_ind_columns.index_owner
                where all_indexes.owner = dev_schema_name
                    and all_indexes.index_name = dev_schema_index.index_name;

                select count(*)
                into columns_amount2
                from all_indexes
                inner join all_ind_columns
                on all_indexes.index_name = all_ind_columns.index_name and all_indexes.owner = all_ind_columns.index_owner
                where all_indexes.owner = prod_schema_name
                    and all_indexes.index_name = dev_schema_index.index_name;

                if columns_amount1 = columns_amount2 then
                    open index1_columns for
                        select column_name
                        from all_ind_columns
                        where index_owner = dev_schema_name
                            and index_name = dev_schema_index.index_name
                        group by column_name;
                    
                    open index2_columns for
                        select column_name
                        from all_ind_columns
                        where index_owner = prod_schema_name
                            and index_name = dev_schema_index.index_name
                        group by column_name;

                    loop
                        fetch index1_columns into column_name1;
                        fetch index2_columns into column_name2;

                        if column_name1 <> column_name2 then
                            dbms_output.put_line('INDEX: ' || dev_schema_index.index_name);
                            ddl_create_index(dev_schema_name, dev_schema_index.index_name, prod_schema_name);
                            exit;
                        end if;

                        exit when index1_columns%NOTFOUND and index2_columns%NOTFOUND;
                    end loop;

                    close index1_columns;
                    close index2_columns;
                else
                    dbms_output.put_line('INDEX: ' || dev_schema_index.index_name);
                    ddl_create_index(dev_schema_name, dev_schema_index.index_name, prod_schema_name);
                end if;
            else
                dbms_output.put_line('INDEX: ' || dev_schema_index.index_name);
                ddl_create_index(dev_schema_name, dev_schema_index.index_name, prod_schema_name);
            end if;
        end if;
    end loop;
end get_indexes;

create or replace procedure get_packages(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor dev_schema_packages is
        select distinct name
        from all_source
        where owner = dev_schema_name
            and type = 'PACKAGE';

    dev_package_text SYS_REFCURSOR;
    prod_package_text SYS_REFCURSOR;

    amount number;

    lines_amount1 number;
    lines_amount2 number;

    line1 all_source.text%TYPE;
    line2 all_source.text%TYPE;
begin
    for dev_schema_package in dev_schema_packages
    loop
        select count(*) into amount from all_source where owner = prod_schema_name and type = 'PACKAGE' and name = dev_schema_package.name;
        if amount = 0 then
            dbms_output.put_line('PACKAGE: ' || dev_schema_package.name);
            ddl_create_package(dev_schema_name, dev_schema_package.name, prod_schema_name);
        else
            select count(*) into lines_amount1 from all_source where owner = dev_schema_name and type = 'PACKAGE' and name = dev_schema_package.name;
            select count(*) into lines_amount2 from all_source where owner = prod_schema_name and type = 'PACKAGE' and name = dev_schema_package.name;
            if lines_amount1 = lines_amount2 then
                open dev_package_text for
                    select text
                    from all_source
                    where owner = dev_schema_name
                        and name = dev_schema_package.name
                        and line <> 1
                    order by line;
                open prod_package_text for
                    select text
                    from all_source
                    where owner = prod_schema_name
                        and name = dev_schema_package.name
                        and line <> 1
                    order by line;

                loop
                    fetch dev_package_text into line1;
                    fetch prod_package_text into line2;
                    
                    if line1 <> line2 then
                        dbms_output.put_line('PACKAGE: ' || dev_schema_package.name);
                        ddl_create_package(dev_schema_name, dev_schema_package.name, prod_schema_name);
                        exit;
                    end if;

                    exit when dev_package_text%NOTFOUND and prod_package_text%NOTFOUND;
                end loop;

                close dev_package_text;
                close prod_package_text;
            else
                dbms_output.put_line('PACKAGE: ' || dev_schema_package.name);
                ddl_create_package(dev_schema_name, dev_schema_package.name, prod_schema_name);
            end if;
        end if;
    end loop;
end get_packages;

create or replace procedure delete_tables(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor tables is
        select table_name from all_tables where owner = prod_schema_name
        minus
        select table_name from all_tables where owner = dev_schema_name;
begin
    for tab in tables
    loop
        dbms_output.put_line('DROP TABLE ' || prod_schema_name || '.' || tab.table_name || ';');
    end loop;
end delete_tables;

create or replace procedure delete_procedures(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor procedures is
        select object_name from all_procedures where owner = prod_schema_name and 'type' = 'PROCEDURE'
        minus
        select object_name from all_procedures where owner = dev_schema_name and 'type' = 'PROCEDURE';
begin
    for proc in procedures
    loop
        dbms_output.put_line('DROP PROCEDURE ' || prod_schema_name || '.' || proc.object_name || ';');
    end loop;
end delete_procedures;

create or replace procedure delete_functions(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor functions is
        select object_name from all_objects where owner = prod_schema_name and object_type = 'FUNCTION'
        minus
        select object_name from all_objects where owner = dev_schema_name and object_type = 'FUNCTION';
begin
    for func in functions
    loop
        dbms_output.put_line('DROP FUNCTION ' || prod_schema_name || '.' || func.object_name || ';');
    end loop;
end delete_functions;

create or replace procedure delete_indexes(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor inds is
        select index_name from all_indexes where owner = prod_schema_name
        minus
        select index_name from all_indexes where owner = dev_schema_name;
begin
    for ind in inds
    loop
        dbms_output.put_line('DROP INDEX ' || prod_schema_name || '.' || ind.index_name || ';');
    end loop;
end delete_indexes;

create or replace procedure delete_packages(dev_schema_name varchar2, prod_schema_name varchar2) is
    cursor packages is
        select object_name from all_objects where owner = prod_schema_name and object_type = 'PACKAGE'
        minus
        select object_name from all_objects where owner = dev_schema_name and object_type = 'PACKAGE';
begin
    for pkg in packages
    loop
        dbms_output.put_line('DROP PACKAGE ' || prod_schema_name || '.' || pkg.object_name || ';');
    end loop;
end delete_packages;

begin
    dbms_output.put_line('aboba');
    get_tables('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

SET SERVEROUTPUT ON
BEGIN
 Dbms_Output.Put_Line(Systimestamp);
END;

begin
    get_procedures('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

begin
    get_functions('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

begin
    get_indexes('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

begin
    get_packages('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

begin
    delete_tables('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

begin
    delete_procedures('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

begin
    delete_functions('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

begin
    delete_indexes('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

begin
    delete_packages('C##DEV_SCHEMA', 'C##PROD_SCHEMA');
end;

create table C##dev_schema.mytable(
    id number,
    val number,
    constraint id_unique unique (id)
);

create table C##prod_schema.mytable(
    id number,
    val number
);

create or replace procedure C##dev_schema.test_proc1 is
begin
    dbms_output.put_line('HELLO');
end;

create or replace function C##dev_schema.test_func1(arg1 number, arg2 number) return number is
begin
    return 1;
end;

create index C##dev_schema.test_index1 on dev_schema.mytable(id);
create index C##prod_schema.test_index1 on prod_schema.mytable(id);

CREATE OR REPLACE PACKAGE C##dev_schema.test_pkg IS

	PROCEDURE Out_Screen(TOSC IN VARCHAR2);
	
	FUNCTION Add_Two_Num(A IN NUMBER, B IN NUMBER) RETURN NUMBER;
	
	FUNCTION Min_Two_Num(A IN NUMBER, B IN NUMBER) RETURN NUMBER;

	FUNCTION FACTORIAL(NUM IN NUMBER) RETURN NUMBER;
	
END test_pkg;

CREATE TABLE C##dev_schema.supplier
( supplier_id number not null,
  supplier_name varchar2(50) not null,
  contact_name varchar2(50),
  CONSTRAINT supplier_pk PRIMARY KEY (supplier_id)
);

CREATE TABLE C##dev_schema.products
( product_id number not null,
  supplier_id number not null,
  CONSTRAINT fk_supplier
    FOREIGN KEY (supplier_id)
    REFERENCES dev_schema.supplier(supplier_id)
);

select * from all_tab_columns where owner = 'DEV_SCHEMA' or owner = 'PROD_SCHEMA';
select * from all_source where name = 'TEST_PROC1';

select * from all_tables where owner = 'DEV_SCHEMA' or owner = 'PROD_SCHEMA'
