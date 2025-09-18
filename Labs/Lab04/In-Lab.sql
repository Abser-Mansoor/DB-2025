create table student (
    student_id number primary key,
    student_name varchar2(50) not null,
    gpa number(3,2),
    fee number(8,2),
    department varchar2(50),
    course varchar2(50)
);

create table faculty (
    faculty_id number primary key,
    faculty_name varchar2(50) not null,
    salary number(8,2),
    department varchar2(50)
);

insert into student values (1, 'ali', 3.8, 5000, 'CS', 'Database');
insert into student values (2, 'sara', 3.2, 4500, 'CS', 'Programming');
insert into student values (3, 'ahmed', 3.9, 6000, 'CS', 'Database');
insert into student values (4, 'fatima', 3.5, 5500, 'EE', 'Circuits');
insert into student values (5, 'mohammed', 2.8, 4000, 'EE', 'Electronics');
insert into student values (6, 'lina', 3.7, 5200, 'CS', 'Programming');
insert into student values (7, 'omar', 3.1, 4800, 'ME', 'Thermodynamics');
insert into student values (8, 'zainab', 3.6, 5300, 'CS', 'Database');

insert into faculty values (1, 'dr. smith', 80000, 'CS');
insert into faculty values (2, 'dr. johnson', 75000, 'CS');
insert into faculty values (3, 'dr. williams', 70000, 'EE');
insert into faculty values (4, 'dr. brown', 65000, 'ME');
insert into faculty values (5, 'dr. davis', 90000, 'CS');

select department, count(*) as student_count
from student
group by department;

select department, avg(gpa) as avg_gpa
from student
group by department
having avg(gpa) > 3.0;

select course, avg(fee) as avg_fee
from student
group by course;

select department, count(*) as faculty_count
from faculty
group by department;

select faculty_name, salary
from faculty
where salary > (select avg(salary) from faculty);

select student_name, gpa
from student
where gpa > any (select gpa from student where department = 'CS');

select student_name, gpa
from (select student_name, gpa from student order by gpa desc)
where rownum <= 3;

select student_name
from student s
where not exists (
    select course from student where student_name = 'ali'
    minus
    select course from student where student_id = s.student_id
);

select department, sum(fee) as total_fees
from student
group by department;

select distinct course
from student
where gpa > 3.5;
