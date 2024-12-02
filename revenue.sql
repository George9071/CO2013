create table revenue (
    id int unsigned AUTO_INCREMENT primary key,
    month int not null,
    year int not null, 
    last_update date not null,
    note varchar(255),
    title varchar(255),
    number_of_orders int unsigned,
    store_id int unsigned,
    CONSTRAINT FK_revenue_store
        FOREIGN KEY (store_id) REFERENCES store(id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE PROCEDURE CreateMonthlyRevenue()
BEGIN
    DECLARE current_month INT;
    DECLARE current_year INT;

    -- Get the current month and year
    SET current_month = MONTH(CURRENT_DATE);
    SET current_year = YEAR(CURRENT_DATE);

    -- Insert a new revenue record for each store if not already exists
    INSERT INTO revenue (month, year, last_update, note, title, number_of_orders, store_id)
    SELECT DISTINCT
        current_month,
        current_year,
        CURRENT_DATE,
        'Auto-created',
        CONCAT('Revenue for ', current_month, '/', current_year),
        0,
        id
    FROM store
    WHERE NOT EXISTS (
        SELECT 1
        FROM revenue
        WHERE month = current_month AND year = current_year AND store_id = store.id
    );
END;

CREATE EVENT IF NOT EXISTS CreateRevenueEvent
ON SCHEDULE
    EVERY 1 MONTH
    STARTS (TIMESTAMP(CURRENT_DATE - INTERVAL DAY(CURRENT_DATE) - 1 DAY) + INTERVAL 1 MONTH)
DO
    CALL CreateMonthlyRevenue();

-- Manually --
CALL CreateMonthlyRevenue();