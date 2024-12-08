create table store (
    id int unsigned primary key,
    name varchar(255) not null,
	city varchar(255) not null,    	
    street varchar(255) not null,
    email varchar(255),
    phone_number char(10) not null,
    number_of_emps int unsigned default 0,
    -- manager_id int unsigned null,
	-- manage_date date null,
	CONSTRAINT store_email 
        CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT store_phone 
        CHECK (phone_number LIKE '__________' AND phone_number REGEXP '^[0-9]{10}$')
);

ALTER TABLE store
ADD COLUMN manager_id int unsigned;

ALTER TABLE store
ADD CONSTRAINT FK_store_employee
FOREIGN KEY (manager_id) REFERENCES employee(id);

CREATE TRIGGER validate_store_email
BEFORE INSERT ON store
FOR EACH ROW
BEGIN
    IF NOT NEW.email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format.';
    END IF;
END;

CREATE TRIGGER validate_store_phone
BEFORE INSERT ON store
FOR EACH ROW
BEGIN
    -- Check if the phone number is exactly 10 digits
    IF CHAR_LENGTH(NEW.phone_number) != 10 OR NOT NEW.phone_number REGEXP '^[0-9]{10}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid phone number format. It must contain exactly 10 digits.';
    END IF;
END;

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

select * from store;