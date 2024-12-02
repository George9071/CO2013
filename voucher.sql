CREATE TABLE voucher (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    point_need INT UNSIGNED DEFAULT 0,
    discount INT UNSIGNED DEFAULT 0,
    store_id INT UNSIGNED,
    CONSTRAINT FK_voucher_store
        FOREIGN KEY (store_id) REFERENCES store(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

INSERT INTO voucher (point_need, discount, store_id)
VALUES
(400, 10, 10001), -- Store 10001: 10% discount for 400 points
(500, 15, 10001), -- Store 10001: 15% discount for 500 points
(650, 12, 10002), -- Store 10002: 12% discount for 650 points
(1000, 20, 10002), -- Store 10002: 20% discount for 1000 points
(850, 18, 10003); -- Store 10003: 18% discount for 850 points

CREATE TABLE exchanged_voucher (
    voucher_id INT UNSIGNED,
    customer_id INT UNSIGNED,
    PRIMARY KEY (voucher_id, customer_id),
    CONSTRAINT FK_exchanged_voucher_voucher
        FOREIGN KEY (voucher_id) REFERENCES voucher(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_exchanged_voucher_customer    
        FOREIGN KEY (customer_id) REFERENCES customer(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE PROCEDURE ExchangeVoucher(
    IN p_customer_id INT UNSIGNED,
    IN p_voucher_id INT UNSIGNED
)
BEGIN
    DECLARE v_point_need INT UNSIGNED;
    DECLARE v_current_point INT UNSIGNED;
    DECLARE error_message VARCHAR(255);

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
END;