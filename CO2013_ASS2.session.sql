


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




-- CREATE PROCEDURE UpdateRevenueMetrics()
-- BEGIN
--     DECLARE done INT DEFAULT FALSE;
--     DECLARE v_store_id INT;

--     -- Cursor to loop through each store
--     DECLARE store_cursor CURSOR FOR
--         SELECT DISTINCT store_id FROM store;

--     -- Handler for ending the cursor loop
--     DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

--     -- Open the cursor
--     OPEN store_cursor;

--     store_loop: LOOP
--         FETCH store_cursor INTO v_store_id;
--         IF done THEN
--             LEAVE store_loop;
--         END IF;

--         -- 1. Check if revenue entry exists for the store for the current month
--         IF NOT EXISTS (
--             SELECT 1
--             FROM revenue
--             WHERE store_id = v_store_id
--               AND month = MONTH(CURDATE())
--               AND year = YEAR(CURDATE())
--         ) THEN
--             -- Create an entry for the current month if not exists
--             INSERT INTO revenue (id, month, year, last_update, note, title, number_of_orders, store_id)
--             VALUES (NULL, MONTH(CURDATE()), YEAR(CURDATE()), CURDATE(), NULL, CONCAT('Revenue for Store ', v_store_id), 0, v_store_id);
--         END IF;

--         -- 2. Update the number of variations of products sold for the store
--         UPDATE revenue
--         SET note = CONCAT(
--             'Products sold: ',
--             (
--                 SELECT COUNT(DISTINCT od.variation_id)
--                 FROM orders o
--                 JOIN order_detail od ON o.id = od.order_id
--                 WHERE o.store_id = v_store_id
--                   AND MONTH(o.order_date) = MONTH(CURDATE())
--                   AND YEAR(o.order_date) = YEAR(CURDATE())
--             )
--         )
--         WHERE store_id = v_store_id
--           AND month = MONTH(CURDATE())
--           AND year = YEAR(CURDATE());

--         -- 3. Calculate and update the number of orders per shift
--         UPDATE revenue
--         SET note = CONCAT(
--             note, '; Morning Shift Orders: ',
--             (
--                 SELECT COUNT(*)
--                 FROM orders o
--                 JOIN employee e ON o.processor = e.id
--                 WHERE e.store_id = v_store_id
--                   AND e.shift = 'sáng'
--                   AND MONTH(o.order_date) = MONTH(CURDATE())
--                   AND YEAR(o.order_date) = YEAR(CURDATE())
--             ),
--             '; Afternoon Shift Orders: ',
--             (
--                 SELECT COUNT(*)
--                 FROM orders o
--                 JOIN employee e ON o.processor = e.id
--                 WHERE e.store_id = v_store_id
--                   AND e.shift = 'chiều'
--                   AND MONTH(o.order_date) = MONTH(CURDATE())
--                   AND YEAR(o.order_date) = YEAR(CURDATE())
--             ),
--             '; Evening Shift Orders: ',
--             (
--                 SELECT COUNT(*)
--                 FROM orders o
--                 JOIN employee e ON o.processor = e.id
--                 WHERE e.store_id = v_store_id
--                   AND e.shift = 'tối'
--                   AND MONTH(o.order_date) = MONTH(CURDATE())
--                   AND YEAR(o.order_date) = YEAR(CURDATE())
--             )
--         )
--         WHERE store_id = v_store_id
--           AND month = MONTH(CURDATE())
--           AND year = YEAR(CURDATE());

--         -- 4. Update the total number of orders for the store
--         UPDATE revenue
--         SET number_of_orders = (
--             SELECT COUNT(*)
--             FROM orders
--             WHERE store_id = v_store_id
--               AND MONTH(order_date) = MONTH(CURDATE())
--               AND YEAR(order_date) = YEAR(CURDATE())
--         )
--         WHERE store_id = v_store_id
--           AND month = MONTH(CURDATE())
--           AND year = YEAR(CURDATE());
--     END LOOP;

--     -- Close the cursor
--     CLOSE store_cursor;
-- END;

-- CREATE TRIGGER UpdateCustomerPointsWhenBooking
-- AFTER UPDATE ON booking
-- FOR EACH ROW
-- BEGIN
--     DECLARE v_conversion_point INT;
--     DECLARE v_customer_id INT;
--     DECLARE v_total_value DECIMAL(10, 2);
--     DECLARE v_store_id INT;

--     -- Check if the booking state has changed to Paid
--     IF OLD.paid = 'Not paid' AND NEW.paid = 'Paid' THEN
--         -- Retrieve total_value and customer_id from the related order
--         SELECT o.total_value, o.customer_id, o.store_id
--         INTO v_total_value, v_customer_id, v_store_id
--         FROM orders o
--         WHERE o.id = NEW.order_id;

--         -- If a customer ID is associated with the order
--         IF v_customer_id IS NOT NULL THEN
--             -- Calculate conversion points
--             SET v_conversion_point = FLOOR(v_total_value / 1000);

--             -- Update the customer's current points
--             UPDATE customer
--             SET current_point = current_point + v_conversion_point
--             WHERE id = v_customer_id;

--             -- Update the membership points if the customer has a membership
--             UPDATE membership
--             SET points = points + v_conversion_point
--             WHERE customer_id = v_customer_id;
--         END IF;

--         -- Ensure revenue record exists for this store and month
--         IF NOT EXISTS (
--             SELECT 1
--             FROM revenue
--             WHERE store_id = v_store_id 
--               AND month = MONTH(CURDATE()) 
--               AND year = YEAR(CURDATE())
--         ) THEN
--             INSERT INTO revenue (month, year, last_update, note, title, number_of_orders, store_id)
--             VALUES (MONTH(CURDATE()), YEAR(CURDATE()), CURDATE(), NULL, CONCAT('Revenue for Store ', v_store_id), 0, v_store_id);
--         END IF;

--         -- Increment the total orders in the revenue table
--         UPDATE revenue
--         SET number_of_orders = number_of_orders + 1,
--             last_update = CURDATE()
--         WHERE store_id = v_store_id 
--           AND month = MONTH(CURDATE())
--           AND year = YEAR(CURDATE());
--     END IF;
-- END;

-- CREATE TRIGGER AddCustomerPointsWhenReceiptCreated
-- AFTER INSERT ON receipt
-- FOR EACH ROW
-- BEGIN
--     DECLARE v_conversion_point INT;
--     DECLARE v_customer_id INT;
--     DECLARE v_total_value DECIMAL(10, 2);
--     DECLARE v_store_id INT;

--     -- Retrieve total_value and customer_id from the related order
--     SELECT o.total_value, o.customer_id, o.store_id
--     INTO v_total_value, v_customer_id, v_store_id
--     FROM orders o
--     WHERE o.id = NEW.order_id;

--     -- If a customer ID is associated with the order
--     IF v_customer_id IS NOT NULL THEN
--         -- Calculate conversion points
--         SET v_conversion_point = FLOOR(v_total_value / 1000);

--         -- Update the customer's current points
--         UPDATE customer
--         SET current_point = current_point + v_conversion_point
--         WHERE id = v_customer_id;

--         -- Update the membership points if the customer has a membership
--         UPDATE membership
--         SET points = points + v_conversion_point
--         WHERE customer_id = v_customer_id;
--     END IF;

--     -- Ensure revenue record exists for this store and month
--     IF NOT EXISTS (
--         SELECT 1
--         FROM revenue
--         WHERE store_id = v_store_id 
--           AND month = MONTH(CURDATE()) 
--           AND year = YEAR(CURDATE())
--     ) THEN
--         INSERT INTO revenue (month, year, last_update, note, title, number_of_orders, store_id)
--         VALUES (MONTH(CURDATE()), YEAR(CURDATE()), CURDATE(), NULL, CONCAT('Revenue for Store ', v_store_id), 0, v_store_id);
--     END IF;

--     -- Increment the total orders in the revenue table
--     UPDATE revenue
--     SET number_of_orders = number_of_orders + 1,
--         last_update = CURDATE()
--     WHERE store_id = v_store_id 
--       AND month = MONTH(CURDATE())
--       AND year = YEAR(CURDATE());
-- END;





