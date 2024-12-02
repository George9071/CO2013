create table variation_color (
	color varchar(255), 
	variation_id varchar(255),
	primary key (color, variation_id),
    constraint FK_color_variation 
        FOREIGN KEY (variation_id) REFERENCES product_variation(id)
        ON UPDATE CASCADE 
        ON DELETE CASCADE
);

-- Insert colors for variation of product ID '101M' và '101S' (Áo sơ mi nam size M và size S)
-- Insert colors for variation of product ID '401' (Kính mát)
INSERT INTO variation_color (color, variation_id) VALUES
('Light Yellow', '101M'), 
('Light Blue', '101M'), 
('Black', '101S'), 
('White', '101S');
('Black', '401D'), 
('Gray', '401D');

create table variation_in_store (
    variation_id VARCHAR(255),
    store_id INT UNSIGNED,
    color VARCHAR(255),
    quantity INT UNSIGNED DEFAULT 0,
    PRIMARY KEY (variation_id, store_id, color),
    CONSTRAINT FK_color_in_store_store 
        FOREIGN KEY (store_id) REFERENCES store(id)
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT FK_color_in_store_color 
        FOREIGN KEY (color, variation_id) REFERENCES variation_color(color, variation_id)
        ON UPDATE CASCADE 
        ON DELETE CASCADE
);

INSERT INTO variation_in_store (variation_id, store_id, color, quantity)
VALUES
('101M', 10001, 'Light Yellow', 50),
('101M', 10001, 'Light Blue', 30),
('101S', 10001, 'Black', 40),
('101S', 10001, 'White', 20),
('401D', 10001, 'Black', 25),
('401D', 10001, 'Gray', 15),

('101M', 10002, 'Light Yellow', 60),
('101M', 10002, 'Light Blue', 45),
('101S', 10002, 'Black', 35),
('101S', 10002, 'White', 25),
('401D', 10002, 'Black', 30),
('401D', 10002, 'Gray', 20),

('101M', 10003, 'Light Yellow', 70),
('101M', 10003, 'Light Blue', 50),
('101S', 10003, 'Black', 30),
('101S', 10003, 'White', 35),
('401D', 10003, 'Black', 40),
('401D', 10003, 'Gray', 25);

