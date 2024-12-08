create table promotion (
	id int unsigned primary key,
	content varchar(255),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

INSERT INTO promotion (id, content, start_date, end_date)
VALUES 
(1, 'Black Friday Discount', '2024-11-28', '2024-12-02');

CREATE TRIGGER ValidatePromotionDates
BEFORE INSERT ON promotion
FOR EACH ROW
BEGIN
    IF NEW.start_date > NEW.end_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The start_date cannot be later than the end_date.';
    END IF;
END;

INSERT INTO promotion (content, start_date, end_date)
VALUES ('Promo Test', '2024-12-10', '2024-12-01');

drop procedure AddNewPromotion;

CREATE PROCEDURE AddNewPromotion(
    IN p_content VARCHAR(255),
    IN p_start_date DATE,
    IN p_end_date DATE,
    OUT new_promotion_id INT
)
BEGIN
    DECLARE v_new_id INT;

    -- Determine the new ID as max ID + 1
    SELECT IFNULL(MAX(id), 0) + 1 INTO v_new_id FROM promotion;

    -- Insert the new promotion
    INSERT INTO promotion (id, content, start_date, end_date)
    VALUES (v_new_id, p_content, p_start_date, p_end_date);

    -- Set the output parameter with the new promotion ID
    SET new_promotion_id = v_new_id;
END;

CALL AddNewPromotion('Lunar New Year 2025', '2024-12-08', '2025-03-01', @new_id);
-- Retrieve the new promotion ID
SELECT @new_id;


CALL AddNewPromotion(
    'New Year Ceremony 2025',
    '2024-12-01',
    '2025-02-01'
);

CALL AddNewPromotion(
    'New Year Ceremony 2025',
    '2024-12-01',
    '2025-02-01'
);

CALL AddNewPromotion(
    'New Year Ceremony 2025',
    '2024-12-01',
    '2025-02-01'
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE promotion_product (
    product_id INT UNSIGNED,
    promotion_id INT UNSIGNED,
    discount_rate INT UNSIGNED DEFAULT 0 CHECK (discount_rate <= 100),
    use_condition VARCHAR(255),
    PRIMARY KEY (product_id, promotion_id),
    FOREIGN KEY (product_id) REFERENCES product(id) ON DELETE CASCADE,
    FOREIGN KEY (promotion_id) REFERENCES promotion(id) ON DELETE CASCADE
);

CREATE PROCEDURE ApplyPromotion(
    IN p_product_id INT UNSIGNED,
    IN p_promotion_id INT UNSIGNED,
    IN p_discount_rate INT UNSIGNED,
    IN p_use_condition VARCHAR(255)
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    DECLARE v_is_expired BOOLEAN;

    -- Validate that the promotion is not expired
    SELECT start_date, end_date
    INTO v_start_date, v_end_date
    FROM promotion
    WHERE id = p_promotion_id;

    IF CURDATE() > v_end_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot apply an expired promotion to a product.';
    END IF;

    -- Check if the product already has an active promotion
    SELECT COUNT(*)
    INTO v_is_expired
    FROM promotion p
    JOIN promotion_product pp ON p.id = pp.promotion_id
    WHERE pp.product_id = p_product_id
      AND CURDATE() BETWEEN p.start_date AND p.end_date;

    IF v_is_expired > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product already has a valid promotion.';
    END IF;

    -- Apply the new promotion
    INSERT INTO promotion_product (product_id, promotion_id, discount_rate, use_condition)
    VALUES (p_product_id, p_promotion_id, p_discount_rate, p_use_condition);

    -- Adjust the sell price of all variations of the product
    UPDATE product_variation
    SET sell_price = origin_price - (origin_price * p_discount_rate / 100)
    WHERE product_id = p_product_id;
END;

-- p_product_id | p_promotion_id | p_discount_rate | p_use_condition
CALL ApplyPromotion(101, 1, 30, 'Black Friday Deal');
CALL ApplyPromotion(601, 2, 20, 'Ngày hội mê túi xách');
CALL ApplyPromotion(103, 2, 40, 'Hội áo thun');

CREATE EVENT ResetExpiredPromotions
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    DECLARE v_product_id INT;

    -- Declare a cursor to fetch all product IDs associated with expired promotions
    DECLARE cur CURSOR FOR
        SELECT DISTINCT pp.product_id
        FROM promotion p
        JOIN promotion_product pp ON p.id = pp.promotion_id
        WHERE CURDATE() > p.end_date;

    -- Declare a handler to handle the end of the cursor loop
    DECLARE CONTINUE HANDLER FOR NOT FOUND CLOSE cur;

    -- Open the cursor
    OPEN cur;

    promotion_loop: LOOP
        -- Fetch the next product_id
        FETCH cur INTO v_product_id;

        -- Exit the loop when there are no more rows
        IF v_product_id IS NULL THEN
            LEAVE promotion_loop;
        END IF;

        -- Reset sell prices for all variations of this product to the original price
        UPDATE product_variation
        SET sell_price = origin_price
        WHERE product_id = v_product_id;

        -- Remove the expired promotion from the promotion_product table
        DELETE FROM promotion_product
        WHERE product_id = v_product_id;
    END LOOP;

    -- Close the cursor
    CLOSE cur;
END;


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
END;
CALL DisplayPromotedProducts();

CREATE PROCEDURE AdjustDiscountRateForPromotion(
    IN p_promotion_id INT UNSIGNED,
    IN p_new_discount_rate INT UNSIGNED
)
BEGIN
    -- Validate the discount rate
    IF p_new_discount_rate < 0 OR p_new_discount_rate > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Discount rate must be between 0 and 100.';
    END IF;

    -- Update discount rate for the specified promotion
    UPDATE promotion_product
    SET discount_rate = p_new_discount_rate
    WHERE promotion_id = p_promotion_id;

    -- Adjust sell prices for all products under this promotion
    UPDATE product_variation pv
    JOIN promotion_product pp ON pv.product_id = pp.product_id
    SET pv.sell_price = pv.origin_price - (pv.origin_price * p_new_discount_rate / 100)
    WHERE pp.promotion_id = p_promotion_id;
END;
CALL AdjustDiscountRateForPromotion(2, 30);


CREATE PROCEDURE RemovePromotion(
    IN p_promotion_id INT UNSIGNED
)
BEGIN
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
END;
CALL RemovePromotion(2);
