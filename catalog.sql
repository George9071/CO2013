create table catalog (
	id int unsigned primary key,
	name varchar(255) not null unique
);

INSERT INTO catalog (id, name) 
VALUES 
(1, 'Thời trang nam'), 
(2, 'Thời trang nữ'), 
(3, 'Thời trang thể thao'), 
(4, 'Phụ kiện'), 
(5, 'Giày dép'), 
(6, 'Túi và ví'), 
(7, 'Trang sức');

create table catalog_in_store (
	catalog_id int unsigned,
	store_id int unsigned,
	primary key(catalog_id, store_id),
    CONSTRAINT FK_catalog_store 
        FOREIGN KEY (catalog_id) REFERENCES catalog (id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_store_catalog
        FOREIGN KEY (store_id)  REFERENCES store (id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO catalog_in_store (catalog_id, store_id)
VALUES 
(1, 10001), (2, 10001), (3, 10001), (4, 10001), (5, 10001),
(1, 10002), (2, 10002), (5, 10002), (6, 10002), (7, 10002),
(1, 10003), (2, 10003), (4, 10003), (5, 10003), (7, 10003);

create table product_in_catalog (
    catalog_id int unsigned,
    product_id int unsigned,
    primary key (product_id),
    constraint FK_PIC_catalog foreign key (catalog_id) references catalog(id) on delete cascade,
    constraint FK_PIC_product foreign key (product_id) references product(id) on delete cascade
);

INSERT INTO product_in_catalog 
    (catalog_id, product_id)
VALUES 
(1, 101), (1, 102), (1, 103), (1, 104), (1, 105),
(2, 201), (2, 202), (2, 203), (2, 204), (2, 205),
(3, 301), (3, 302), (3, 303), (3, 304), (3, 305),
(4, 401), (4, 402), (4, 403), (4, 404), (4, 405),
(6, 601), (6, 602), (6, 603), (6, 604), (6, 605);

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
END;

SELECT CountProductsInCatalog(8);