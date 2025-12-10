-- Q1
create table bank_accounts (
  account_no    number,
  holder_name   varchar(50),
  balance       number
);

insert into bank_accounts values (1, 'Account A', 20000);
insert into bank_accounts values (2, 'Account B', 15000);
insert into bank_accounts values (3, 'Account C', 10000);

commit;

update bank_accounts set balance = balance - 5000 where account_no = 1;
update bank_accounts set balance = balance + 5000 where account_no = 2;
update bank_accounts set balance = balance + 2000 where account_no = 3;

rollback;

select * from bank_accounts;

-- Q2
create table inventory (
  item_id    number,
  item_name  varchar(30),
  quantity   number
);

insert into inventory values (1, 'Item A', 100);
insert into inventory values (2, 'Item B', 200);
insert into inventory values (3, 'Item C', 150);
insert into inventory values (4, 'Item D', 300);

commit;

update inventory set quantity = quantity - 10 where item_id = 1;
savepoint sp1;
update inventory set quantity = quantity - 20 where item_id = 2;
savepoint sp2;
update inventory set quantity = quantity - 5 where item_id = 3;

rollback to sp1;

commit;

select * from inventory;

-- Q3
create table fees (
  student_id   number,
  name         varchar(30),
  amount_paid  number,
  total_fee    number
);

insert into fees values (1, 'Ali', 2000, 5000);
insert into fees values (2, 'Sara', 3000, 5000);
insert into fees values (3, 'Ahmed', 1500, 5000);

commit;

update fees set amount_paid = amount_paid + 500 where student_id = 1;
savepoint halfway;
update fees set amount_paid = amount_paid + 1000 where student_id = 2;

rollback to halfway;

commit;

select * from fees;

-- Q4
create table products (
  product_id    number,
  product_name  varchar(30),
  stock         number
);

create table orders (
  order_id     number,
  product_id   number,
  quantity     number
);

insert into products values (1, 'Laptop', 50);
insert into products values (2, 'Mouse', 100);

commit;

update products set stock = stock - 5 where product_id = 1;
insert into orders values (1, 1, 5);
delete from products where product_id = 2;

rollback;

update products set stock = stock - 5 where product_id = 1;
insert into orders values (1, 1, 5);

commit;

select * from products;
select * from orders;

-- Q5
create table employees (
  emp_id    number,
  emp_name  varchar(30),
  salary    number
);

insert into employees values (1, 'Ahsan', 30000);
insert into employees values (2, 'Bilal', 35000);
insert into employees values (3, 'Hassan', 32000);
insert into employees values (4, 'Usman', 40000);
insert into employees values (5, 'Zain', 45000);

commit;

update employees set salary = salary + 2000 where emp_id = 1;
savepoint A;
update employees set salary = salary + 3000 where emp_id = 2;
savepoint B;
update employees set salary = salary + 2500 where emp_id = 3;

rollback to A;

commit;

select * from employees;
