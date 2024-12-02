create table promotion (
	id int unsigned primary key,
	content varchar(255),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TRIGGER ValidatePromotionDates
BEFORE INSERT ON promotion
FOR EACH ROW
BEGIN
    IF NEW.start_date > NEW.end_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The start_date cannot be later than the end_date.';
    END IF;
END;


INSERT INTO promotion (id, content, start_date, end_date)
VALUES 
(1, 'Black Friday Discount', '2024-11-28', '2024-12-02');
(2, 'Tet Holiday', '2024-11-28', '2025-02-01');

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

-- Adjusts all variations of product ID 101 with a 30% discount.
-- p_product_id | p_promotion_id | p_discount_rate | p_use_condition
CALL ApplyPromotion(101, 1, 30, 'Black Friday Deal');
CALL ApplyPromotion(601, 2, 20, 'Ngày hội mê túi xách');

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