-- Q1
create or replace trigger trg_students_upper
before insert on students
for each row
begin
  :new.student_name := upper(:new.student_name);
end;
/

-- Q2
create or replace trigger trg_no_delete_weekend
before delete on employees
begin
  if to_char(sysdate, 'DY') in ('SAT', 'SUN') then
    raise_application_error(-20001, 'Deletion not allowed on weekends');
  end if;
end;
/

-- Q3
create or replace trigger trg_salary_audit
after update of salary on employees
for each row
begin
  insert into log_salary_audit (emp_id, old_salary, new_salary, update_date)
  values (:old.emp_id, :old.salary, :new.salary, sysdate);
end;
/

-- Q4
create or replace trigger trg_no_negative_price
before update of price on products
for each row
begin
  if :new.price < 0 then
    raise_application_error(-20002,
      'Price cannot be negative');
  end if;
end;
/

-- Q5
create or replace trigger trg_courses_audit
after insert on courses
for each row
begin
  insert into course_insert_log (username, insert_time) values (user, sysdate);
end;
/

-- Q6
create or replace trigger trg_default_dept
before insert on emp
for each row
begin
  if :new.department_id is null then
    :new.department_id := 10;
  end if;
end;
/

-- Q7
create or replace trigger trg_sales_total
for insert on sales
compound trigger

  v_before_total number;
  v_after_total  number;

  before statement is
  begin
    select nvl(sum(amount), 0) into v_before_total from sales;
  end before statement;

  after statement is
  begin
    select nvl(sum(amount), 0) into v_after_total from sales;

    dbms_output.put_line('Before: ' || v_before_total);
    dbms_output.put_line('After: ' || v_after_total);
  end after statement;

end trg_sales_total;
/

-- Q8
create or replace trigger trg_ddl_audit
after create or drop on schema
begin
  insert into schema_ddl_log (username, action, object_name, action_date)
  values (user, ora_sysevent, ora_dict_obj_name, sysdate);
end;
/

-- Q9
create or replace trigger trg_no_update_shipped
before update on orders
for each row
begin
  if :old.order_status = 'SHIPPED' then
    raise_application_error(-20003, 'Shipped orders cannot be modified');
  end if;
end;
/

-- Q10
create or replace trigger trg_login_audit
after logon on schema
begin
  insert into login_audit (username, login_time) values (user, sysdate);
end;
/
