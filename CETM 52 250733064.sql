/* sequences need to be dropped before the tables that use them */
DROP SEQUENCE IF EXISTS purchase_id_seq;
DROP SEQUENCE IF EXISTS product_id_seq;
DROP SEQUENCE IF EXISTS store_id_seq;
DROP SEQUENCE IF EXISTS account_id_seq;
DROP SEQUENCE IF EXISTS customer_id_seq;

/* child tables dropped before parent tables to resolve any referential integrity issues */

DROP TABLE IF EXISTS purchase_line;
DROP TABLE IF EXISTS stock;
DROP TABLE IF EXISTS purchase;
DROP TABLE IF EXISTS bank_account;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS store;
DROP TABLE IF EXISTS customer;

/* sequences must be created created in the correct order of parent tables before child tables */

CREATE SEQUENCE customer_id_seq START WITH 1001 INCREMENT BY 1;
CREATE SEQUENCE account_id_seq START WITH 501 INCREMENT BY 1;
CREATE SEQUENCE store_id_seq START WITH 201 INCREMENT BY 1;
CREATE SEQUENCE product_id_seq START WITH 3001 INCREMENT BY 1;
CREATE SEQUENCE purchase_id_seq START WITH 9001 INCREMENT BY 1;

/*tables created in the correct order to resolve foreign key references */ 

CREATE TABLE customer
(customer_id      INTEGER      NOT NULL DEFAULT nextval('customer_id_seq') PRIMARY KEY,
customer_forename VARCHAR(50)  NOT NULL,
customer_surname  VARCHAR(50)  NOT NULL,
customer_street   VARCHAR(100) NOT NULL,
customer_area     VARCHAR(100),                        
customer_town     VARCHAR(50)  NOT NULL,
customer_pcode    VARCHAR(10)  NOT NULL,
customer_telno    VARCHAR(15)  NOT NULL,
customer_email    VARCHAR(100),                        
customer_gender   CHAR(1)      NOT NULL CHECK (customer_gender IN ('M', 'F', 'O')),
customer_dob      DATE         NOT NULL);


CREATE TABLE bank_account
(account_id     INTEGER      NOT NULL DEFAULT nextval('account_id_seq') PRIMARY KEY,
customer_id    INTEGER      NOT NULL REFERENCES customer(customer_id),
bank_name      VARCHAR(100) NOT NULL,
bank_street    VARCHAR(100) NOT NULL,
bank_area      VARCHAR(100),                            
bank_town      VARCHAR(50)  NOT NULL,
bank_pcode     VARCHAR(10)  NOT NULL,
bank_telno     VARCHAR(15),                         
bank_sortcode  CHAR(8)      NOT NULL,                 
bank_accountno CHAR(8)      NOT NULL,               
UNIQUE (bank_sortcode, bank_accountno));


CREATE TABLE store
(store_id     INTEGER      NOT NULL DEFAULT nextval('store_id_seq') PRIMARY KEY,
store_name   VARCHAR(100) NOT NULL,
store_street VARCHAR(100) NOT NULL,
store_area   VARCHAR(100),                             
store_town   VARCHAR(50)  NOT NULL,
store_pcode  VARCHAR(10)  NOT NULL,
store_telno  VARCHAR(15));


CREATE TABLE product
(product_id          INTEGER       NOT NULL DEFAULT nextval('product_id_seq') PRIMARY KEY,
product_type        VARCHAR(50)   NOT NULL CHECK (product_type IN ('Toy', 'Computer Game')),
product_name        VARCHAR(100)  NOT NULL,
product_description VARCHAR(150),                       
product_cost        NUMERIC(8,2)  NOT NULL CHECK (product_cost > 0.00));


CREATE TABLE purchase
(purchase_id   INTEGER NOT NULL DEFAULT nextval('purchase_id_seq') PRIMARY KEY,
customer_id   INTEGER NOT NULL REFERENCES customer(customer_id),
store_id      INTEGER NOT NULL REFERENCES store(store_id),
purchase_date DATE    NOT NULL CHECK (purchase_date <= CURRENT_DATE));


CREATE TABLE purchase_line
(purchase_id INTEGER      NOT NULL REFERENCES purchase(purchase_id),
product_id  INTEGER      NOT NULL REFERENCES product(product_id),
quantity    SMALLINT     NOT NULL DEFAULT 1 CHECK (quantity >= 1),      
unit_price  NUMERIC(8,2) NOT NULL CHECK (unit_price > 0.00),
PRIMARY KEY (purchase_id, product_id));


CREATE TABLE stock
(store_id   INTEGER  NOT NULL REFERENCES store(store_id),
product_id INTEGER  NOT NULL REFERENCES product(product_id),
quantity   SMALLINT NOT NULL CHECK (quantity >= 0),                 
PRIMARY KEY (store_id, product_id));


/* Trigger function before INSERT table values to validate a customer’s age */

CREATE OR REPLACE FUNCTION check_customer_age()RETURNS TRIGGER 
LANGUAGE 'plpgsql' AS
$BODY$
BEGIN
  IF (CURRENT_DATE - NEW.customer_dob) / 365 < 18 THEN
    RAISE EXCEPTION 
      'Registration failed: Customer date of birth % gives an age below 18. 
       Must be 18 or older to register.', NEW.customer_dob;
  END IF;
  RETURN NEW;
END;
$BODY$;


CREATE OR REPLACE TRIGGER trg_customer_age
BEFORE INSERT OR UPDATE ON customer
FOR EACH ROW EXECUTE FUNCTION check_customer_age();


INSERT INTO customer (customer_forename, customer_surname, customer_street, customer_area, customer_town, customer_pcode, customer_telno, customer_email, customer_gender, customer_dob) VALUES
('James',  'Miller',    '12 High Street',    'Westminster', 'London',     'SW1A 1AA', '07700 900123', 'j.miller85@outlook.com',  'M', '1985-05-12'),
('Sarah',  'Bennett',   '45 Oak Lane',        'Didsbury',   'Manchester', 'M20 2RF',  '07700 900456', 'sarah.b92@gmail.com',      'F', '1992-11-20'),
('Robert', 'Chen',      '8 Station Road',     'Jesmond',    'Newcastle',  'NE2 3AI',  '07700 900789',  NULL,                      'M', '1978-02-03'),
('Elena',  'Rodriguez', '21 Park View',       'Clifton',    'Bristol',    'BS8 4EJ',  '07700 900011', 'elena.rod@icloud.com',     'F', '1995-08-15'),
('Chloe',  'Thompson',  '56 Victoria Street', 'Redcliffe',  'Bristol',    'BS1 6QS',  '07700 900222', 'chloe_98@yahoo.co.uk',     'F', '1998-04-04');


INSERT INTO store (store_name, store_street, store_area, store_town, store_pcode, store_telno) VALUES
('TTE Newcastle',   '100 Retail Park',  'Team Valley',  'Gateshead',   'NE11 0BE', '0191 491 0000'),
('TTE Birmingham',  '50 Broad Street',  'City Centre',  'Birmingham',  'B1 2JB',   '0121 200 1111'),
('TTE Manchester',  '42 Bridge Street', 'Deansgate',    'Manchester',  'M3 3BW',   '0161 832 2000'),
('TTE Bristol',     '15 Corn Street',   'Old City',     'Bristol', 'BS1 1HT',  '0117 925 3000'),
('TTE Glasgow',     '101 George Street','City Centre',  'Glasgow',     'G1 1QU',   '0141 552 4000');

INSERT INTO product (product_type, product_name, product_description, product_cost) VALUES
('Toy', 'Building Blocks Set', 'Classic colourful stacking blocks, suitable for ages 2+',     24.99),
('Toy', 'Remote Control Car', '1:16 scale high-speed RC car with 2.4GHz wireless controller', 49.99),
('Computer Game', 'Space Raiders', 'Sci-fi shooter adventure game, compatible with PC and console', 39.99),
('Computer Game', 'Football Manager 2026',  'Official football management simulation, season 2025/26', 44.99),
('Toy', 'Jigsaw Puzzle 1000pc', '1000-piece landscape jigsaw puzzle, for ages 10+', 14.99);


INSERT INTO bank_account (customer_id, bank_name, bank_street, bank_area, bank_town, bank_pcode, bank_telno, bank_sortcode, bank_accountno) VALUES
(1001, 'Barclays',   '1 Churchill Place',  'Canary Wharf',   'London', 'E14 5HP', '0800 001 001', '20-00-00', '12345678'),
(1002, 'HSBC',       '8 Canada Square',    'Canary Wharf',   'London', 'E14 5HQ', '0800 002 002', '40-00-00', '87654321'),
(1003, 'Lloyds',     '25 Gresham Street',  'City of London', 'London', 'EC2V 7HN','0800 003 003', '30-00-00', '45678901'),
(1004, 'Santander',  '2 Triton Square',    'Regents Place',  'London', 'NW1 3AN', '0800 004 004', '09-01-29', '99887766'),
(1005, 'NatWest',    '250 Bishopsgate',    'City of London', 'London', 'EC2M 4AA','0800 005 005', '60-00-01', '11223344');


INSERT INTO purchase (customer_id, store_id, purchase_date) VALUES
(1001, 201, '2026-05-01'),
(1002, 201, '2026-05-02'),
(1003, 202, '2026-05-05'),
(1001, 202, '2026-05-10'),
(1004, 201, '2026-05-12');


INSERT INTO purchase_line (purchase_id, product_id, quantity, unit_price) VALUES
(9001, 3001, 1,  24.99),   
(9001, 3004, 1,  44.99),   
(9002, 3002, 1,  49.99),   
(9003, 3003, 2,  39.99),   
(9004, 3005, 1,  14.99);   


INSERT INTO stock (store_id, product_id, quantity) VALUES
(201, 3001, 15),   
(201, 3002,  5),  
(202, 3003, 10),   
(203, 3004,  8),   
(204, 3005, 12);  

/* Trigger test call*/

INSERT INTO customer (customer_forename, customer_surname, customer_street, customer_area, customer_town, customer_pcode, customer_telno, customer_email, customer_gender, customer_dob) 
VALUES ('Test', 'Adult', '1 Valid Street', 'Testfield', 'London', 'EC1A 1BB', '07700900999', NULL, 'M', '1990-01-01');

INSERT INTO customer (customer_forename, customer_surname, customer_street, customer_area, customer_town, customer_pcode, customer_telno, customer_email, customer_gender, customer_dob) 
VALUES ('Test', 'Minor', '2 Invalid Street', 'Testfield', 'London', 'EC1A 1BC', '07700900888', NULL, 'F', '2015-06-15');


/* Customer purchase procedure */

CREATE OR REPLACE PROCEDURE print_customer_purchase (cust_id CUSTOMER.CUSTOMER_ID%TYPE, prod_id PRODUCT.PRODUCT_ID%TYPE, qty STOCK.QUANTITY%TYPE, str_id STORE.STORE_ID%TYPE)
LANGUAGE 'plpgsql' AS
$BODY$
DECLARE
/* defining the required parameters */
    c_stock STOCK.QUANTITY%TYPE;
    c_price PRODUCT.PRODUCT_COST%TYPE;
    c_total NUMERIC(8,2);
    c_new_purchase_id PURCHASE.PURCHASE_ID%TYPE;
BEGIN
/* details to be displayed */
    SELECT product_cost 
    INTO STRICT c_price
    FROM product
    WHERE product_id = prod_id;
   
SELECT quantity 
    INTO STRICT c_stock
    FROM stock
    WHERE store_id = str_id AND product_id = prod_id;
    
    /* apply business logic check */
	IF c_stock < qty THEN
    		RAISE EXCEPTION 'Transaction Cancelled: Stock Unavailable.';
    END IF; 
	/* calculate cost */
    c_total := c_price * qty;
	
    /* Generate unique sequential ID using sequence */
	c_new_purchase_id := nextval('purchase_id_seq');

    /* store purchase details within the database */
	INSERT INTO purchase (purchase_id, customer_id, store_id, purchase_date)
    VALUES (c_new_purchase_id, cust_id, str_id, CURRENT_DATE);

    INSERT INTO purchase_line (purchase_id, product_id, quantity, unit_price)
    VALUES (c_new_purchase_id, prod_id, qty, c_price);

    UPDATE stock
    SET quantity = quantity - qty
    WHERE store_id = str_id AND product_id = prod_id;  

    /* Report header */
	RAISE NOTICE 'Purchase completed';
    RAISE NOTICE 'Purchase ID: % | Item Price: £% | Total Amount: £%', c_new_purchase_id, c_price, c_total;

EXCEPTION
/* For returning missing records in a cleaner way */
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Transaction Failed: The Product ID or Store ID entered cannot be found.';
END;
$BODY$;

/* Test call for customer purchase procedure */

CALL print_customer_purchase(1001, 3001, CAST(2 AS SMALLINT), 201);

CALL print_customer_purchase(1001, 3001,  CAST(9999 AS SMALLINT), 201);


/* Store purchase procedure */

CREATE OR REPLACE PROCEDURE print_store_purchases (str_id STORE.STORE_ID%TYPE, st_date DATE, end_date DATE)
LANGUAGE 'plpgsql' AS
$BODY$
/* defining the required parameters */
DECLARE
    str_name        STORE.STORE_NAME%TYPE;
    str_town        STORE.STORE_TOWN%TYPE;
    purchase_total  NUMERIC(10,2) := 0;
    line_count      INT := 0;
    rec             RECORD;
BEGIN
/* details to be displayed */
    SELECT store_name, store_town
    INTO STRICT str_name, str_town /* would raise exception message if detail invalid */
    FROM store
    WHERE store_id = str_id;

   /* Report header */
   	RAISE NOTICE 'PURCHASE REPORT';
    RAISE NOTICE 'Store ID: %', str_id;
    RAISE NOTICE 'Store Name: %', str_name;
    RAISE NOTICE 'Town: %', str_town;
    RAISE NOTICE 'Period: % to %', st_date, end_date;

/* select rows for table joining, 4 tables joined, implicit cursor applied */
    FOR rec IN
        SELECT
            p.purchase_id,
            p.purchase_date,
            c.customer_id,
            c.customer_forename,
            c.customer_surname,
            pr.product_id,
            pr.product_name,
            pr.product_description,
            pl.quantity,
            pl.unit_price,
            (pl.quantity * pl.unit_price) AS line_total
        FROM purchase p
        INNER JOIN customer c      ON c.customer_id  = p.customer_id
        INNER JOIN purchase_line pl ON pl.purchase_id = p.purchase_id
        INNER JOIN product pr      ON pr.product_id  = pl.product_id
        WHERE p.store_id = str_id
          AND p.purchase_date BETWEEN st_date AND end_date
        ORDER BY p.purchase_date, p.purchase_id, pr.product_name
    LOOP
        line_count     := line_count + 1;
        purchase_total := purchase_total + rec.line_total;

        RAISE NOTICE '[Purchase #%] Date: %', rec.purchase_id, rec.purchase_date;
        RAISE NOTICE '  Customer   : % % (ID: %)', rec.customer_forename, rec.customer_surname, rec.customer_id;
        RAISE NOTICE '  Product    : % (ID: %)', rec.product_name, rec.product_id;
        RAISE NOTICE '  Description: %', rec.product_description;
        RAISE NOTICE '  Qty: %  |  Unit Price: £%  |  Line Total: £%',
                     rec.quantity, rec.unit_price, rec.line_total;
    END LOOP;
	
	/* Report summary */
    IF line_count = 0 THEN
        RAISE NOTICE 'No purchases found for store % between % and %.',
                     str_id, st_date, end_date;
    ELSE
        RAISE NOTICE '--- SUMMARY ---';
        RAISE NOTICE '  Total line items : %', line_count;
        RAISE NOTICE '  Purchase total   : £%', purchase_total;
    END IF;

EXCEPTION
/* For returning missing records in a cleaner way */
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Transaction Failed: Store ID "%" does not exist.', str_id;
END;
$BODY$;

/* store purchase test call*/

CALL print_store_purchases(201, '2026-05-01', '2026-05-31');

CALL print_store_purchases(201, '2025-01-01', '2025-01-31');

CALL print_store_purchases(999, '2026-05-01', '2026-05-31');


/* Move stock procedure */
CREATE OR REPLACE PROCEDURE print_move_stock (prod_id PRODUCT.PRODUCT_ID%TYPE, qty STOCK.QUANTITY%TYPE, source_str_id STORE.STORE_ID%TYPE, dest_str_id STORE.STORE_ID%TYPE)
LANGUAGE 'plpgsql' AS
$BODY$
DECLARE
/* defining the required parameters */
    source_stock STOCK.QUANTITY%TYPE;
    dest_stock STOCK.QUANTITY%TYPE;
BEGIN
/* details to be displayed */
    SELECT quantity 
    INTO STRICT source_stock /* would trigger exception message if product id not found in source store */
    FROM stock
    WHERE store_id = source_str_id AND product_id = prod_id;

   /* for checking insufficient stock */
   IF source_stock < qty THEN
        RAISE EXCEPTION 'Transaction Cancelled: Stock Unavailable in the source store.';
    END IF;
	
    SELECT quantity 
    INTO dest_stock /* No strict applied so that the if statement can handle both scenarios */
    FROM stock
    WHERE store_id = dest_str_id AND product_id = prod_id;

    IF FOUND THEN
        UPDATE stock
        SET quantity = quantity + qty
        WHERE store_id = dest_str_id AND product_id = prod_id;
    ELSE
        INSERT INTO stock (store_id, product_id, quantity)
        VALUES (dest_str_id, prod_id, qty);
    END IF;
	
    UPDATE stock
    SET quantity = quantity - qty
    WHERE store_id = source_str_id AND product_id = prod_id;  

    RAISE NOTICE 'Stock move completed successfully.';
    RAISE NOTICE 'Moved % units of Product ID % from Store % to Store %.', qty, prod_id, source_str_id, dest_str_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Transaction Failed: The Product ID or Source Store ID entered cannot be found.';
END;
$BODY$;

/* move stock test call*/

CALL print_move_stock(3001, CAST(5 AS SMALLINT), 201, 203);

CALL print_move_stock(3001, CAST(3 AS SMALLINT), 203, 201);

CALL print_move_stock(3001, CAST(9999 AS SMALLINT), 201, 203);