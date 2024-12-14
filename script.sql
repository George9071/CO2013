CREATE TABLE store (
    id              INT UNSIGNED    PRIMARY KEY,
    name            VARCHAR(255)    NOT NULL,
	city            VARCHAR(255)    NOT NULL,    	
    street          VARCHAR(255)    NOT NULL,
    email           VARCHAR(255),
    phone_number    CHAR(10)        NOT NULL,
    number_of_emps  INT UNSIGNED    DEFAULT 0,
    manager_id      INT UNSIGNED    NULL,
	manage_date     DATE            NULL
);

CREATE TABLE employee (
    id              INT UNSIGNED    PRIMARY KEY,
	firstname       VARCHAR(255)    NOT NULL,	
	lastname        VARCHAR(255)    NOT NULL,
	gender          VARCHAR(20)     NOT NULL CHECK (gender='nam' OR gender='nữ'),
	phone_number    CHAR(10)        NOT NULL, 
    city            VARCHAR(255)    NOT NULL,    	
    street          VARCHAR(255)    NOT NULL,
    shift           VARCHAR(255)    NOT NULL CHECK (shift = 'sáng' OR shift = 'chiều' OR shift = 'tối'),
    start_date      DATE            NOT NULL,
    office          VARCHAR(255)    NOT NULL CHECK (office = 'normal' OR office = 'manager'),
    salary          INT UNSIGNED    DEFAULT 0,
    store_id        INT UNSIGNED    NULL,
    supervisor      INT UNSIGNED    NULL
);

CREATE TABLE catalog (
	id      INT UNSIGNED    PRIMARY KEY,
	name    VARCHAR(255)    NOT NULL        UNIQUE
);

CREATE TABLE catalog_in_store (
    catalog_id  INT UNSIGNED,
	store_id    INT UNSIGNED,
	PRIMARY KEY(catalog_id, store_id)
);

CREATE TABLE product (
	id                    INT UNSIGNED      PRIMARY KEY,
	name                  VARCHAR(255)      NOT NULL,
	description           VARCHAR(255),
	discount_for_employee INT UNSIGNED      default 0
);

CREATE TABLE product_in_catalog (
    catalog_id int unsigned,
    product_id int unsigned,
    primary key (product_id)
);

CREATE TABLE product_variation (
	id              varchar(255)                primary key,
	origin_price    int unsigned                default 0,
	sell_price      int unsigned                default 0,
	size            ENUM('S', 'M', 'L', 'D')    DEFAULT 'D' NOT NULL,
	product_id      int unsigned
);

CREATE TABLE variation_color (
	color           varchar(255), 
	variation_id    varchar(255),
	primary key (color, variation_id)
);

create table variation_in_store (
    variation_id    VARCHAR(255),
    store_id        INT UNSIGNED,
    color           VARCHAR(255),
    quantity        INT UNSIGNED    DEFAULT 0,
    PRIMARY KEY (variation_id, store_id, color)
);

CREATE TABLE customer (
    id            INT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    fullname      VARCHAR(255)  NOT NULL,
    phone_number  CHAR(10)      NULL,
    email         VARCHAR(255)  NULL,
    city          VARCHAR(255)  NULL,
    current_point INT UNSIGNED  DEFAULT 0
);

CREATE TABLE membership (
    customer_id   INT UNSIGNED                       PRIMARY KEY,
    register      DATE                               NOT NULL,
    points        INT UNSIGNED                       DEFAULT 0,
    card_type     ENUM('silver', 'gold', 'platinum') DEFAULT 'silver'
);

CREATE TABLE voucher (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    point_need  INT UNSIGNED DEFAULT 0,
    discount    INT UNSIGNED DEFAULT 0,
    store_id    INT UNSIGNED
);

CREATE TABLE exchanged_voucher (
    voucher_id  INT UNSIGNED,
    customer_id INT UNSIGNED,
    PRIMARY KEY (voucher_id, customer_id)
);

CREATE TABLE promotion (
	id          INT UNSIGNED    PRIMARY KEY,
	content     varchar(255),
    start_date  DATE            NOT NULL,
    end_date    DATE            NOT NULL
);

CREATE TABLE promotion_product (
    product_id      INT UNSIGNED,
    promotion_id    INT UNSIGNED,
    discount_rate   INT UNSIGNED DEFAULT 0 CHECK (discount_rate <= 100),
    use_condition   VARCHAR(255),
    PRIMARY KEY (product_id, promotion_id)
);

CREATE TABLE orders (
    id                  INT UNSIGNED               AUTO_INCREMENT PRIMARY KEY,
    order_date          DATE                       NOT NULL,
    conversion_point    INT UNSIGNED               DEFAULT 0,
    total_value         DECIMAL(10, 2)             DEFAULT 0,
    store_id            INT UNSIGNED               NOT NULL,
    processor           INT UNSIGNED               NULL,
    voucher_id          INT UNSIGNED               NULL,
    customer_id         INT UNSIGNED               NULL,
    order_type          ENUM('booking', 'receipt') NOT NULL
);

CREATE TABLE order_detail (
    order_id        INT UNSIGNED,
    variation_id    VARCHAR(255),
    color           VARCHAR(255),
    quantity        INT UNSIGNED    DEFAULT 0,
    primary key (order_id, variation_id, color)
);

CREATE TABLE booking (
    order_id    INT UNSIGNED                             PRIMARY KEY,
    pickup_date DATE                                     NULL,
    state       ENUM('Processing', 'Ready', 'Picked-up') DEFAULT 'Processing',
    paid        ENUM('Not paid', 'Paid')                 DEFAULT 'Not paid'
);

CREATE TABLE receipt (
    order_id   INT UNSIGNED     PRIMARY KEY,
    order_time TIMESTAMP        DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE revenue (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    month            INT          NOT NULL,
    year             INT          NOT NULL, 
    last_update      DATE         NOT NULL,
    note             VARCHAR(255),
    title            VARCHAR(255),
    number_of_orders INT UNSIGNED,
    store_id         INT UNSIGNED
);

CREATE TABLE provider (
    id      INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY, 
    name    VARCHAR(255)    UNIQUE,
    hotline VARCHAR(255),
    email   VARCHAR(255)
);

CREATE TABLE provided_product (
    provider_id     INT UNSIGNED,
    variation_id    VARCHAR(255),
    color           VARCHAR(255), 
    quantity        INT UNSIGNED DEFAULT 0,
    discount        INT UNSIGNED DEFAULT 0 CHECK (discout >= 0 AND discount <= 100),
    PRIMARY KEY (provider_id, variation_id, color)
);

CREATE TABLE warehouse (
    id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    street   VARCHAR(255),
    city     VARCHAR(255),
    store_id INT UNSIGNED,
    classify ENUM('at_store', 'out_store') NOT NULL
);

CREATE TABLE report (
    id           VARCHAR(255) PRIMARY KEY,
    name         VARCHAR(255),
    rp_date      INT CHECK (rp_date >= 1 AND rp_date <= 31),
    rp_month     INT CHECK (rp_month >= 1 AND rp_month <= 12),
    rp_year      INT,
    rp_type      enum ('import', 'export') NOT NULL,
    warehouse_id INT UNSIGNED
);

CREATE TABLE detail_report(
    report_id       VARCHAR(255),
    variation_id    VARCHAR(255),
    color           VARCHAR(255),
    quantity        INT UNSIGNED DEFAULT 0,
    primary key (report_id, variation_id, color)
);
-- --------------------------------------------------------------------------------------------------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER validate_store_email
BEFORE INSERT ON store
FOR EACH ROW
BEGIN
    IF NOT NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER validate_store_phone
BEFORE INSERT ON store
FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.phone_number) != 10 OR NOT NEW.phone_number REGEXP '^[0-9]{10}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid phone number format. It must contain exactly 10 digits.';
    END IF;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER check_phone BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.phone_number) != 10 OR NOT NEW.phone_number REGEXP '^[0-9]{10}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid phone number format. It must contain exactly 10 digits.';
    END IF;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER check_supervisor_consistency_insert
BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    -- Declare the necessary variables at the start of the BEGIN block
    DECLARE supervisor_shift VARCHAR(255);
    DECLARE supervisor_store_id INT;

    -- Check if the supervisor ID is not NULL
    IF NEW.supervisor IS NOT NULL THEN
        -- Retrieve supervisor's shift and store_id
        SELECT shift, store_id
        INTO supervisor_shift, supervisor_store_id
        FROM employee
        WHERE id = NEW.supervisor;

        -- Check if the supervisor's shift and store match the employee's shift and store
        IF supervisor_shift != NEW.shift THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Supervisor must have the same shift as the employee.';
        END IF;

        IF supervisor_store_id != NEW.store_id THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Supervisor must belong to the same store as the employee.';
        END IF;
    END IF;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER check_supervisor_consistency_update
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    -- Declare variables to hold supervisor's attributes
    DECLARE supervisor_shift VARCHAR(255);
    DECLARE supervisor_store_id INT;

    -- Only check if the supervisor field is being updated
    IF NEW.supervisor IS NOT NULL AND (NEW.supervisor != OLD.supervisor OR OLD.supervisor IS NULL) THEN
        -- Retrieve the supervisor's shift and store_id
        SELECT shift, store_id
        INTO supervisor_shift, supervisor_store_id
        FROM employee
        WHERE id = NEW.supervisor;

        -- Validate supervisor's shift consistency with the employee's current shift (OLD.shift)
        IF supervisor_shift != NEW.shift THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Supervisor must have the same shift as the employee.';
        END IF;

        -- Validate supervisor's store consistency with the employee's current store (OLD.store_id)
        IF supervisor_store_id != NEW.store_id THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Supervisor must belong to the same store as the employee.';
        END IF;
    END IF;
END
$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER validate_product_variation
BEFORE INSERT ON product_variation
FOR EACH ROW
BEGIN
    DECLARE error_message VARCHAR(255);

    -- Check if the product already has a variation with size 'D'
    IF NEW.size != 'D' AND EXISTS (
        SELECT 1
        FROM product_variation
        WHERE product_id = NEW.product_id AND size = 'D'
    ) THEN
        SET error_message = CONCAT(
            'Cannot add size ', NEW.size, 
            ' because a default size (D) variation already exists for product ID ', NEW.product_id
        );
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    END IF;

    -- Check if the product already has variations with specific sizes
    IF NEW.size = 'D' AND EXISTS (
        SELECT 1
        FROM product_variation
        WHERE product_id = NEW.product_id AND size != 'D'
    ) THEN
        SET error_message = CONCAT(
            'Cannot add default size (D) because specific size variations already exist for product ID ', NEW.product_id
        );
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    END IF;

    -- Ensure there is no duplicate size for the same product
    IF EXISTS (
        SELECT 1
        FROM product_variation
        WHERE product_id = NEW.product_id AND size = NEW.size
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A variation with the same size already exists for this product.';
    END IF;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER AdjustMembershipCardType
AFTER UPDATE ON membership
FOR EACH ROW
BEGIN
    DECLARE new_card_type ENUM('silver', 'gold', 'platinum');

    IF NEW.points <= 200 THEN
        SET new_card_type = 'silver';
    ELSEIF NEW.points BETWEEN 201 AND 1000 THEN
        SET new_card_type = 'gold';
    ELSE
        SET new_card_type = 'platinum';
    END IF;

    -- Update the card type if it has changed
    IF NEW.card_type != new_card_type THEN
        UPDATE membership
        SET card_type = new_card_type
        WHERE customer_id = NEW.customer_id;
    END IF;
END
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER ValidatePromotionDates
BEFORE INSERT ON promotion
FOR EACH ROW
BEGIN
    IF NEW.start_date > NEW.end_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ngày bắt đầu không thể sau ngày kết thúc';
    END IF;
END
$$
DELIMITER ;

DELIMITER $$
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
END
$$
DELIMITER ;

DELIMITER $$
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
END
$$
DELIMITER ;


DELIMITER $$
$$
DELIMITER ;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE AddProduct (
    IN p_catalog_id INT,
    IN p_name VARCHAR(255),
    IN p_description VARCHAR(255),
    IN p_discount_for_employee INT,
    OUT new_product_id INT -- Output parameter
)
BEGIN
    DECLARE next_product_id INT;

    -- Start the transaction
    START TRANSACTION;

    -- Determine the next product ID based on the catalog ID
    IF p_catalog_id BETWEEN 1 AND 7 THEN
        -- Lock the rows to prevent concurrent access
        SELECT MAX(id) + 1 INTO next_product_id
        FROM product
        WHERE LEFT(CAST(id AS CHAR), 1) = CAST(p_catalog_id AS CHAR)
        FOR UPDATE;

        -- If no products exist in the catalog, start from catalog_id * 100 + 1
        IF next_product_id IS NULL THEN
            SET next_product_id = p_catalog_id * 100 + 1;
        END IF;
    ELSE
        -- For catalogs starting with 8 or 9
        SELECT MAX(id) + 1 INTO next_product_id
        FROM product
        WHERE LEFT(CAST(id AS CHAR), 1) = CAST(p_catalog_id AS CHAR)
        FOR UPDATE;

        -- If no products exist, start from catalog_id * 100 + 1
        IF next_product_id IS NULL THEN
            SET next_product_id = p_catalog_id * 100 + 1;
        END IF;
    END IF;

    -- Insert the new product
    INSERT INTO product (id, name, description, discount_for_employee)
    VALUES (next_product_id, p_name, p_description, p_discount_for_employee);

    -- If the product belongs to a catalog, insert into the product_in_catalog table
    IF p_catalog_id BETWEEN 1 AND 7 THEN
        INSERT INTO product_in_catalog (catalog_id, product_id)
        VALUES (p_catalog_id, next_product_id);
    END IF;

    -- Set the output parameter
    SET new_product_id = next_product_id;

    -- Commit the transaction
    COMMIT;
END
$$
DELIMITER ;
-- CALL AddProduct(2, 'Áo hai 2 dây nữ', 'Áo Hai Dây Nữ Basic Có Đệm Ngực', 3);

DELIMITER $$
CREATE PROCEDURE InsertProductVariation(
    IN p_product_id INT UNSIGNED,
    IN p_origin_price INT UNSIGNED,
    IN p_size ENUM('S', 'M', 'L', 'D'),
    OUT new_variation_id VARCHAR(255) -- Output parameter
)
BEGIN
    DECLARE variation_id VARCHAR(255);
    DECLARE error_message VARCHAR(255);

    -- Start the transaction
    START TRANSACTION;

    -- Check if the product_id exists in the product table
    IF NOT EXISTS (
        SELECT 1
        FROM product
        WHERE id = p_product_id
        FOR UPDATE -- Lock the row to prevent concurrent modifications
    ) THEN
        SET error_message = CONCAT('The product with id: ', p_product_id, ' does not exist.');
        ROLLBACK; -- Rollback transaction in case of error
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    END IF;

    -- Generate the variation ID
    SET variation_id = CONCAT(p_product_id, p_size);

    -- Check if the variation ID already exists in the product_variation table
    IF EXISTS (
        SELECT 1
        FROM product_variation
        WHERE id = variation_id
        FOR UPDATE -- Lock the row to prevent concurrent modifications
    ) THEN
        SET error_message = CONCAT('The variation with id: ', variation_id, ' already exists.');
        ROLLBACK; -- Rollback transaction in case of error
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    END IF;

    -- Insert into the product_variation table
    INSERT INTO product_variation (
        id, product_id, size, origin_price, sell_price
    ) VALUES (
        variation_id, p_product_id, p_size, p_origin_price, p_origin_price
    );

    -- Set the output parameter
    SET new_variation_id = variation_id;

    -- Commit the transaction
    COMMIT;
END
$$
DELIMITER ;

-- CALL InsertProductVariation(101, 500, 'S');
-- CALL InsertProductVariation(101, 700, 'M');
-- CALL InsertProductVariation(103, 1000, 'M');
-- CALL InsertProductVariation(103, 1200, 'L');
-- CALL InsertProductVariation(401, 300, 'D');
-- CALL InsertProductVariation(601, 2400, 'D');

DELIMITER $$
CREATE FUNCTION CountProductsInCatalog(p_catalog_id INT) 
RETURNS INT
READS SQL DATA
BEGIN
    -- Variable declarations
    DECLARE product_count INT DEFAULT 0;
    DECLARE product_id INT;
    DECLARE done INT DEFAULT FALSE;

    -- Cursor declaration
    DECLARE product_cursor CURSOR FOR 
        SELECT product_id FROM product_in_catalog WHERE catalog_id = p_catalog_id;

    -- Handler declaration
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Check input parameter
    IF p_catalog_id IS NULL OR p_catalog_id NOT BETWEEN 1 AND 7 THEN
        RETURN -1; -- Return -1 for invalid catalog ID
    END IF;

    -- Open cursor and count products
    OPEN product_cursor;

    count_products: LOOP
        FETCH product_cursor INTO product_id;
        IF done THEN
            LEAVE count_products;
        END IF;
        SET product_count = product_count + 1;
    END LOOP;

    CLOSE product_cursor;

    RETURN product_count;
END
$$
DELIMITER ;
-- SELECT CountProductsInCatalog(1);

DELIMITER $$
CREATE PROCEDURE ExchangeVoucher(
    IN p_customer_id INT UNSIGNED,
    IN p_voucher_id INT UNSIGNED
)
BEGIN
    DECLARE v_point_need INT UNSIGNED;
    DECLARE v_current_point INT UNSIGNED;
    DECLARE error_message VARCHAR(255);

    -- Start a transaction
    START TRANSACTION;

    -- Fetch the points needed for the voucher and the customer's current points
    SELECT point_need INTO v_point_need
    FROM voucher
    WHERE id = p_voucher_id;

    SELECT current_point INTO v_current_point
    FROM customer
    WHERE id = p_customer_id;

    -- Validate that the customer has enough points
    IF v_current_point < v_point_need THEN
        SET error_message = CONCAT('Không đủ điểm để đổi voucher này! Điểm cần để quy đổi: ', v_point_need);
        
        -- Rollback the transaction before signaling an error
        ROLLBACK;
        
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    END IF;

    -- Deduct points from the customer's current points
    UPDATE customer
    SET current_point = current_point - v_point_need
    WHERE id = p_customer_id;

    -- Record the exchange in the exchanged_voucher table
    INSERT INTO exchanged_voucher (voucher_id, customer_id)
    VALUES (p_voucher_id, p_customer_id);

    -- Commit the transaction
    COMMIT;
END
$$
DELIMITER ;
CALL ExchangeVoucher(1, 2) -- Nguyễn Văn Anh exchanged voucher 2

DELIMITER $$
CREATE PROCEDURE AddNewPromotion(
    IN p_content VARCHAR(255),
    IN p_start_date DATE,
    IN p_end_date DATE,
    OUT new_promotion_id INT
)
BEGIN
    DECLARE v_new_id INT;
    DECLARE error_message VARCHAR(255);

    -- Start the transaction
    START TRANSACTION;

    -- Determine the new ID as max ID + 1
    SELECT IFNULL(MAX(id), 0) + 1 INTO v_new_id FROM promotion;

    -- Insert the new promotion
    INSERT INTO promotion (id, content, start_date, end_date)
    VALUES (v_new_id, p_content, p_start_date, p_end_date);

    -- Check if the insert was successful
    IF ROW_COUNT() = 0 THEN
        SET error_message = 'Failed to insert the new promotion.';
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    END IF;

    -- Commit the transaction
    COMMIT;

    -- Set the output parameter with the new promotion ID
    SET new_promotion_id = v_new_id;
END
$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE ApplyPromotion(
    IN p_product_id INT UNSIGNED,
    IN p_promotion_id INT UNSIGNED,
    IN p_discount_rate INT UNSIGNED,
    IN p_use_condition VARCHAR(255)
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    DECLARE v_active_promotion_count INT;

    -- Begin the transaction
    START TRANSACTION;

    -- Validate that the promotion is not expired
    SELECT start_date, end_date
    INTO v_start_date, v_end_date
    FROM promotion
    WHERE id = p_promotion_id;

    IF CURDATE() > v_end_date THEN
        -- Rollback and signal error if promotion is expired
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể áp dụng mã khuyến mãi đã hết hạn';
    END IF;

    -- Check if the product already has an active promotion
    SELECT COUNT(*)
    INTO v_active_promotion_count
    FROM promotion p
    JOIN promotion_product pp ON p.id = pp.promotion_id
    WHERE pp.product_id = p_product_id
      AND CURDATE() BETWEEN p.start_date AND p.end_date;

    IF v_active_promotion_count > 0 THEN
        -- Rollback and signal error if the product already has an active promotion
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sản phẩm đã được áp dụng khuyến mãi trước đó';
    END IF;

    -- Apply the new promotion
    INSERT INTO promotion_product (product_id, promotion_id, discount_rate, use_condition)
    VALUES (p_product_id, p_promotion_id, p_discount_rate, p_use_condition);

    -- Adjust the sell price of all variations of the product
    UPDATE product_variation
    SET sell_price = origin_price - (origin_price * p_discount_rate / 100)
    WHERE product_id = p_product_id;

    -- Commit the transaction if all operations are successful
    COMMIT;
END
$$
DELIMITER ;
-- Apply Promotion 1 to Product 101
-- CALL ApplyPromotion(101, 1, 20, 'Áp dụng cho toàn bộ kích cỡ');

DELIMITER $$
CREATE PROCEDURE DisplayPromotedProducts()
BEGIN
    SELECT 
        p.id AS product_id,
        p.name AS product_name,
        pp.promotion_id,
        promo.content AS promotion_name,
        pp.discount_rate,
        pp.use_condition,
        promo.start_date,
        promo.end_date
    FROM product p
    JOIN promotion_product pp ON p.id = pp.product_id
    JOIN promotion promo ON pp.promotion_id = promo.id
    WHERE CURDATE() BETWEEN promo.start_date AND promo.end_date
    ORDER BY promo.start_date, p.name;
END
$$
DELIMITER ;
-- CALL DisplayPromotedProducts();

DELIMITER $$
CREATE PROCEDURE AdjustDiscountRateForPromotion(
    IN p_promotion_id INT UNSIGNED,
    IN p_product_id INT UNSIGNED,
    IN p_new_discount_rate INT UNSIGNED
)
BEGIN
    -- Declare a handler to catch any SQL exceptions
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- If an error occurs, rollback the transaction
        ROLLBACK;
        -- Optionally, raise a custom error message
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Có lỗi xảy ra khi điều chỉnh mức khuyến mãi';
    END;

    -- Validate the discount rate
    IF p_new_discount_rate < 0 OR p_new_discount_rate > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Mức giảm giá phải nằm trong khoảng 0 đến 100';
    END IF;

    -- Start the transaction
    START TRANSACTION;

    -- Update the discount rate for the specified product under the given promotion
    UPDATE promotion_product
    SET discount_rate = p_new_discount_rate
    WHERE promotion_id = p_promotion_id
    AND product_id = p_product_id;

    -- Adjust the sell price for the specified product under this promotion
    UPDATE product_variation pv
    JOIN promotion_product pp ON pv.product_id = pp.product_id
    SET pv.sell_price = pv.origin_price - (pv.origin_price * p_new_discount_rate / 100)
    WHERE pp.promotion_id = p_promotion_id
    AND pp.product_id = p_product_id;

    -- If everything goes well, commit the transaction
    COMMIT;
END
$$
DELIMITER ;
-- CALL AdjustDiscountRateForPromotion(3, 104, 30); -- product 104 will have its discount rate changed to 30%

DELIMITER $$
CREATE PROCEDURE RemovePromotion(
    IN p_promotion_id INT UNSIGNED
)
BEGIN
    -- Declare a handler to catch any SQL exceptions
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- If an error occurs, rollback the transaction
        ROLLBACK;
        -- Optionally, raise a custom error message
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Có lỗi xảy ra khi xóa mã khuyến mãi';
    END;

    -- Start the transaction
    START TRANSACTION;

    -- Reset sell prices for all variations of products under the promotion
    UPDATE product_variation pv
    JOIN promotion_product pp ON pv.product_id = pp.product_id
    SET pv.sell_price = pv.origin_price
    WHERE pp.promotion_id = p_promotion_id;

    -- Remove the promotion from the promotion_product table
    DELETE FROM promotion_product
    WHERE promotion_id = p_promotion_id;

    -- Remove the promotion itself
    DELETE FROM promotion
    WHERE id = p_promotion_id;

    -- If everything goes well, commit the transaction
    COMMIT;
END
$$
DELIMITER ;
CALL RemovePromotion(3);

DELIMITER $$
CREATE PROCEDURE DetailSoldProduct (
    IN specified_month INT,
    IN specified_year INT,
    IN specified_store_id INT
)
BEGIN
    -- Validate month
    IF specified_month < 1 OR specified_month > 12 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Giá trị tháng không hợp lệ. Đảm bảo giá trị nằm trong khoảng 1 - 12';
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
END
$$
DELIMITER ;
-- CALL DetailSoldProduct (12, 2024, 10001);

DELIMITER $$
CREATE PROCEDURE OrdersByShift(
    IN specified_month INT,
    IN specified_year INT,
    IN specified_store_id INT
)
BEGIN
    -- Validate inputs
    IF specified_month < 1 OR specified_month > 12 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Giá trị tháng không hợp lệ. Đảm bảo giá trị nằm trong khoảng 1 - 12.';
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
END
$$
DELIMITER ;
CALL OrdersByShift(12, 2024, 10001);

DELIMITER $$
CREATE PROCEDURE CreateMonthlyRevenue()
BEGIN
    DECLARE current_month INT;
    DECLARE current_year INT;

    -- Start a transaction
    START TRANSACTION;

    BEGIN
        -- Get the current month and year
        SET current_month = MONTH(CURRENT_DATE);
        SET current_year = YEAR(CURRENT_DATE);

        -- Insert a new revenue record for each store if not already exists
        INSERT INTO revenue (month, year, last_update, note, title, number_of_orders, store_id)
        SELECT DISTINCT
            current_month,
            current_year,
            CURRENT_DATE,
            'Auto-created',
            CONCAT('Revenue for ', current_month, '/', current_year),
            0,
            id
        FROM store
        WHERE NOT EXISTS (
            SELECT 1
            FROM revenue
            WHERE month = current_month AND year = current_year AND store_id = store.id
        );
    END;

    -- Commit the transaction
    COMMIT;
END
$$
DELIMITER ;
CALL CreateMonthlyRevenue();

DELIMITER $$
CREATE PROCEDURE GenerateReportID(
    IN warehouse_id INT,
    IN report_type ENUM('import', 'export'),
    OUT generated_id VARCHAR(255)
)
BEGIN
    DECLARE prefix VARCHAR(255);
    DECLARE suffix INT DEFAULT 0;
    DECLARE type_code CHAR(2);

    -- Determine the report type code
    IF report_type = 'import' THEN
        SET type_code = 'IP';
    ELSEIF report_type = 'export' THEN
        SET type_code = 'EP';
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid report type';
    END IF;

    -- Generate the prefix
    SET prefix = CONCAT('RP', warehouse_id, type_code);

    -- Start transaction
    START TRANSACTION;

    -- Select and lock the relevant rows for update
    SELECT IFNULL(MAX(CAST(SUBSTRING(id, LENGTH(prefix) + 1) AS UNSIGNED)), 0)
    INTO suffix
    FROM report
    WHERE id COLLATE utf8mb4_unicode_ci LIKE CONCAT(prefix, '%') COLLATE utf8mb4_unicode_ci
    FOR UPDATE;

    -- Increment the suffix
    SET suffix = suffix + 1;

    -- Generate the report ID
    SET generated_id = CONCAT(prefix, suffix);

    -- Commit transaction
    COMMIT;
END
$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE InsertReportWithGeneratedID(
    IN warehouse_id INT,
    IN report_name VARCHAR(255),
    IN rp_date INT,
    IN rp_month INT,
    IN rp_year INT,
    IN rp_type ENUM('import', 'export')
)
BEGIN
    DECLARE generated_id VARCHAR(255);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        -- Rollback the transaction if any error occurs
        ROLLBACK;
    END;

    -- Start a transaction
    START TRANSACTION;

    -- Generate a unique report ID
    CALL GenerateReportID(warehouse_id, rp_type, generated_id);

    -- Insert the new report using the generated ID
    INSERT INTO report (id, name, rp_date, rp_month, rp_year, rp_type, warehouse_id)
    VALUES (generated_id, report_name, rp_date, rp_month, rp_year, rp_type, warehouse_id);

    -- Commit the transaction
    COMMIT;
END
$$
DELIMITER ;

DELIMITER $$
$$
DELIMITER ;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO store (id, name, city, street, email, phone_number)
VALUES 
(10001, 'Cửa hàng 1', 'Hồ Chí Minh', 'CMT8', 'dbHCM@gmail.com', '0912781462'),
(10002, 'Cửa hàng 2', 'Đà Nẵng', 'Võ Thị Sáu', 'dbDN@gmail.com', '0912781429'),
(10003, 'Cửa hàng 3', 'Hà Nội', 'Mai Chí Thọ', 'storeHN@gmail.com', '0912785127'),
(10004, 'Cửa hàng 4', 'Hà Nội', 'Hoàng Diệu', 'HNHD@gmail.com', '0926781830'),
(10005, 'Cửa hàng 5', 'Hồ Chí Minh', 'Bùi Viện', 'BVstore@gmail.com', '0912982829'),
(10006, 'Cửa hàng 6', 'Hồ Chí Minh', 'Phạm Ngũ Lão', 'PNLstore@gmail.com', '0926186464'),
(10007, 'Cửa hàng 7', 'Đà Lạt', 'Nguyễn Đình Chiểu', 'NDCstore@gmail.com', '0935741821'),
(10008, 'Cửa hàng 8', 'Cần Thơ', 'Hoàng Diệu', 'HoangDieustore@gmail.com', '0926715785');

INSERT INTO employee 
(id, firstname, lastname, gender, phone_number, city, street, shift, start_date, office, store_id, supervisor)
VALUES 
(10001, 'Nhi'   , 'Lê Thị Ý'    , 'nữ' , '0912726581', 'Hồ Chí Minh', 'Võ Văn Việt'     , 'sáng'    , '2020-02-15', 'manager', 10001, null),
(10002, 'Toàn'  , 'Nguyễn Văn'  , 'nam', '0912742781', 'Hồ Chí Minh', 'Lý Thường Kiệt'  , 'sáng'    , '2023-11-11', 'normal' , 10001, 10001),

(10003, 'Nam'   , 'Trần Đình'   , 'nam', '0912744618', 'Hồ Chí Minh', 'Võ Văn Ngân'     , 'chiều'   , '2022-08-02', 'normal' , 10001, null),
(10004, 'Hằng'  , 'Lê Thị'      , 'nữ' , '0912223456', 'Hồ Chí Minh', 'Nguyễn Trãi'     , 'chiều'   , '2023-01-05', 'manager', 10001, null),
(10005, 'Quân'  , 'Đỗ Hoàng'    , 'nam', '0912345678', 'Hồ Chí Minh', 'Lê Văn Sỹ'       , 'chiều'   , '2022-06-15', 'normal' , 10001, 10004),
(10006, 'Phương', 'Ngô Thị'     , 'nữ' , '0912789101', 'Hồ Chí Minh', 'CMT8'            , 'chiều'   , '2022-11-30', 'normal' , 10001, 10004),

(20002, 'Phúc'  , 'Nguyễn Hồng' , 'nam', '6658863045', 'Đà Nẵng'    , 'Hoàng Sa'        , 'sáng'    , '2021-10-10', 'manager', 10002, null),
(20005, 'Tấn'   , 'Hồ Trọng'    , 'nam', '6658862153', 'Đà Nẵng'    , 'Lê Duẫn'         , 'sáng'    , '2022-10-10', 'normal' , 10002, 20002),

(20001, 'Thịnh' , 'Trương Đức'  , 'nam', '0895134660', 'Đà Nẵng'    , 'Bạch Đằng'       , 'tối'     , '2022-02-14', 'manager' , 10002, null),
(20003, 'Thư'   , 'Phạm Thị'    , 'nữ' , '0912348910', 'Đà Nẵng'    , 'Hòa Xuân'        , 'tối'     , '2023-09-25', 'normal' , 10002, 20001),
(20004, 'Hải'   , 'Lê Văn'      , 'nam', '0912741256', 'Đà Nẵng'    , 'Liên Chiểu'      , 'tối'     , '2023-04-05', 'normal' , 10002, 20001);

INSERT INTO catalog (id, name) 
VALUES 
(1, 'Thời trang nam'), 
(2, 'Thời trang nữ'), 
(3, 'Thời trang thể thao'), 
(4, 'Phụ kiện'), 
(5, 'Giày dép'), 
(6, 'Túi và ví'), 
(7, 'Trang sức');

INSERT INTO catalog_in_store (catalog_id, store_id)
VALUES 
(1, 10001), (2, 10001), (3, 10001), (4, 10001), (5, 10001),
(1, 10002), (2, 10002), (5, 10002), (6, 10002), (7, 10002),
(1, 10003), (2, 10003), (4, 10003), (5, 10003), (7, 10003);

INSERT INTO product (id, name, description, discount_for_employee) 
VALUES 
(101, 'Áo sơ mi nam', 'Áo sơ mi nam chất liệu cotton', 0),
(102, 'Quần tây nam', 'Quần tây nam phong cách công sở', 0), 
(103, 'Áo thun nam', 'Áo thun nam thoáng mát', 0), 
(104, 'Áo khoác nam', 'Áo khoác nam thời trang', 10), 
(105, 'Giày lười nam', 'Giày lười nam kiểu dáng hiện đại', 5),

(201, 'Váy dạ hội', 'Váy dạ hội sang trọng', 5), 
(202, 'Áo sơ mi nữ', 'Áo sơ mi nữ chất liệu lụa', 0), 
(203, 'Quần jeans nữ', 'Quần jeans nữ co giãn', 0), 
(204, 'Áo thun nữ', 'Áo thun nữ mềm mại', 0), 
(205, 'Giày cao gót', 'Giày cao gót nữ thời trang', 15),

(301, 'Áo thể thao', 'Áo thể thao thoáng mát', 5), 
(302, 'Quần thể thao', 'Quần thể thao co giãn', 5), 
(303, 'Giày thể thao', 'Giày thể thao êm ái', 10), 
(304, 'Áo khoác thể thao', 'Áo khoác thể thao chống gió', 20), 
(305, 'Quần shorts thể thao', 'Quần shorts thể thao thoải mái', 5),

(401, 'Kính mát', 'Kính mát chống tia UV', 10), 
(402, 'Thắt lưng', 'Thắt lưng da cao cấp', 15), 
(403, 'Vòng tay bạc', 'Trang sức bạc tinh tế', 20), 
(404, 'Mũ lưỡi trai', 'Mũ lưỡi trai phong cách', 5), 
(405, 'Khăn quàng cổ', 'Khăn quàng cổ len mềm mại', 10),

(601, 'Túi xách tay', 'Túi xách tay thời trang', 30), 
(602, 'Balo', 'Balo đa năng', 15), 
(603, 'Ví cầm tay', 'Ví cầm tay phong cách', 20), 
(604, 'Túi đeo chéo', 'Túi đeo chéo tiện lợi', 15), 
(605, 'Túi du lịch', 'Túi du lịch rộng rãi', 25);

INSERT INTO product_in_catalog (catalog_id, product_id)
VALUES 
(1, 101), (1, 102), (1, 103), (1, 104), (1, 105),
(2, 201), (2, 202), (2, 203), (2, 204), (2, 205),
(3, 301), (3, 302), (3, 303), (3, 304), (3, 305),
(4, 401), (4, 402), (4, 403), (4, 404), (4, 405),
(6, 601), (6, 602), (6, 603), (6, 604), (6, 605);

set @new_variation_id = '0';
CALL InsertProductVariation(101, 500, 'S', @new_variation_id);
CALL InsertProductVariation(101, 700, 'M', @new_variation_id);
CALL InsertProductVariation(103, 1000, 'M', @new_variation_id);
CALL InsertProductVariation(103, 1200, 'L', @new_variation_id);
CALL InsertProductVariation(401, 300, 'D', @new_variation_id);
CALL InsertProductVariation(601, 2400, 'D', @new_variation_id);

INSERT INTO variation_color (color, variation_id) 
VALUES
('Light Yellow', '101M'), 
('Light Blue', '101M'), 
('Black', '101S'), 
('White', '101S'),
('Black', '401D'), 
('Gray', '401D');

INSERT INTO variation_in_store (variation_id, store_id, color, quantity)
VALUES
('101M', 10001, 'Light Yellow', 50),
('101M', 10001, 'Light Blue', 30),
('101S', 10001, 'Black', 40),
('101S', 10001, 'White', 20),
('401D', 10001, 'Black', 25),
('401D', 10001, 'Gray', 15),

('101M', 10002, 'Light Yellow', 60),
('101M', 10002, 'Light Blue', 45),
('101S', 10002, 'Black', 35),
('101S', 10002, 'White', 25),
('401D', 10002, 'Black', 30),
('401D', 10002, 'Gray', 20);

INSERT INTO customer (fullname, phone_number, email, city, current_point)
VALUES 
('Nguyễn Văn Anh', '0912345678', 'nguyenvananh@gmail.com', 'Hà Nội', 150),
('Trần Thị Bích Ngọc', '0923456789', 'bichngoctt@gmail.com', 'Hồ Chí Minh', 220),
('Lê Văn Toàn', '0934567890', 'levantoan@gmail.com', 'Đà Nẵng', 310),
('Phạm Thị Dung', '0945678901', 'dungphamthi@gmail.com', 'Hải Phòng', 180),
('Vũ Minh Thư', '0956789012', 'vuminhthư@gmail.com', 'Cần Thơ', 90);

INSERT INTO membership (customer_id, register, points, card_type)
VALUES 
(1, '2022-05-10', 150, 'silver'),
(2, '2021-12-25', 220, 'gold'),
(3, '2020-09-15', 1310, 'platinum'),
(4, '2023-02-20', 180, 'silver'),
(5, '2023-10-05', 90, 'silver');

INSERT INTO voucher (point_need, discount, store_id)
VALUES
(400, 10, 10001), -- Store 10001: 10% discount for 400 points
(500, 15, 10001), -- Store 10001: 15% discount for 500 points
(650, 12, 10002), -- Store 10002: 12% discount for 650 points
(1000, 20, 10002), -- Store 10002: 20% discount for 1000 points
(850, 18, 10003); -- Store 10003: 18% discount for 850 points

INSERT INTO exchanged_voucher (voucher_id, customer_id)
VALUES
(1, 1), -- Nguyễn Văn Anh exchanged voucher 1
(2, 2), -- Trần Thị Bích Ngọc exchanged voucher 2
(3, 3), -- Lê Văn Toàn exchanged voucher 3
(4, 4), -- Phạm Thị Dung exchanged voucher 4
(5, 5); -- Vũ Minh Thư exchanged voucher 5

set @new_variation_id = 0;
CALL AddNewPromotion('Black Friday', '2024-12-01', '2024-12-15', @new_variation_id);
CALL AddNewPromotion('Khuyến mãi 12/12', '2024-12-10', '2024-12-20', @new_variation_id);
CALL AddNewPromotion('Kỉ niệm 5 năm thành lập chuỗi cửa hàng', '2024-12-05', '2024-12-25', @new_variation_id);
CALL AddNewPromotion('Tết linh đình, mua sắm tưng bừng', '2024-12-01', '2024-12-31', @new_variation_id);
CALL AddNewPromotion('Flash Sale mùa tựu trường', '2024-09-12', '2024-11-13', @new_variation_id);

-- Apply Promotion 1 to Product 101
CALL ApplyPromotion(101, 1, 20, 'Áp dụng cho toàn bộ kích cỡ');

-- Apply Promotion 1 to Product 102
CALL ApplyPromotion(102, 1, 20, 'Áp dụng cho toàn bộ kích cỡ');

-- Apply Promotion 2 to Product 103
CALL ApplyPromotion(103, 2, 15, 'Áp dụng cho sản phẩm mua trực tiếp tại cửa hàng');

-- Apply Promotion 3 to Product 104
CALL ApplyPromotion(104, 3, 10, 'Khuyến mãi khả dụng cho khách hàng có thẻ hội viên');

-- Apply Promotion 3 to Product 105
CALL ApplyPromotion(105, 3, 10, 'Mua 2 sản phẩm được giảm giá 10%');

INSERT INTO orders 
(order_date, conversion_point, total_value, store_id, processor, voucher_id, customer_id, order_type)
VALUES
('2024-12-01', 50, 500.00, 10001, 10002, NULL, NULL, 'booking'),    -- Booking order for store 10001
('2024-12-02', 60, 600.00, 10002, 20002, NULL, NULL, 'booking'),    -- Booking order for store 10002
('2024-12-03', 70, 700.00, 10001, 10002, NULL, NULL, 'booking'),    -- Booking order for store 10001
('2024-12-04', 75, 750.00, 10001, 10002, NULL, NULL, 'booking'),    -- Booking order for store 10001

('2024-12-04', 80, 800.00, 10001, 10003, NULL, NULL, 'receipt'),    -- Receipt order for store 10001
('2024-12-05', 90, 900.00, 10002, 20004, NULL, NULL, 'receipt'),    -- Receipt order for store 10002
('2024-12-06', 100, 1000.00, 10001, 10006, NULL, NULL, 'receipt'),  -- Receipt order for store 10001
('2024-12-07', 200, 2000.00, 10001, 10005, NULL, NULL, 'receipt');  -- Receipt order for store 10001

INSERT INTO order_detail (order_id, variation_id, color, quantity)
VALUES
(1, '101M', 'Light Yellow', 2),
(1, '101M', 'Light Blue', 3),
(1, '101S', 'Black', 1),

(2, '101M', 'Light Yellow', 4),
(2, '101M', 'Light Blue', 2),
(2, '101S', 'White', 1),

(3, '101M', 'Light Yellow', 3),
(3, '101M', 'Light Blue', 3),
(3, '401D', 'Black', 1),

(4, '101M', 'Light Yellow', 5),
(4, '101M', 'Light Blue', 2),
(4, '101S', 'Black', 3);

INSERT INTO booking (order_id, pickup_date, state, paid)
VALUES
(1, '2024-12-10', 'Processing'  , 'Not paid'),         -- Booking 1
(2, '2024-12-11', 'Ready'       , 'Paid'),             -- Booking 2
(3, '2024-12-12', 'Picked-up'   , 'Paid'),             -- Booking 3
(4, '2024-12-09', 'Ready'       , 'Not paid');         -- Booking 4

INSERT INTO receipt (order_id, order_time)
VALUES
(5, '2024-12-04 10:10:00'), -- Receipt 1
(6, '2024-12-05 11:11:00'), -- Receipt 2
(7, '2024-12-06 12:12:00'), -- Receipt 3
(8, '2024-12-07 13:31:00'); -- Receipt 4

INSERT INTO revenue (month, year, last_update, note, title, number_of_orders, store_id) VALUES
(11, 2024, '2024-11-01', 'Generated for testing', 'Revenue for November 2024 - Cửa hàng 1', 0, 10001),
(12, 2024, '2024-12-13', 'Generated for testing', 'Revenue for December 2024 - Cửa hàng 1', 6, 10001),
(12, 2024, '2024-12-13', 'Generated for testing', 'Revenue for December 2024 - Cửa hàng 2', 2, 10002),
(12, 2024, '2024-12-13', 'Generated for testing', 'Revenue for December 2024 - Cửa hàng 3', 0, 10003);

INSERT INTO provider (name, hotline, email) 
VALUES
('Vogue Fabrics Inc.', '101-555-1234', 'contact@voguefabrics.com'),
('Runway Supply Co.', '202-555-2345', 'info@runwaysupply.com'),
('Elegant Threads Ltd.', '303-555-3456', 'support@elegantthreads.com'),
('Haute Couture Partners', '404-555-4567', 'sales@hautecouturepartners.com'),
('Trendsetters Apparel', '505-555-5678', 'service@trendsettersapparel.com');

INSERT INTO provided_product (provider_id, variation_id, color, quantity, discount)
VALUES
(1, '101M', 'Light Yellow', 100, 10),
(1, '101M', 'Light Blue', 80, 10),
(1, '101S', 'Black', 120, 15),

(2, '401D', 'Black', 50, 5),
(2, '401D', 'Gray', 40, 5),

(3, '101S', 'White', 90, 10),
(3, '101M', 'Light Yellow', 110, 12);

INSERT INTO warehouse (street, city, store_id, classify)
VALUES
('Nguyen Hue', 'Ho Chi Minh', 10001, 'at_store'),
('Le Duan', 'Da Nang', 10002, 'out_store'),
('Kim Ma', 'Ha Noi', 10003, 'at_store'),
('Ba Trieu', 'Ho Chi Minh', 10001, 'out_store'),
('Phan Chau Trinh', 'Da Nang', 10002, 'at_store');

CALL InsertReportWithGeneratedID(1, 'Import Report 1', 1, 12, 2024, 'import');
CALL InsertReportWithGeneratedID(2, 'Export Report 1', 2, 12, 2024, 'export');
CALL InsertReportWithGeneratedID(3, 'Import Report 2', 3, 12, 2024, 'import');
CALL InsertReportWithGeneratedID(1, 'Export Report 2', 4, 12, 2024, 'export');
CALL InsertReportWithGeneratedID(2, 'Import Report 3', 5, 12, 2024, 'import');

INSERT INTO detail_report (report_id, variation_id, color, quantity)
VALUES
('RP1EP1', '101M', 'Light Yellow', 100),
('RP1IP1', '101M', 'Light Blue', 150),
('RP2EP1', '101S', 'Black', 200),
('RP2IP1', '101S', 'White', 180),
('RP3IP1', '401D', 'Black', 120);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER TABLE store
ADD CONSTRAINT FK_store_employee
FOREIGN KEY (manager_id) REFERENCES employee(id);

ALTER TABLE employee
ADD CONSTRAINT FK_employee_store 
FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE employee
ADD CONSTRAINT FK_supervisor 
FOREIGN KEY (supervisor) REFERENCES employee(id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE catalog_in_store
ADD CONSTRAINT FK_catalog_store
FOREIGN KEY (catalog_id) REFERENCES catalog (id) ON UPDATE CASCADE ON DELETE CASCADE,
ADD CONSTRAINT FK_store_catalog
FOREIGN KEY (store_id)  REFERENCES store (id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE product_in_catalog
ADD CONSTRAINT FK_PIC_catalog
FOREIGN KEY (catalog_id) REFERENCES catalog(id) ON DELETE CASCADE,
ADD CONSTRAINT FK_PIC_product
FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE;

ALTER TABLE product_variation
ADD CONSTRAINT FK_variation_product
FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE;

ALTER TABLE variation_color
ADD CONSTRAINT FK_color_variation
FOREIGN KEY (variation_id) REFERENCES product_variation(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE variation_in_store
ADD CONSTRAINT FK_variation_in_store_store 
FOREIGN KEY (store_id) REFERENCES store(id) ON UPDATE CASCADE ON DELETE CASCADE,
ADD CONSTRAINT FK_color_in_store_color 
FOREIGN KEY (color) REFERENCES variation_color(color) ON UPDATE CASCADE ON DELETE CASCADE,
ADD CONSTRAINT FK_vc_in_store_variation 
FOREIGN KEY (variation_id) REFERENCES variation_color(variation_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE membership
ADD CONSTRAINT FK_membership_variation
FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE voucher
ADD CONSTRAINT FK_voucher_store
FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE exchanged_voucher 
ADD CONSTRAINT FK_exchanged_voucher_voucher
FOREIGN KEY (voucher_id) REFERENCES voucher(id) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT FK_exchanged_voucher_customer
FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE promotion_product
ADD CONSTRAINT FK_PP_product
FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE,
ADD CONSTRAINT FK_PP_promotion
FOREIGN KEY (promotion_id) REFERENCES promotion(id) ON DELETE CASCADE;

ALTER TABLE orders 
ADD CONSTRAINT FK_orders_store 
FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT FK_orders_employee 
FOREIGN KEY (processor) REFERENCES employee(id) ON DELETE SET NULL,
ADD CONSTRAINT FK_orders_voucher 
FOREIGN KEY (voucher_id) REFERENCES voucher(id) ON DELETE SET NULL,
ADD CONSTRAINT FK_oderrs_customer 
FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE SET NULL;

ALTER TABLE order_detail
ADD CONSTRAINT FK_detail_order
FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
ADD CONSTRAINT FK_detail_color
FOREIGN KEY (color) REFERENCES variation_color(color) ON DELETE CASCADE,
ADD CONSTRAINT FK_detail_variation
FOREIGN KEY (variation_id) REFERENCES variation_color(variation_id) ON DELETE CASCADE;

ALTER TABLE booking
ADD CONSTRAINT FK_booking_order
FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
        
ALTER TABLE receipt
ADD CONSTRAINT FK_receipt_order
FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;

ALTER TABLE revenue
ADD CONSTRAINT FK_revenue_store
FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE provided_product
ADD CONSTRAINT FK_PP_provider
FOREIGN KEY (provider_id) REFERENCES provider(id) ON UPDATE CASCADE ON DELETE CASCADE,
ADD CONSTRAINT FK_PP_variation
FOREIGN KEY (variation_id) REFERENCES variation_color(variation_id) ON UPDATE CASCADE ON DELETE CASCADE,
ADD CONSTRAINT FK_PP_color
FOREIGN KEY (color) REFERENCES variation_color(color) ON UPDATE CASCADE ON DELETE CASCADE;   

ALTER TABLE warehouse
ADD CONSTRAINT FK_warehouse_store
FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE report
ADD CONSTRAINT FK_report_warehouse
FOREIGN KEY (warehouse_id) REFERENCES warehouse(id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE detail_report
ADD CONSTRAINT FK_dtrp_report
FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE,
ADD CONSTRAINT FK_dtrp_variation
FOREIGN KEY (variation_id) REFERENCES variation_color(variation_id) ON DELETE CASCADE,
ADD CONSTRAINT FK_dtrp_color 
FOREIGN KEY (color) REFERENCES variation_color(color) ON DELETE CASCADE;