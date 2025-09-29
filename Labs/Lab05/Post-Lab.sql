select s.student_id, s.name student_name, t.teacher_id, t.name teacher_name, s.city from students s join teachers t on s.city = t.city;

select e.emp_id, e.name emp_name, m.name mgr_name from employees e left join employees m on e.mgr_id = m.emp_id;

select e.emp_id, e.name from employees e left join departments d on e.dept_id = d.dept_id where d.dept_id is null;

select e.dept_id, avg(e.salary) avg_salary from employees e group by e.dept_id having avg(e.salary) > 50000;

select e.emp_id, e.name, e.salary, e.dept_id from employees e where e.salary > ( select avg(salary) from employees where dept_id = e.dept_id );

select d.dept_id, d.dept_name from departments d where not exists ( select 1 from employees e where e.dept_id = d.dept_id and e.salary < 30000 );

select s.student_id, s.name student_name, c.course_id, c.course_name from students s join courses c on s.course_id = c.course_id where s.city = 'lahore';

select e.emp_id, e.name emp_name, m.name mgr_name, d.dept_name, e.hire_date from employees e left join employees m on e.mgr_id = m.emp_id left join departments d on e.dept_id = d.dept_id where e.hire_date between to_date('2020-01-01','yyyy-mm-dd') and to_date('2023-01-01','yyyy-mm-dd');

select s.student_id, s.name student_name, c.course_name from students s join courses c on s.course_id = c.course_id join teachers t on c.teacher_id = t.teacher_id where t.name = 'sir ali';

select e.emp_id, e.name emp_name, e.dept_id from employees e join employees m on e.mgr_id = m.emp_id where e.dept_id = m.dept_id;
