create table product (
	id int unsigned primary key,
	name varchar(255) not null,
	description varchar(255),
	discount_for_employee int unsigned default 0
);

-- Insert products for 'Thời trang nam' (catalog id 1) 
INSERT INTO product (id, name, description, discount_for_employee) 
VALUES 
(101, 'Áo sơ mi nam', 'Áo sơ mi nam chất liệu cotton', 0),
(102, 'Quần tây nam', 'Quần tây nam phong cách công sở', 0), 
(103, 'Áo thun nam', 'Áo thun nam thoáng mát', 0), 
(104, 'Áo khoác nam', 'Áo khoác nam thời trang', 10), 
(105, 'Giày lười nam', 'Giày lười nam kiểu dáng hiện đại', 5);

-- Insert products for 'Thời trang nữ' (catalog id 2) 
INSERT INTO product (id, name, description, discount_for_employee) 
VALUES 
(201, 'Váy dạ hội', 'Váy dạ hội sang trọng', 5), 
(202, 'Áo sơ mi nữ', 'Áo sơ mi nữ chất liệu lụa', 0), 
(203, 'Quần jeans nữ', 'Quần jeans nữ co giãn', 0), 
(204, 'Áo thun nữ', 'Áo thun nữ mềm mại', 0), 
(205, 'Giày cao gót', 'Giày cao gót nữ thời trang', 15);

-- Insert products for 'Thời trang thể thao' (catalog id 3) 
INSERT INTO product (id, name, description, discount_for_employee) 
VALUES 
(301, 'Áo thể thao', 'Áo thể thao thoáng mát', 5), 
(302, 'Quần thể thao', 'Quần thể thao co giãn', 5), 
(303, 'Giày thể thao', 'Giày thể thao êm ái', 10), 
(304, 'Áo khoác thể thao', 'Áo khoác thể thao chống gió', 20), 
(305, 'Quần shorts thể thao', 'Quần shorts thể thao thoải mái', 5);

-- Insert products for 'Phụ kiện' (catalog id 4) 
INSERT INTO product (id, name, description, discount_for_employee) 
VALUES 
(401, 'Kính mát', 'Kính mát chống tia UV', 10), 
(402, 'Thắt lưng', 'Thắt lưng da cao cấp', 15), 
(403, 'Vòng tay bạc', 'Trang sức bạc tinh tế', 20), 
(404, 'Mũ lưỡi trai', 'Mũ lưỡi trai phong cách', 5), 
(405, 'Khăn quàng cổ', 'Khăn quàng cổ len mềm mại', 10);

-- Insert products for 'Túi và ví' (catalog id 6) 
INSERT INTO product (id, name, description, discount_for_employee) 
VALUES 
(601, 'Túi xách tay', 'Túi xách tay thời trang', 30), 
(602, 'Balo', 'Balo đa năng', 15), 
(603, 'Ví cầm tay', 'Ví cầm tay phong cách', 20), 
(604, 'Túi đeo chéo', 'Túi đeo chéo tiện lợi', 15), 
(605, 'Túi du lịch', 'Túi du lịch rộng rãi', 25);

create table product_variation (
	id varchar(255) primary key,
	origin_price int unsigned default 0,
	sell_price int unsigned default 0,
	size ENUM('S', 'M', 'L', 'D') NOT NULL DEFAULT 'D',
	product_id int unsigned,
    CONSTRAINT FK_variation_product
        FOREIGN KEY (product_id) REFERENCES product(id)
        ON DELETE CASCADE
);

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
END;

CREATE PROCEDURE insertProductVariation(
    IN p_product_id INT UNSIGNED,
    IN p_origin_price INT UNSIGNED,
    IN p_size ENUM('S', 'M', 'L', 'D') 
)
BEGIN
    DECLARE variation_id VARCHAR(255);
    DECLARE error_message VARCHAR(255);

    -- Check if the product_id exists in the product table
    IF NOT EXISTS (
        SELECT 1
        FROM product
        WHERE id = p_product_id
    ) THEN
        SET error_message = CONCAT('The product with id: ', p_product_id, ' does not exist.');
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    END IF;

    -- Generate the variation ID
    SET variation_id = CONCAT(p_product_id, p_size);

    -- Insert into the product_variation table
    INSERT INTO product_variation (
        id, product_id, size, origin_price, sell_price
    ) VALUES (
        variation_id, p_product_id, p_size, p_origin_price, p_origin_price
    );
END;

CALL insert_product_variation(101, 500, 'S');
CALL insert_product_variation(101, 700, 'M');
CALL insert_product_variation(103, 1000, 'M');
CALL insert_product_variation(103, 1200, 'L');
CALL insert_product_variation(401, 300, 'D');
CALL insert_product_variation(601, 2400, 'D');



