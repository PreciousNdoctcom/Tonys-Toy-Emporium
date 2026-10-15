1. Trigger: trg_customer_age (function check_customer_age())

What it does: fires before every INSERT or UPDATE on customer. It raises an exception if the date of birth gives an age under 18, so underage customers can’t be registered.

Example:
sql
  -- Accepted (born 1990)
  INSERT INTO customer (customer_forename, customer_surname, customer_street, customer_area,
    customer_town, customer_pcode, customer_telno, customer_email, customer_gender, customer_dob)
  VALUES ('Test', 'Adult', '1 Valid Street', 'Testfield', 'London', 'EC1A 1BB', '07700900999', NULL, 'M', '1990-01-01');

  -- Rejected: "Registration failed... Must be 18 or older to register."
  INSERT INTO customer (customer_forename, customer_surname, customer_street, customer_area,
    customer_town, customer_pcode, customer_telno, customer_email, customer_gender, customer_dob)
  VALUES ('Test', 'Minor', '2 Invalid Street', 'Testfield', 'London', 'EC1A 1BC', '07700900888', NULL, 'F', '2015-06-15');

2. Procedure: print_customer_purchase(cust_id, prod_id, qty, str_id)

What it does: looks up the product price and the store’s stock, cancels with an exception if stock is too low, then creates a purchase row and a purchase_line row and reduces the store’s stock. It prints the purchase ID, item price and total.

Example:
sql
  CALL print_customer_purchase(1001, 3001, CAST(2 AS SMALLINT), 201);     -- succeeds
  CALL print_customer_purchase(1001, 3001, CAST(9999 AS SMALLINT), 201);  -- "Stock Unavailable"

  -- Verify the stock reduction
  SELECT * FROM stock WHERE store_id = 201 AND product_id = 3001;

3. Procedure: print_store_purchases(str_id, st_date, end_date)

What it does: prints a sales report for one store over a date range, joining four tables (purchase, customer, purchase_line, product). It lists each line with its customer, product and line total, then a summary with the line count and total. It handles a store ID that doesn’t exist.

Example:
sql
  CALL print_store_purchases(201, '2026-05-01', '2026-05-31');  -- report (use dates that match your seed data)
  CALL print_store_purchases(201, '2025-01-01', '2025-01-31');  -- "No purchases found"
  CALL print_store_purchases(999, '2026-05-01', '2026-05-31');  -- "Store ID does not exist"

Output appears in the Messages tab in pgAdmin, because it uses RAISE NOTICE.

4. Procedure: print_move_stock(prod_id, qty, source_str_id, dest_str_id)

What it does: moves stock between two stores. It checks the source store has enough, adds to the destination (or creates a stock row if that store doesn’t stock the product yet), and subtracts from the source.

Example:
sql
  CALL print_move_stock(3001, CAST(5 AS SMALLINT), 201, 203);     -- succeeds
  CALL print_move_stock(3001, CAST(9999 AS SMALLINT), 201, 203);  -- "Stock Unavailable in the source store"

  -- Verify both stores
  SELECT * FROM stock WHERE product_id = 3001 AND store_id IN (201, 203);
Limitations to be upfront about

Known limitations:

The age check divides days by 365, so it’s approximate across leap years. Someone a few days short of 18 could pass. 
AGE(CURRENT_DATE, NEW.customer_dob) < INTERVAL '18 years' is exact.
print_move_stock doesn’t check that the quantity is positive or that the source and destination stores differ.
The purchase procedure handles one product per call, so it’s one purchase line per purchase.
The stock rule is a CHECK (quantity >= 0) constraint, not a trigger. The only trigger in the project is the age check.
