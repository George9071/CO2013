create table employee (
	id int unsigned primary key,
	firstname varchar(255) not null,	
	lastname varchar(255) not null,
	gender varchar(20) not null check (gender='nam' OR gender='nữ'),
	phone_number char(10) not null, 
    city varchar(255) not null,    	
    street varchar(255) not null,
    shift VARCHAR(255) not null check (shift = 'sáng' OR shift = 'chiều' OR shift = 'tối'),
    start_date date not null,
    office varchar(255) not null check (office = 'normal' OR office = 'manager'),
    salary int unsigned default 0,
    store_id INT unsigned null,
    supervisor INT unsigned NULL,
    CHECK (phone_number LIKE '__________' AND phone_number REGEXP '^[0-9]{10}$'),
    CONSTRAINT fk_employee_store FOREIGN KEY (store_id) REFERENCES store(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_supervisor FOREIGN KEY (supervisor) REFERENCES employee(id) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TRIGGER check_gender BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    IF NEW.gender NOT IN ('nam', 'nữ') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid gender. Allowed values are "nam" or "nữ".';
    END IF;
END;

CREATE TRIGGER check_shift BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    IF NEW.shift NOT IN ('sáng', 'chiều', 'tối') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid shift. Allowed values are "sáng", "chiều", or "tối".';
    END IF;
END;

CREATE TRIGGER check_office BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    IF NEW.office NOT IN ('normal', 'manager') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid office. Allowed values are "normal" or "manager".';
    END IF;
END;

CREATE TRIGGER check_phone BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.phone_number) != 10 OR NOT NEW.phone_number REGEXP '^[0-9]{10}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid phone number format. It must contain exactly 10 digits.';
    END IF;
END;

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
END;

CREATE TRIGGER check_supervisor_consistency_update
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    -- Declare the necessary variables at the start of the BEGIN block
    DECLARE supervisor_shift VARCHAR(255);
    DECLARE supervisor_store_id INT;

    -- Only check if supervisor is changed
    IF NEW.supervisor IS NOT NULL AND NEW.supervisor != OLD.supervisor THEN
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
END;

--- Create a trigger after insert a employee will affect to number of employees || managerID of a store ---
INSERT INTO employee 
(id, firstname, lastname, gender, phone_number, city, street, shift, start_date, office, store_id, supervisor)
VALUES 
(10001, 'Nhi'   , 'Lê Thị Ý'    , 'nữ' , '0912726581', 'Hồ Chí Minh', 'Võ Văn Việt'     , 'sáng'    , '2020-02-15', 'manager', 10001, null),
(10002, 'Toàn'  , 'Nguyễn Văn'  , 'nam', '0912742781', 'Hồ Chí Minh', 'Lý Thường Kiệt'  , 'sáng'    , '2023-11-11', 'normal' , 10001, 10001),
(10003, 'Nam'   , 'Trần Đình'   , 'nam', '0912744618', 'Hồ Chí Minh', 'Võ Văn Ngân'     , 'chiều'   , '2022-08-02', 'normal' , 10001, null);
(20001, 'Thịnh' , 'Trương Đức'  , 'nam', '0895134660', 'Đà Nẵng'    , 'Bạch Đằng'       , 'tối'     , '2022-02-14', 'normal' , 10002, null),
(20002, 'Phúc'  , 'Nguyễn Hồng' , 'nam', '6658863045', 'Đà Nẵng'    , 'Hoàng Sa'        , 'sáng'    , '2021-10-10', 'manager', 10002, null),
(30001, 'Đức'   , 'Ngô Tài'     , 'nam', '6505342073', 'Hà Nội'     , 'Bùi Thị Xuân'    , 'chiều'   , '2023-11-11', 'normal' , 10003, null);