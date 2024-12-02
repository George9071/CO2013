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