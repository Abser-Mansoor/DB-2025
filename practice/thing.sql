create table students (
  std_id int primary key,
  std_name varchar(255) not null,
  std_age int not null,
  std_email varchar(255),
  created_at date,
  updated_at date
);

create table students_log (
  std_id int,
  is_created int default 0,
  is_updated int default 0,
  is_deleted int default 0
);

alter table students_log add created_at date;

create or replace trigger set_create_time
before insert or update on students
for each row
begin
  if inserting then
    :new.created_at := sysdate();
  end if;
  :new.updated_at := sysdate();
end;
/

create or replace trigger student_id_check
before insert or update on students
for each row
when (new.std_id < 1)
begin
  raise_application_error(-20001, 'Student ID cannot be nonpositive');
end;
/

create or replace trigger student_delete
after delete on students
for each ROW
begin
  insert into students_log values (:old.std_id, 0, 0, 1, null, 0);
end;
/

create or replace trigger student_create
after insert on students
for each ROW
BEGIN
  insert into STUDENTS_LOG values (:new.std_id, 1, 0, 0, null, 0);
end;
/

create or replace trigger set_create_time_students_log
before insert on students_log
for each row
begin
  :new.created_at := sysdate();
end;
/

insert into students values (1, 'fasih', 20, null, null, null);
insert into students values (2, 'hamna', 19, null, null, null);
insert into students values (3, 'pallo', 15, null, null, null);
insert into students values (4, 'sabih', 9, null, null, null);

select * from students order by updated_at desc;
select * from students_log;

update students set std_name = 'Fasih' where std_id = 1;
delete from students where std_id = 1;

delete from students;
delete from STUDENTS_LOG;

-- this code block sets null dates to not null by iterating rowwise
declare
  log_date date := sysdate();
begin
  for sl in (select * from students_log) LOOP
    update students_log set created_at = log_date where created_at is null;
  end loop;
end;
/

select * from STUDENTS_LOG;

declare
  v_num int := 10;
  v_div int := 0;
begin
  if v_div = 0 then
    raise_application_error(-20001, 'Division by Zero');
  end if;
  v_num := v_num / v_div;
exception
  when others then
  case sqlcode
    when -20001 then
      dbms_output.put_line('Custom error: ' || sqlerrm);
  end case;
end;
/

declare
  cursor c is select std_id, std_email from students;
  v_id students.std_id%type;
  v_email students.std_email%type;
begin
  open c;
  loop
    fetch c into v_id, v_email;
    exit when c%notfound;

    dbms_output.put_line(v_id || ' ' || (case when v_email is null then 'NoEmail' else v_email end));
  end loop;
  close c;
end;
/

exec create_student(10, 'Ali', 20); -- this also works

create or replace view std_v as
select std_id, std_name, std_age
from students;

alter table students_log add is_from_view int default 0;

create or replace trigger std_v_trg
instead of insert or update on std_v
for each row
declare
  is_created int := 0;
  is_updated int := 0;
begin
  if inserting then
    is_created := 1;
    insert into students values (:new.std_id, :new.std_name, :new.std_age, null, null, null);
  elsif updating then
    is_updated := 1;
    update students set std_name = :new.std_name, std_age = :new.std_age where std_id = :new.std_id;
  end if;
  
  insert into students_log values (:new.std_id, is_created, is_updated, 0, null, 1);
end;
/

insert into std_v values (5, 'not fasih', 20);
select * from std_v;

select * from students_log order by created_at desc;
update std_v set std_name = 'not not fasih' where std_id = 5;

create or replace procedure count_students_with_name_util(std_name in varchar, std_count out int) as
begin
  std_count := 0;
  for std_ in (select * from students) loop
    if lower(std_.std_name) like '%' || lower(std_name) || '%' then
      std_count := std_count + 1;
    end if;
  end loop;
end;
/

create or replace function count_students_with_name(std_name varchar) return int as
  std_count int;
begin
  count_students_with_name_util(std_name, std_count);
  return std_count;
end;
/

select count_students_with_name('fasih') from dual;

create table audit_log (
  table_name varchar(255) not null,
  action varchar(255) not null,
  action_time date not null
);

create or replace trigger log_ddl_schema_trg
after create or alter on schema
-- events are: create, alter, drop, truncate, rename, audit, grant/revoke
-- database only events: logon, logoff, startup, shutdown
begin
  insert into audit_log (table_name, action, action_time)
  values (ora_dict_obj_name, ora_sysevent, sysdate);

  -- ora_dict_obj_name = object name affected
  -- ora_sysevent = event type
  -- ora_login_user
  -- ora_dict_obj_owner
end;
/

create or replace trigger test_table_ddl_dml_trg
after insert or update or delete on test
for each row
declare
  trg_mode varchar(255) := case when inserting then 'INSERT' when updating then 'UPDATE' when deleting then 'DELETE' end;
begin
  insert into audit_log values (
    'TEST',
    trg_mode,
    sysdate
  );
end;
/

create table test (
  test_id int,
  std_id int not null,
  primary key (test_id)
);

select * from audit_log;

alter table test add constraint std_key_ref foreign key (std_id) references students on delete cascade;
alter table test drop constraint std_key_ref;

insert into test values (1, 1);

create or replace procedure create_student(std_id int, std_name varchar, std_age int) as
begin
  insert into students (std_id, std_name, std_age) values (std_id, std_name, std_age);
end;
/

create or replace procedure delete_student_by_id(std_id int) as
begin
  delete from students st where st.std_id = std_id;
end;
/

begin
  delete_student_by_id(6);
end;
/
select * from students;

delete from students where std_id = 6;
commit;

set transaction name 'student_t';

begin
  create_student(6, 'TEST1', 30);
end;
/

savepoint before_test2;

begin
  create_student(7, 'TEST2', 30);
end;
/

rollback to savepoint before_test2;

rollback;

-- Q1 of past paper

select d.department_name, max(e.salary) as max_salary, min(e.salary) as min_salary
from hr.employees e
join hr.departments d on d.department_id = e.department_id
group by e.department_id, d.department_name
having max(e.salary) - min(e.salary) > 4000;

select * from (
  select d.department_name, t.hire_year, count(t.employee_id) as employees_hired
  from (select to_char(e.hire_date, 'YYYY') as hire_year, e.* from hr.employees e) t
  join hr.departments d on d.department_id = t.department_id
  group by hire_year, department_name
  order by count(t.employee_id) desc
) where ROWNUM <= 1;

select d.department_name, e.employee_name, j.job_title, max(e.salary) as salary
from (
  select
    e.department_id,
    e.first_name || ' ' || e.last_name as employee_name,
    e.salary,
    e.job_id
  from hr.employees e
) e
join hr.departments d on d.department_id = e.department_id
join hr.jobs j on e.job_id = j.job_id
group by d.department_name, e.employee_name, d.department_id, j.job_title
having max(e.salary) = (select max(e.salary) from hr.employees e where e.department_id = d.department_id);

select e.first_name || ' ' || e.last_name as employee_name, m.first_name || ' ' || m.last_name as manager_name
from hr.employees e
join hr.employees m on e.manager_id = m.employee_id
where e.salary > m.salary;

-- Q2 of past paper

create table products (
  product_id int primary key,
  product_name varchar(255) not null,
  price decimal,
  stock_quantity int
);

insert into products values (1, 'Laptop', 50000, 10);
insert into products values (2, 'Smartphone', 20000, 8);
insert into products values (3, 'Tablet', 15000, 20);
insert into products values (4, 'Headphones', 5000, 6);
insert into products values (5, 'Keyboard', 2000, 3);

create sequence stock_alert_seq
start with 1
increment by 1
nocache;

create table stock_alert (
  alert_id int,
  product_id int,
  current_stock int,
  alert_message varchar(255),
  alert_date date
);

alter table stock_alert add constraint pk_stock_alert primary key (alert_id);
alter table stock_alert add constraint fk_product_id foreign key (product_id) references products;

create or replace trigger stock_threshold
before update on products
for each row
declare
  alert_id int;
begin
  select stock_alert_seq.nextval into alert_id from dual;
  if :new.stock_quantity < 5 then
    insert into stock_alert values (alert_id, :new.product_id, :new.stock_quantity, 'Low Stock', sysdate);
  end if;
end;
/

update products set stock_quantity = 3 where product_name = 'Laptop';
update products set stock_quantity = 2 where product_name = 'Tablet';

select * from stock_alert;

-- transactions

create table guests (
  guest_id int primary key,
  name varchar(255),
  email varchar(255)
);

create table rooms (
  room_id int primary key,
  room_type varchar(255) default 'Small' check(room_type in ('Large', 'Small')),
  price decimal
);

create table reservations (
  reservation_id int primary key,
  guest_id int references guests (guest_id),
  room_id int references rooms (room_id),
  check_in date not null,
  check_out date
);

create table payments (
  payment_id int primary key,
  reservation_id int references reservations (reservation_id),
  amount decimal
);

create table reservation_log (
  log_id int primary key,
  reservation_id int references reservations (reservation_id),
  action varchar(255)
);

set transaction name 'boarding_tr';

begin
  insert into guests values (1, 'Fasih', 'mail');
  insert into rooms values (1, 'Large', 2000);
  insert into reservations values (1, 1, 1, sysdate, null);
  insert into payments values (1, 1, 2000);
  insert into reservation_log values (1, 1, 'Rented');

  commit;
exception
  when others then
    dbms_output.put_line('Error: ' || sqlerrm);
    rollback;
end;
/

select * from guests
join reservations using (guest_id)
join rooms using (room_id)
join payments using (reservation_id)
join reservation_log using (reservation_id);

-- Q3 of past paper

create table sales (
  sale_id int primary key,
  product_id int references products (product_id),
  sale_date varchar(255) not null,
  sale_amount decimal not null
);

insert into sales values (1, 1, '2023-01-01', 3);
insert into sales values (2, 2, '2023-01-15', 5);
insert into sales values (3, 3, '2023-02-01', 2);

create sequence sales_seq
start with 4
increment by 1
nocache;

create or replace procedure RecordSale(p_product_id int, p_sale_amount int) as
  v_row products%rowtype;
begin
  select * into v_row from products where product_id = p_product_id;

  if v_row.stock_quantity - p_sale_amount < 0 then
    dbms_output.put_line('Insufficient stock for the sale');
  end if;

  insert into sales values (sales_seq.nextval, p_product_id, sysdate, p_sale_amount);
  update products set stock_quantity = stock_quantity - p_sale_amount where product_id = p_product_id;
exception
  when no_data_found then
    dbms_output.put_line('Product not found');
  when others then
    dbms_output.put_line('Error: ' || sqlerrm);
end;
/

exec RecordSale(6, 1);
select * from sales;

create or replace function GetTotalSalesAmount(f_product_id int) return int as
  tot int := 0;
begin
  for s in (select * from sales where product_id = f_product_id) loop
    tot := tot + s.sale_amount;
  end loop;
  return tot;
end;
/

select * from sales;

select GetTotalSalesAmount(3) as amount from dual;