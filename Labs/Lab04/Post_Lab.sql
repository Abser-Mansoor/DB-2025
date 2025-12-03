select itemName from MenuItem where isAvailable = 0 AND price > 500;

select itemName from MenuItem where (category = 'Beverage' AND price > 300) OR category = 'Dessert';

select itemName, price from MenuItem where category = 'Snack' AND isAvailable = 1;

select itemName, price/100 from MenuItem where category = 'Snack' AND isAvailable = 1;

select Supplies.supplierID from Supplies left join MenuItem on Supplies.itemID = MenuItem.itemID where itemName = 'Cappucino';

select Employee.name, Cafe.cafeName from Employee left join Cafe on Employee.cafeID = Cafe.cafeID where Employee.cafeID = Cafe.cafeID AND Employee.address = Cafe.city;

select empID from Employee where salary != 50000;

select supplierID from Supplier where city = 'Karachi' INTERSECT select supplierID from Supplier where city = 'Lahore';

select itemName from MenuItem except select MenuItem.itemName from MenuItem left join Supplies on MenuItem.itemID = Supplies.itemID;