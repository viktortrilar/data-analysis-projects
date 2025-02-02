-- Data cleaning practice with SQL
-- Kaggle link to dataset https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training

SELECT *
FROM dirty_cafe_sales;

-- Make new table for wrangling then insert data and make column to check for duplicates
CREATE TABLE cafe_stage
LIKE dirty_cafe_sales;

ALTER TABLE cafe_stage ADD COLUMN `row_num` INT;
INSERT INTO cafe_stage (`Transaction ID`, `Item`, `Quantity`, `Price Per Unit`, `Total Spent`, `Payment Method`, `Location`, `Transaction Date`, `row_num`)
SELECT `Transaction ID`, `Item`, `Quantity`, `Price Per Unit`, `Total Spent`, `Payment Method`, `Location`, `Transaction Date`,
ROW_NUMBER() OVER (PARTITION BY `Transaction ID`, `Item`, `Quantity`, `Price Per Unit`, `Total Spent`, `Payment Method`, `Location`, `Transaction Date`) AS `row_num`
FROM dirty_cafe_sales;

-- Check for duplicates
SELECT *
FROM cafe_stage
WHERE row_num > 1;


SELECT `Transaction Date`
FROM cafe_stage;

-- Handle missing Transaction dates
UPDATE cafe_stage
SET `Transaction Date` = NULL
WHERE `Transaction Date` = 'UNKNOWN'
OR `Transaction Date` = 'ERROR'
OR `Transaction Date` = '';
-- Convert text format data to DATE format
ALTER TABLE cafe_stage
MODIFY COLUMN `Transaction Date` DATE;

-- Handle missing payment method
UPDATE cafe_stage
SET `Payment Method` = NULL
WHERE `Payment Method` = 'UNKNOWN'
OR `Payment Method` = 'ERROR'
OR `Payment Method` = '';

-- Handle missing location data
UPDATE cafe_stage
SET `Location` = NULL
WHERE `Location` = 'UNKNOWN'
OR `Location` = 'ERROR'
OR `Location` = '';

-- Make temporary menu table to find missing items
CREATE TEMPORARY TABLE menu 
(
    Item VARCHAR(50),
    `Price per Unit` DECIMAL(5, 2)
);

-- Insert menu items
INSERT INTO menu (`Item`, `Price per Unit`) VALUES
('Coffee', 2),
('Tea', 1.5),
('Sandwich', 4),
('Salad', 5),
('Cake', 3),
('Cookie', 1),
('Smoothie', 4),
('Juice', 3);

-- Change missing items to items from the menu that match their unit price
UPDATE cafe_stage
SET `Item` = (
SELECT menu.`Item`
FROM menu
WHERE menu.`Price per Unit` * cafe_stage.Quantity = cafe_stage.`Total Spent`
LIMIT 1
)
WHERE `Item` IS NULL 
OR `Item` = 'UNKNOWN' 
OR `Item` = 'ERROR' 
OR `Item` = '';

-- Calculates missing Total Spent values by using item quantity * price of item
UPDATE cafe_stage
SET `Total Spent` = (`Quantity` * `Price Per Unit`)
WHERE `Total Spent` IS NULL 
OR `Total Spent` = 'UNKNOWN' 
OR `Total Spent` = 'ERROR'
OR `Total Spent` = '';

-- Optionally get mode to determine most common location (In-store)
CREATE TEMPORARY TABLE location_temp AS 
SELECT `Location` 
FROM cafe_stage 
WHERE `Location` IS NOT NULL 
GROUP BY `Location` 
ORDER BY COUNT(*) DESC 
LIMIT 1;

-- Set location to mode
UPDATE cafe_stage
SET `Location` = (
SELECT `Location` 
FROM location_temp 
LIMIT 1
)
WHERE `Location` IS NULL;

-- Optionally get mode to determine most common payment method (Digital Wallet)
CREATE TEMPORARY TABLE payment_method_temp AS 
SELECT `Payment Method` 
FROM cafe_stage 
WHERE `Payment Method` IS NOT NULL 
GROUP BY `Payment Method` 
ORDER BY COUNT(*) DESC 
LIMIT 1;

-- Set payment to mode
UPDATE cafe_stage
SET `Payment Method` = (SELECT `Payment Method` FROM payment_method_temp LIMIT 1)
WHERE `Payment Method` IS NULL;

-- Drop redundant row_num column
ALTER TABLE cafe_stage
DROP COLUMN row_num;


SELECT *
FROM cafe_stage;
