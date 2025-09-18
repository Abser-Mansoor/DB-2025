alter table employees add constraint unique_bonus unique (bonus);
INSERT INTO employees (employee_id, full_name, salary, department_id, bonus) VALUES (2, 'Jane Smith', 25000, 1, 1000);
INSERT INTO employees (employee_id, full_name, salary, department_id, bonus) VALUES (3, 'Bob Wilson', 30000, 2, 1000); -- This will fail
alter table employees add dob date;
alter table employees add constraint age_constraint check (months_between(DATE '2025-01-01', dob) / 12 >= 18);
insert into employees (employee_id, full_name, salary, department_id, bonus, dob) VALUES (5, 'Little Timmy', 25000, 1, 300, DATE '2018-04-18'); -- This will fail
alter table employees drop constraint fk_emp_dept;
insert into employees (employee_id, full_name, salary, department_id) values (6, 'Invalid Dept', 25000, 999); -- Department 999 doesn't exist
alter table employees add constraints fk_emp_dept foreign key (department_id) references departments(dept_id);
insert into employees (employee_id, full_name, salary, department_id) values (7, 'Still Invalid Dept', 50000, 890); -- fails
alter table employees drop (city, age);
select departments.dept_id, departments.dept_name, employees.employee_id, employees.full_name, employees.salary from departments left join employees on departments.dept_id = employees.department_id order by departments.dept_id, employees.employee_id;
select constraint_name from user_constraints where table_name = 'EMPLOYEES' and constraint_type = 'C' and search_condition like '%salary%';
alter table employees drop constraint SYS_C0012345;
alter table employees rename column salary to monthly_salary;
alter table employees add constraint check_salary check (monthly_salary > 20000);
select * from departments left join employees on departments.dept_id = employees.department_id where employees.employee_id is NULL;
truncate table employees;
SELECT *
FROM (
    SELECT d.dept_id, d.dept_name, COUNT(e.employee_id) as employee_count
    FROM departments d
    LEFT JOIN employees e ON d.dept_id = e.department_id
    GROUP BY d.dept_id, d.dept_name
    ORDER BY COUNT(e.employee_id) DESC
)
WHERE ROWNUM = 1;
