-- ======================================================================
-- NATIONAL UNIVERSITY OF COMPUTER AND EMERGING SCIENCES
-- Database Systems Lab Final Exam Solutions
-- Semester: Fall-2025 | Campus: Karachi
-- Instructor: Ms. Farecha Jabeen, Ms. Kinza Mushtaq
-- ======================================================================

/*

TABLE OF CONTENTS:

1. QUESTION #01: SQL QUERIES (LLQ #3)
   1.1 Employees earning > average salary of same hire year
   1.2 Employees with no job history, salary < min of those with history
   1.3 Employees with commission > average commission of their job
   1.4 Employees hired in department's peak hiring year
   1.5 Departments with >3 employees earning >5000

2. QUESTION #02: TRIGGERS & TRANSACTIONS (LLO #4)
   2.1 PL/SQL Trigger: prevent_negative_values
   2.2 Pharmacy Medicine Order Transaction

3. QUESTION #03: PL/SQL - ORDER BILLING SYSTEM (LLO #4)
   3.1 ORDER_ITEM object type
   3.2 Object table creation
   3.3 PL/SQL processing block

4. QUESTION #04: MONGODB QUERIES (LLO #3)
   4.1 Sample data insertion
   4.2 All required queries (1-10)

*/

-- ======================================================================
-- SECTION 1: QUESTION #01 - SQL QUERIES
-- ======================================================================

-- ----------------------------------------------------------------------
-- 1.1: Employees earning more than average salary of same hire year
-- ----------------------------------------------------------------------
WITH yearly_avg AS (
    SELECT 
        EXTRACT(YEAR FROM hire_date) as hire_year,
        AVG(salary) as avg_salary
    FROM employees
    GROUP BY EXTRACT(YEAR FROM hire_date)
)
SELECT 
    e.*,
    ya.avg_salary
FROM 
    employees e
    JOIN yearly_avg ya ON EXTRACT(YEAR FROM e.hire_date) = ya.hire_year
WHERE 
    e.salary > ya.avg_salary;

-- ----------------------------------------------------------------------
-- 1.2: Employees with no job history, salary < min of employees with history
-- ----------------------------------------------------------------------
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.salary,
    e.hire_date
FROM 
    employees e
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM job_history jh 
        WHERE jh.employee_id = e.employee_id
    )
    AND e.salary < (
        SELECT MIN(salary)
        FROM employees emp
        WHERE EXISTS (
            SELECT 1 
            FROM job_history jh2 
            WHERE jh2.employee_id = emp.employee_id
        )
    );

-- ----------------------------------------------------------------------
-- 1.3: Employees with commission > average commission of their job
-- ----------------------------------------------------------------------
WITH job_avg_commission AS (
    SELECT 
        job_id,
        AVG(commission_pct) as avg_comm
    FROM employees
    WHERE commission_pct IS NOT NULL
    GROUP BY job_id
)
SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    e.job_id,
    j.job_title,
    e.commission_pct,
    jac.avg_comm
FROM 
    employees e
    JOIN jobs j ON e.job_id = j.job_id
    JOIN job_avg_commission jac ON e.job_id = jac.job_id
WHERE 
    e.commission_pct > jac.avg_comm;

-- ----------------------------------------------------------------------
-- 1.4: Employees hired in department's peak hiring year
-- ----------------------------------------------------------------------
WITH yearly_dept_hires AS (
    SELECT 
        d.department_id,
        d.department_name,
        EXTRACT(YEAR FROM e.hire_date) as hire_year,
        COUNT(*) as hires_count,
        RANK() OVER (PARTITION BY d.department_id ORDER BY COUNT(*) DESC) as rank_hires
    FROM 
        employees e
        JOIN departments d ON e.department_id = d.department_id
    GROUP BY 
        d.department_id, d.department_name, EXTRACT(YEAR FROM e.hire_date)
),
max_hires_year AS (
    SELECT 
        department_id,
        hire_year
    FROM yearly_dept_hires
    WHERE rank_hires = 1
)
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name as employee_name,
    e.hire_date,
    d.department_name,
    EXTRACT(YEAR FROM e.hire_date) as hire_year,
    ydh.hires_count as total_hires_that_year
FROM 
    employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN max_hires_year mhy ON e.department_id = mhy.department_id 
        AND EXTRACT(YEAR FROM e.hire_date) = mhy.hire_year
    JOIN yearly_dept_hires ydh ON e.department_id = ydh.department_id 
        AND EXTRACT(YEAR FROM e.hire_date) = ydh.hire_year;

-- ----------------------------------------------------------------------
-- 1.5: Departments with >3 employees earning >5000
-- ----------------------------------------------------------------------
SELECT 
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) as high_earners_count,
    LISTAGG(e.first_name || ' ' || e.last_name, ', ') 
        WITHIN GROUP (ORDER BY e.salary DESC) as high_earners,
    SUM(e.salary) as total_high_salary
FROM 
    departments d
    JOIN employees e ON d.department_id = e.department_id
WHERE 
    e.salary > 5000
GROUP BY 
    d.department_id, d.department_name
HAVING 
    COUNT(e.employee_id) > 3;

-- ======================================================================
-- SECTION 2: QUESTION #02 - TRIGGERS & TRANSACTIONS
-- ======================================================================

-- ----------------------------------------------------------------------
-- 2.1: PL/SQL Trigger - prevent_negative_values
-- ----------------------------------------------------------------------
CREATE OR REPLACE TRIGGER prevent_negative_values
    BEFORE INSERT OR UPDATE ON PRODUCTS
    FOR EACH ROW
DECLARE
    v_old_stock NUMBER;
    v_stock_reduction_pct NUMBER;
    v_user VARCHAR2(50);
BEGIN
    -- Get current user
    v_user := USER;
    
    -- RULE 1: Prevent negative/zero PRICE and STOCK
    IF (:NEW.PRICE <= 0 OR :NEW.STOCK <= 0) THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Product_price dependent quantity cannot be negative or zero');
    END IF;
    
    -- RULE 2: Monitor low stock levels
    IF (:NEW.STOCK < 5) THEN
        DBMS_OUTPUT.PUT_LINE('Warning: The product is going out of stock');
    END IF;
    
    -- RULE 3: Restrict stock reduction >50%
    IF UPDATING AND :OLD.STOCK IS NOT NULL AND :OLD.STOCK > 0 THEN
        v_stock_reduction_pct := ((:OLD.STOCK - :NEW.STOCK) / :OLD.STOCK) * 100;
        IF v_stock_reduction_pct > 50 THEN
            RAISE_APPLICATION_ERROR(-20003, 
                'Stock reduction exceeds allowed limit (50%)');
        END IF;
    END IF;
    
    -- RULE 4: Auto-calculate SUBTOTAL
    :NEW.SUBTOTAL := :NEW.PRICE * NVL(:NEW.QUANTITY, 1);
    
    -- Prevent manual SUBTOTAL update
    IF UPDATING AND (:OLD.SUBTOTAL IS NOT NULL AND 
        (:NEW.SUBTOTAL != :OLD.SUBTOTAL)) THEN
        IF NOT (:NEW.PRICE != :OLD.PRICE OR :NEW.QUANTITY != :OLD.QUANTITY) THEN
            RAISE_APPLICATION_ERROR(-20004, 
                'This field cannot be updated manually');
        END IF;
    END IF;
    
    -- RULE 5: Maintain audit fields
    IF INSERTING THEN
        :NEW.CREATED_BY := v_user;
        :NEW.UPDATED_BY := v_user;
    ELSIF UPDATING THEN
        :NEW.UPDATED_BY := v_user;
        :NEW.CREATED_BY := :OLD.CREATED_BY;
    END IF;
    
    -- RULE 6: Update timestamp
    :NEW.LAST_UPDATED := SYSDATE;
    
END prevent_negative_values;
/

-- ----------------------------------------------------------------------
-- 2.2: Pharmacy Medicine Order Transaction
-- ----------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE place_medicine_order (
    p_customer_id IN NUMBER,
    p_med_id IN NUMBER,
    p_quantity IN NUMBER
) AS
    v_order_id NUMBER;
    v_current_stock NUMBER;
    v_medicine_price NUMBER;
    v_total_amount NUMBER;
BEGIN
    -- Start transaction
    SAVEPOINT start_transaction;
    
    -- Check stock availability
    SELECT stock, price 
    INTO v_current_stock, v_medicine_price
    FROM medicines 
    WHERE med_id = p_med_id
    FOR UPDATE;
    
    IF v_current_stock < p_quantity THEN
        RAISE_APPLICATION_ERROR(-20010, 'Insufficient stock');
    END IF;
    
    -- Create order
    SELECT order_seq.NEXTVAL INTO v_order_id FROM DUAL;
    INSERT INTO orders VALUES (v_order_id, p_customer_id, SYSDATE, 0);
    
    -- Add order item
    INSERT INTO order_items VALUES (
        order_item_seq.NEXTVAL, v_order_id, p_med_id, p_quantity
    );
    
    -- Update stock
    UPDATE medicines 
    SET stock = stock - p_quantity
    WHERE med_id = p_med_id;
    
    -- Calculate total
    v_total_amount := p_quantity * v_medicine_price;
    UPDATE orders SET total_amount = v_total_amount 
    WHERE order_id = v_order_id;
    
    -- Log success
    INSERT INTO order_log VALUES (
        order_log_seq.NEXTVAL, v_order_id, 'Order successful', SYSDATE
    );
    
    -- Commit
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO start_transaction;
        RAISE;
END;
/

-- ======================================================================
-- SECTION 3: QUESTION #03 - PL/SQL ORDER BILLING SYSTEM
-- ======================================================================

-- ----------------------------------------------------------------------
-- 3.1: Create ORDER_ITEM object type
-- ----------------------------------------------------------------------
CREATE OR REPLACE TYPE ORDER_ITEM AS OBJECT (
    item_name    VARCHAR2(100),
    quantity     NUMBER,
    price_per_unit NUMBER(10,2),
    
    MEMBER FUNCTION total_cost RETURN NUMBER,
    MEMBER PROCEDURE display_item
);
/

CREATE OR REPLACE TYPE BODY ORDER_ITEM AS
    MEMBER FUNCTION total_cost RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        v_total := self.quantity * self.price_per_unit;
        IF self.quantity > 5 THEN
            v_total := v_total * 0.95; -- 5% discount
        END IF;
        RETURN v_total;
    END;
    
    MEMBER PROCEDURE display_item IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Item: ' || self.item_name);
        DBMS_OUTPUT.PUT_LINE('Total: $' || self.total_cost());
    END;
END;
/

-- ----------------------------------------------------------------------
-- 3.2: Create object table
-- ----------------------------------------------------------------------
CREATE TABLE order_items_table OF ORDER_ITEM;

-- ----------------------------------------------------------------------
-- 3.3: PL/SQL processing block
-- ----------------------------------------------------------------------
DECLARE
    CURSOR c_items IS SELECT VALUE(oit) as item FROM order_items_table oit;
    v_item ORDER_ITEM;
    v_total_cost NUMBER;
    v_highest NUMBER := 0;
BEGIN
    FOR item_rec IN c_items LOOP
        v_item := item_rec.item;
        v_total_cost := v_item.total_cost();
        
        -- Display details
        DBMS_OUTPUT.PUT_LINE('Item: ' || v_item.item_name);
        DBMS_OUTPUT.PUT_LINE('Quantity: ' || v_item.quantity);
        DBMS_OUTPUT.PUT_LINE('Price: $' || v_item.price_per_unit);
        DBMS_OUTPUT.PUT_LINE('Final: $' || v_total_cost);
        
        IF v_item.quantity > 5 THEN
            DBMS_OUTPUT.PUT_LINE('(5% discount applied)');
        END IF;
        DBMS_OUTPUT.PUT_LINE('---');
        
        -- Track highest
        IF v_total_cost > v_highest THEN
            v_highest := v_total_cost;
        END IF;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Highest bill amount: $' || v_highest);
END;
/

-- ======================================================================
-- SECTION 4: QUESTION #04 - MONGODB QUERIES
-- ======================================================================

/*
MongoDB Queries Summary:

1. Employees without bonus:
   db.employees.find({ "bonus": 0 })

2. Top 3 highest-paid HR employees:
   db.employees.find({ "department": "HR" }).sort({ "salary": -1 }).limit(3)

3. Increase salary by 10% for active employees:
   db.employees.updateMany(
       { "lastActive": { $gte: new Date(Date.now() - 30*24*60*60*1000) } },
       { $mul: { "salary": 1.10 } }
   )

4. Total spending per customer:
   db.orders.aggregate([
       { $group: { _id: "$customerId", totalSpent: { $sum: "$totalAmount" } } }
   ])

5. Customers with >5 orders:
   db.orders.aggregate([
       { $group: { _id: "$customerId", orderCount: { $sum: 1 } } },
       { $match: { "orderCount": { $gt: 5 } } }
   ])

6. Orders with items > 50,000:
   db.orders.find({ "items.price": { $gt: 50000 } })

7. Same as query 3.

8. Most frequent product:
   db.orders.aggregate([
       { $unwind: "$items" },
       { $group: { _id: "$items.product", totalQty: { $sum: "$items.qty" } } },
       { $sort: { "totalQty": -1 } },
       { $limit: 1 }
   ])

9. Employees name starts with A or M:
   db.employees.find({ "name": { $regex: /^(A|M)/i } })

10. Yearly revenue:
    db.orders.aggregate([
        { $group: { 
            _id: { $year: "$orderDate" },
            revenue: { $sum: "$totalAmount" }
        } }
    ])
*/

-- ======================================================================
-- END OF SOLUTIONS
-- ======================================================================