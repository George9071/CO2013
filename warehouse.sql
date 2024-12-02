create table warehouse (
    id int unsigned AUTO_INCREMENT primary key,
    street varchar(255),
    city varchar(255),
    store_id int unsigned,
    classify ENUM('at_store', 'out_store') NOT NULL,
    CONSTRAINT FK_warehouse_store
        FOREIGN KEY (store_id) REFERENCES store(id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

create table report (
    id varchar(255) primary key,
    name varchar(255),
    rp_date int,
    rp_month int,
    rp_year int,
    rp_type enum ('import', 'export'),
    warehouse_id int unsigned,
    CONSTRAINT report_date CHECK (rp_date >= 1 AND rp_date <= 31),
    CONSTRAINT report_month CHECK (rp_month >= 1 AND rp_month <= 12),
    CONSTRAINT FK_report_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouse(id)
);

create table detail_report(
    report_id varchar(255),
    variation_id varchar(255),
    color varchar(255),
    primary key (report_id, variation_id, variation_color),
    CONSTRAINT FK_dtrp_report
        FOREIGN KEY (report_id) REFERENCES report(id)
        ON DELETE CASCADE,
    CONSTRAINT FK_dtrp_report
        FOREIGN KEY (report_id) REFERENCES report(id)
        ON DELETE CASCADE,
    CONSTRAINT FK_dtrp_variation
        FOREIGN KEY (variation_id) REFERENCES variation_color(id)
        ON DELETE CASCADE,
    CONSTRAINT FK_dtrp_color
        FOREIGN KEY (color) REFERENCES variation_color(color)
        ON DELETE CASCADE
);

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

    -- Get the max suffix for reports with the same prefix
    SELECT IFNULL(MAX(CAST(SUBSTRING(id, LENGTH(prefix) + 1) AS UNSIGNED)), 0)
    INTO suffix
    FROM report
    WHERE id LIKE CONCAT(prefix, '%');

    -- Increment the suffix
    SET suffix = suffix + 1;

    -- Generate the report ID
    SET generated_id = CONCAT(prefix, suffix);
END;
