CREATE TABLE orders (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_date DATE NOT NULL,
    conversion_point INT UNSIGNED DEFAULT 0,
    total_value DECIMAL(10, 2) NOT NULL,
    store_id INT UNSIGNED NOT NULL,
    processor INT UNSIGNED NULL,
    voucher_id INT UNSIGNED DEFAULT NULL,
    customer_id INT UNSIGNED DEFAULT NULL,
    order_type ENUM('booking', 'receipt') NOT NULL,
    CONSTRAINT FK_orders_store FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE CASCADE,
    CONSTRAINT FK_orders_employee FOREIGN KEY (processor) REFERENCES employee(id) ON DELETE SET NULL,
    CONSTRAINT FK_orders_voucher FOREIGN KEY (voucher_id) REFERENCES voucher(id) ON DELETE SET NULL,
    CONSTRAINT FK_oderrs_customer FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE SET NULL
);

INSERT INTO orders 
(order_date, conversion_point, total_value, store_id, processor, voucher_id, customer_id, order_type)
VALUES
('2024-12-01', 50, 500.00, 10001, NULL, NULL, NULL, 'booking'), -- Booking order for store 10001
('2024-12-02', 60, 600.00, 10002, NULL, 1, NULL, 'booking'),    -- Booking order for store 10002
('2024-12-03', 70, 700.00, 10003, NULL, 2, NULL, 'booking'),    -- Booking order for store 10003
('2024-12-04', 80, 800.00, 10001, NULL, 3, NULL, 'receipt'),    -- Receipt order for store 10001
('2024-12-05', 90, 900.00, 10002, NULL, 4, NULL, 'receipt'),    -- Receipt order for store 10002
('2024-12-06', 100, 1000.00, 10003, NULL, 5, NULL, 'receipt');  -- Receipt order for store 10003

CREATE TABLE order_detail (
    order_id int unsigned,
    variation_id varchar(255),
    color varchar(255),
    quantity int unsigned default 0,
    primary key (order_id, variation_id, color),
    CONSTRAINT FK_detail_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_detail_color FOREIGN KEY (color) REFERENCES variation_color(color) ON DELETE CASCADE,
    constraint FK_detail_variation FOREIGN KEY (variation_id) REFERENCES variation_color(variation_id) ON DELETE CASCADE
);

-- Insert into order_detail (3 items per order)
INSERT INTO order_detail (order_id, variation_id, color, quantity)
VALUES
-- Order 1 details (store 10001)
(1, '101M', 'Light Yellow', 2),
(1, '101M', 'Light Blue', 3),
(1, '101S', 'Black', 1),

-- Order 2 details (store 10002)
(2, '101M', 'Light Yellow', 4),
(2, '101M', 'Light Blue', 2),
(2, '101S', 'White', 1),

-- Order 3 details (store 10003)
(3, '101M', 'Light Yellow', 3),
(3, '101M', 'Light Blue', 3),
(3, '401D', 'Black', 1),

-- Order 4 details (store 10001)
(4, '101M', 'Light Yellow', 5),
(4, '101M', 'Light Blue', 2),
(4, '101S', 'Black', 3),

-- Order 5 details (store 10002)
(5, '401D', 'Black', 4),
(5, '401D', 'Gray', 2),
(5, '101S', 'White', 1),

-- Order 6 details (store 10003)
(6, '101M', 'Light Yellow', 6),
(6, '101M', 'Light Blue', 3),
(6, '401D', 'Black', 2);


CREATE TABLE booking (
    order_id INT UNSIGNED PRIMARY KEY,
    pickup_date DATE NULL,
    state ENUM('Processing', 'Ready', 'Picked-up') DEFAULT 'Processing',
    paid ENUM('Not paid', 'Paid') DEFAULT 'Not paid',
    CONSTRAINT FK_booking_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- Insert into booking
INSERT INTO booking (order_id, pickup_date, state, paid)
VALUES
(1, '2024-12-10', 'Processing', 'Not paid'),  -- Booking 1
(2, '2024-12-11', 'Ready', 'Paid'),          -- Booking 2
(3, '2024-12-12', 'Picked-up', 'Paid');      -- Booking 3

-- add point to customer
-- add point to that customer membership
-- +1 to number of orders of that month in revenue
CREATE TRIGGER AfterBookingPaid
AFTER UPDATE ON booking
FOR EACH ROW
BEGIN
    DECLARE v_conversion_point INT;
    DECLARE v_customer_id INT;
    DECLARE v_total_value DECIMAL(10, 2);
    DECLARE v_store_id INT;

    -- Check if the paid status is updated from 'Not paid' to 'Paid'
    IF OLD.paid = 'Not paid' AND NEW.paid = 'Paid' THEN
        -- Retrieve total_value, customer_id, and store_id from the related order
        SELECT o.total_value, o.customer_id, o.store_id
        INTO v_total_value, v_customer_id, v_store_id
        FROM orders o
        WHERE o.id = NEW.order_id;

        -- If a customer ID is associated with the order
        IF v_customer_id IS NOT NULL THEN
            -- Calculate conversion points
            SET v_conversion_point = FLOOR(v_total_value / 1000);

            -- Update the customer's current points
            UPDATE customer
            SET current_point = current_point + v_conversion_point
            WHERE id = v_customer_id;

            -- Update membership points if the customer has a membership
            UPDATE membership
            SET points = points + v_conversion_point
            WHERE customer_id = v_customer_id;
        END IF;

        -- Update the revenue table
        UPDATE revenue
        SET number_of_orders = number_of_orders + 1, 
            last_update = CURDATE()
        WHERE month = MONTH((SELECT order_date FROM orders WHERE id = NEW.order_id))
          AND year = YEAR((SELECT order_date FROM orders WHERE id = NEW.order_id))
          AND store_id = (SELECT store_id FROM orders WHERE id = NEW.order_id);
    END IF;
END;


CREATE TABLE receipt (
    order_id INT UNSIGNED PRIMARY KEY,
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_receipt_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- Insert into receipt
INSERT INTO receipt (order_id, order_time)
VALUES
(4, '2024-12-04 10:00:00'), -- Receipt 1
(5, '2024-12-05 11:00:00'), -- Receipt 2
(6, '2024-12-06 12:00:00'); -- Receipt 3

CREATE TRIGGER AfterReceiptCreated
AFTER INSERT ON receipt
FOR EACH ROW
BEGIN
    DECLARE v_conversion_point INT;
    DECLARE v_customer_id INT;
    DECLARE v_total_value DECIMAL(10, 2);
    DECLARE v_store_id INT;

    -- Retrieve total_value, customer_id, and store_id from the related order
    SELECT o.total_value, o.customer_id, o.store_id
    INTO v_total_value, v_customer_id, v_store_id
    FROM orders o
    WHERE o.id = NEW.order_id;

    -- If a customer ID is associated with the order
    IF v_customer_id IS NOT NULL THEN
        -- Calculate conversion points
        SET v_conversion_point = FLOOR(v_total_value / 1000);

        -- Update the customer's current points
        UPDATE customer
        SET current_point = current_point + v_conversion_point
        WHERE id = v_customer_id;

        -- Update membership points if the customer has a membership
        UPDATE membership
        SET points = points + v_conversion_point
        WHERE customer_id = v_customer_id;
    END IF;

    -- Update the revenue table
    UPDATE revenue
    SET number_of_orders = number_of_orders + 1,
        last_update = CURDATE()
    WHERE month = MONTH((SELECT order_date FROM orders WHERE id = NEW.order_id))
      AND year = YEAR((SELECT order_date FROM orders WHERE id = NEW.order_id))
      AND store_id = (SELECT store_id FROM orders WHERE id = NEW.order_id);
END;

CREATE PROCEDURE DetailSoldProduct (
    IN specified_month INT,
    IN specified_year INT,
    IN specified_store_id INT
)
BEGIN
    -- Validate month
    IF specified_month < 1 OR specified_month > 12 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid month value. Must be between 1 and 12.';
    END IF;

    -- Main query
    SELECT 
        MONTH(o.order_date) AS month,
        YEAR(o.order_date) AS year,
        od.variation_id,
        od.color,
        SUM(od.quantity) AS quantity
    FROM 
        orders o
    JOIN 
        order_detail od ON o.id = od.order_id
    WHERE 
        o.store_id = specified_store_id
        AND MONTH(o.order_date) = specified_month
        AND YEAR(o.order_date) = specified_year
    GROUP BY 
        MONTH(o.order_date), YEAR(o.order_date), od.variation_id, od.color
    ORDER BY 
        od.variation_id, od.color;
END;

CALL DetailSoldProduct (12, 2024, 10003);

CREATE PROCEDURE OrdersByShift(
    IN specified_month INT,
    IN specified_year INT,
    IN specified_store_id INT
)
BEGIN
    -- Validate inputs
    IF specified_month < 1 OR specified_month > 12 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid month value. Must be between 1 and 12.';
    END IF;

    -- Main query
    SELECT 
        MONTH(o.order_date) AS month,
        YEAR(o.order_date) AS year,
        e.shift AS shift,
        COUNT(o.id) AS number_of_orders
    FROM 
        orders o
    LEFT JOIN 
        employee e ON o.processor = e.id
    WHERE 
        o.store_id = specified_store_id
        AND MONTH(o.order_date) = specified_month
        AND YEAR(o.order_date) = specified_year
    GROUP BY 
        MONTH(o.order_date), YEAR(o.order_date), e.shift
    ORDER BY 
        FIELD(e.shift, 'sáng', 'chiều', 'tối'); 
END;

CALL OrdersByShift(12, 2024, 10001);

DESCRIBE booking;