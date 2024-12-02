CREATE TABLE customer (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fullname VARCHAR(255) NOT NULL,
    phone_number CHAR(10) NULL,
    email VARCHAR(255) NULL,
    city VARCHAR(255) NULL,
    current_point INT UNSIGNED DEFAULT 0
);

CREATE TRIGGER validate_customer_email
BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
    IF NOT NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format.';
    END IF;
END;

CREATE TRIGGER validate_customer_phone
BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
    -- Check if the phone number is exactly 10 digits
    IF CHAR_LENGTH(NEW.phone_number) != 10 OR NOT NEW.phone_number REGEXP '^[0-9]{10}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid phone number format. It must contain exactly 10 digits.';
    END IF;
END;

CREATE TABLE membership (
    customer_id INT UNSIGNED PRIMARY KEY,
    register DATE NOT NULL,
    points INT UNSIGNED DEFAULT 0,
    card_type ENUM('silver', 'gold', 'platinum') DEFAULT 'silver',
    FOREIGN KEY (customer_id) REFERENCES customer(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

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
END;