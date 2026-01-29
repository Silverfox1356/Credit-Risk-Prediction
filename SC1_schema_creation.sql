CREATE TABLE staging_inventory (
    `Date` VARCHAR(20),
    `Store_ID` VARCHAR(50),
    `Product_ID` VARCHAR(50),
    `Category` VARCHAR(50),
    `Region` VARCHAR(50),
    `Inventory_Level` INT,
    `Units_Sold` INT,
    `Units_Ordered` INT,
    `Demand_Forecast` DECIMAL(10, 2),
    `Price` DECIMAL(10, 2),
    `Discount` INT,
    `Weather_Condition` VARCHAR(50),
    `Holiday_Promotion` INT,
    `Competitor_Pricing` DECIMAL(10, 2),
    `Seasonality` VARCHAR(50)
);

LOAD DATA LOCAL INFILE 'C:/Users/risha/Downloads/inventory_forecasting.csv' 
INTO TABLE staging_inventory
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

create table stores(
	store_id varchar(10) primary key,
    region varchar(20) not null
);
alter table stores drop column region;

create table products(
	product_id varchar(10) primary key,
    category varchar(50) not null
);

create table daily_transactions(
	transaction_id int primary key auto_increment,
    transaction_date date not null,
    store_id varchar(10) not null,
    product_id varchar(10) not null,
    region varchar(50) not null,
    inventory_level int not null,
    units_sold int not null,
    units_ordered int not null,
    demand_forecast decimal(10,2) not null,
    price decimal(10,2) not null,
    discount decimal(10,2) not null,
    competitor_pricing decimal(10,2) not null,
    weather_condition varchar(20),
    holiday_promotion boolean not null,
    seasonality varchar(20) not null,
    foreign key(store_id) references stores(store_id),
    foreign key(product_id) references products(product_id)
);
insert into products
select distinct Product_ID,Category
from staging_inventory;

insert into stores
select distinct Store_ID
from staging_inventory;

INSERT INTO daily_transactions (
    transaction_date,
    store_id,
    product_id,
    region,
    inventory_level,
    units_sold,
    units_ordered,
    demand_forecast,
    price,
    discount,
    competitor_pricing,
    weather_condition,
    holiday_promotion,
    seasonality
)
SELECT 
    STR_TO_DATE(`Date`, '%d-%m-%Y'),  -- Converts '01-01-2022' to '2022-01-01'
    Store_ID,
    Product_ID,
    Region,
    Inventory_Level,
    Units_Sold,
    Units_Ordered,
    Demand_Forecast,
    Price,
    Discount,
    Competitor_Pricing,
    Weather_Condition,
    Holiday_Promotion,
    Seasonality
FROM staging_inventory;
