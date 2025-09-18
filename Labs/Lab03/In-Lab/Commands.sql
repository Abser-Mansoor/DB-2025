create table employees (
    employee_id NUMBER PRIMARY KEY,
    employee_name VARCHAR(25) NOT NULL,
    salary NUMBER(8, 2) CHECK (salary > 20000),
    department_id NUMBER
);

alter table employees rename column employee_name to full_name;
select constraint_name from user_constraints where table_name = 'EMPLOYEES' and constraint_type = 'C';
alter table employees drop constraint SYS_C007006;
CREATE TABLE departments (
    dept_id NUMBER PRIMARY KEY,
    dept_name VARCHAR2(50) UNIQUE
);

INSERT INTO departments (dept_id, dept_name) VALUES (1, 'IT');
INSERT INTO departments (dept_id, dept_name) VALUES (2, 'HR');
INSERT INTO departments (dept_id, dept_name) VALUES (3, 'Finance');
insert into employees (employee_id, full_name, salary, department_id) values (1, 'John Doe', 5000, 1);
alter table employees add constraint fk_emp_dpt foreign key (department_id) references departments(department_id);
alter table employees add bonus number(6,2) default 100;
alter table employees add ( city VARCHAR2(50) default 'Karachi', age number default 25 check (age > 18) );
insert into employees (employee_id, full_name, salary, department_id) values (2, 'Abser', 20000, 2);
insert into employees (employee_id, full_name, salary, department_id) values (3, 'Fasih', 40000, 1);
insert into employees (employee_id, full_name, salary, department_id) values (4, 'Ali', 60000, 2);
delete from employees where employee_id in (1,3);
alter table employees modify (
    full_name VARCHAR(20),
    city VARCHAR(20)
);
alter table employees add email VARCHAR(50) UNIQUE;
select * from employees
