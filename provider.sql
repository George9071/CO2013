create table provider (
    id int unsigned AUTO_INCREMENT, 
    name varchar(255) unique,
    hotline varchar(255),
    email varchar(255),
    primary key (id)
);

INSERT INTO provider 
    (name, hotline, email) 
VALUES
('Vogue Fabrics Inc.', '101-555-1234', 'contact@voguefabrics.com'),
('Runway Supply Co.', '202-555-2345', 'info@runwaysupply.com'),
('Elegant Threads Ltd.', '303-555-3456', 'support@elegantthreads.com'),
('Haute Couture Partners', '404-555-4567', 'sales@hautecouturepartners.com'),
('Trendsetters Apparel', '505-555-5678', 'service@trendsettersapparel.com'),
('Urban Chic Suppliers', '606-555-6789', 'hello@urbanchicsuppliers.com');

create table provided_product (
    provider_id int unsigned,
    variation_id varchar(255),
    color varchar(255), 
    quantity int unsigned default 0,
    discount int unsigned default 0 check (discout >= 0 AND discount <= 100),
    primary key (provider_id, variation_id, color),
    CONSTRAINT FK_PP_provider
        FOREIGN KEY (provider_id) REFERENCES provider(id) ON UPDATE CASCADE,
    CONSTRAINT FK_PP_variation
        FOREIGN KEY (variation_id) REFERENCES variation_color(variation_id) ON UPDATE CASCADE,
    CONSTRAINT FK_PP_color
        FOREIGN KEY (color) REFERENCES variation_color(color) ON UPDATE CASCADE    
);

