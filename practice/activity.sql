set serveroutput on;

create table students (
    std_id int primary key,
    std_name varchar(255) not null,
    h_pay int,
    y_pay int
);

create or replace trigger insert_data
before insert on students
for each row
begin
    if :new.h_pay is null then
        :new.h_pay := 250;
    end if;
end;
/

create or replace trigger update_salary
before update on students
for each row
begin
    :new.y_pay := :new.h_pay * 1920;
end;
/

create or replace trigger prevent_admin
before delete on students
for each row
begin
    if :old.std_name = 'admin' then
        raise_application_error(-20000, 'you cannot delete admin record');
    end if;
end;
/

create table std_logs (
    std_id int references students (std_id),
    inserted_by varchar(255),
    inserted_at date
);

create table std_logs_del (
    std_id int references students (std_id),
    deleted_by varchar(255),
    deleted_at date
);

-- ACTIVITY 1
create trigger log_student_del
after delete on students
for each row
begin
    insert into std_logs_del(std_id, deleted_at, deleted_by)
    values (:new.std_id, sysdate, sys_context('USERENV', 'SESSION_USER'));
end;
/

create trigger log_student
after insert on students
for each row
begin
    insert into std_logs(std_id, inserted_by, inserted_at)
    values (:new.std_id, sys_context('USERENV', 'SESSION_USER'), sysdate);
end;
/

create or replace trigger prevent_tables
before drop on database
begin
    raise_application_error(-20000, 'Cannot drop object');
end;
/

-- ACTIVITY 2
create or replace trigger prevent_std_table_drop
before drop on database
begin
    if ora_dict_obj_name = 'STUDENTS' then
        raise_application_error(-20000, 'Cannot drop user table');
    end if;
end;
/

create table schema_audit (
    ddl_date date,
    ddl_user varchar(255),
    object_create varchar(255),
    object_name varchar(255),
    ddl_operation varchar(255)
);

create or replace trigger schema_audit_tr
after ddl on schema
begin
    insert into schema_audit values (sysdate, sys_context('USERENV', 'CURRENT_USER'), ora_dict_obj_type, ora_dict_obj_name, ora_sysevent);
end;
/