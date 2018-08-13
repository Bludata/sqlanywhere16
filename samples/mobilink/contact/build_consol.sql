-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************

-------------------------------------------------
--   Create tables
-------------------------------------------------

CREATE TABLE "DBA"."SalesRep"
(
	"rep_id"        		integer NOT NULL DEFAULT GLOBAL AUTOINCREMENT,
	"name"  			char(40) NOT NULL,
	"ml_username"   		char(40) UNIQUE NOT NULL,
	"active"        		bit NOT NULL,
	PRIMARY KEY ("rep_id")
)
go
CREATE TABLE "DBA"."Customer"
(
	"cust_id"       		integer NOT NULL DEFAULT GLOBAL AUTOINCREMENT,
	"name"  			char(40) NOT NULL,
	"rep_id"        		integer NOT NULL,
	"last_modified" 		timestamp NULL DEFAULT timestamp,
	"active"        		bit NOT NULL,
	PRIMARY KEY ("cust_id")
)
go
CREATE TABLE "DBA"."Contact"
(
	"contact_id"    		integer NOT NULL DEFAULT GLOBAL AUTOINCREMENT,
	"name"  			char(40) NULL,
	"cust_id"       		integer NULL,
	"last_modified" 		timestamp NULL DEFAULT timestamp,
	"active"        		bit NOT NULL,
	PRIMARY KEY ("contact_id")
)
go
CREATE TABLE "DBA"."Product"
(
	"id"    			integer NOT NULL,
	"name"  			char(15) NULL,
	"size"  			char(18) NULL,
	"supplier"      		char(30) NULL,
	"quantity"      		integer NULL,
	"unit_price"    		money NULL,
	"last_modified" 		timestamp NULL DEFAULT timestamp,
	"active"        		bit NOT NULL,
	PRIMARY KEY ("id")
)
go

CREATE GLOBAL TEMPORARY TABLE "DBA"."product_conflict"
(
	"id"    			integer NOT NULL,
	"size"  			char(18) NOT NULL,
	"quantity"      		integer NULL,
	"unit_price"    		money NULL,
	"row_type"      		char(1) NOT NULL,
	"name"  			varchar(30) NULL,
	PRIMARY KEY ("id", "row_type")
) ON COMMIT DELETE ROWS
go
COMMENT ON COLUMN "DBA"."product_conflict"."row_type" IS
	'O for Old or N for New'
go
commit work
go

-------------------------------------------------
--   Load data
-------------------------------------------------

INSERT INTO SALESREP( rep_id, "name", ml_username, active ) VALUES ( 195,'Marc Dill','MDill',1 )
INSERT INTO SALESREP( rep_id, "name", ml_username, active ) VALUES ( 856,'Samuel Singer','SSinger',1 )
INSERT INTO SALESREP( rep_id, "name", ml_username, active ) VALUES ( 949,'Pamela Savarino','PSavarino',1 )
INSERT INTO SALESREP( rep_id, "name", ml_username, active ) VALUES ( 1039,'Shih Lin Chao','SChao',1 )
go 
COMMIT WORK

go
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 104,'P.S.C.',1039,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 112,'McManus Inc.',856,0 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 113,'Lakes Inc.',856,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 123,'North Land Trading',949,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 126,'Golden Gate Active Wear',949,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 130,'Wyse Corp.',1039,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 135,'Hermanns',949,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 143,'Molly''s',856,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 163,'Mount Eastern Sports',856,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 165,'Moran''s Gift Shop',1039,1 )
INSERT INTO CUSTOMER ( cust_id, "name", rep_id, active ) VALUES ( 166,'Hospital Gifts',949,1 )
go
COMMIT WORK
go

INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1097,'Salton Pepper',104,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1099,'Amit Singh',104,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1100,'Helen Chau',112,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1101,'Ella Mentary',113,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1102,'Sheng Chen',123,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1103,'Maio Chermak',123,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1104,'Ling Ling Andrews',123,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1105,'Li-Hui Jyh-Hwa',123,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1106,'Jen-Chang Chin',126,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1107,'Alfred Neumann',130,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1108,'Rosanna Beldov',135,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1109,'Marta Richards',135,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1110,'Randy Arlington',143,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1111,'Herbert Berejiklian',143,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1112,'Vartan Berenberg',143,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1113,'Sebouh Bensoul',143,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1114,'Thao Tenorio',163,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1115,'Serop Belmont',163,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1116,'Anoush Serafina',165,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1117,'Marilyn Nakagama',165,1 )
INSERT INTO CONTACT ( contact_id, "name", cust_id, active ) VALUES ( 1118,'Leilani Gardner',166,1 )
go
COMMIT WORK
go

INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 300,'Tee Shirt','Small','Casual Warehouse',28,9,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 301,'Tee Shirt','Medium','Casual Warehouse',25,14,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 302,'Tee Shirt','One size fits all','Casual Warehouse',12,14,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 400,'Baseball Cap','One size fits all','Sports Wholesalers',90,9,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 401,'Baseball Cap','One size fits all','Sports Wholesalers',32,10,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 500,'Visor','One size fits all','Sports Wholesalers',49,7,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 501,'Visor','One size fits all','Sports Wholesalers',75,7,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 600,'Sweatshirt','Large','Casual Warehouse',84,24,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 601,'Sweatshirt','Large','Casual Warehouse',93,24,1 )
INSERT INTO PRODUCT ( id, "name", size, supplier, quantity, unit_price, active ) VALUES ( 700,'Shorts','Medium','Sports Wholesalers',40,15,1 )
go

commit work
go


-------------------------------------------------
--   Add foreign key definitions
-------------------------------------------------

ALTER TABLE "DBA"."Customer"
	ADD FOREIGN KEY "SalesRep" ("rep_id") 
	REFERENCES "DBA"."SalesRep" ("rep_id")
go

ALTER TABLE "DBA"."Contact"
	ADD FOREIGN KEY "Customer" ("cust_id") 
	REFERENCES "DBA"."Customer" ("cust_id")
go


-------------------------------------------------
--   Create triggers
-------------------------------------------------

CREATE TRIGGER UpdateContactForCustomer
AFTER UPDATE OF rep_id ORDER 1
ON DBA.Customer
REFERENCING OLD AS old_cust NEW as new_cust
FOR EACH ROW
BEGIN

  UPDATE Contact 
  SET Contact.last_modified = new_cust.last_modified 
  FROM Contact 
  WHERE Contact.cust_id = new_cust.cust_id

END
go

-------------------------------------------------
-- Create synchronization scripts
-------------------------------------------------

-- Upload synchronization scripts

-- SalesRep table
-- no upload allowed.

-- Customer table

call ml_add_table_script( 'default', 'Customer', 'upload_insert',
'     INSERT INTO Customer( cust_id, name, rep_id, active ) 
     VALUES ( {ml r.cust_id}, {ml r.name}, {ml r.rep_id}, 1 )' )
go
call ml_add_table_script( 'default', 'Customer', 'upload_update',
'    UPDATE Customer 
    SET name = {ml r.name}, rep_id = {ml r.rep_id}
    WHERE cust_id = {ml r.cust_id}' );
go
call ml_add_table_script( 'default', 'Customer', 'upload_delete',
'    UPDATE Customer
    SET active = 0
    WHERE cust_id = {ml r.cust_id}' 
)
go

-- Contact table

call ml_add_table_script( 'default','Contact', 'upload_insert',
'     INSERT INTO Contact (contact_id, name, cust_id, active ) 
     VALUES ( {ml r.contact_id}, {ml r.name}, {ml r.cust_id}, 1 )' )
go
call ml_add_table_script( 'default', 'Contact', 'upload_update',
'    UPDATE Contact
    SET name = {ml r.name}, cust_id = {ml r.cust_id}
    WHERE contact_id = {ml r.contact_id}' )
go
call ml_add_table_script( 'default', 'Contact', 'upload_delete',
'    UPDATE Contact
    SET active = 0
    WHERE contact_id = {ml r.contact_id}' )
go

-- Product table
-- Conflict resolution added
-- only updates allowed at remote database

call ml_add_table_script( 'default', 'Product', 'resolve_conflict',
'    UPDATE Product
    SET p.quantity = p.quantity - old_row.quantity + new_row.quantity
    FROM Product p, DBA.product_conflict old_row, DBA.product_conflict new_row
    WHERE p.id = old_row.id
    AND p.id = new_row.id
    AND old_row.row_type = ''O''
    AND new_row.row_type = ''N''' )
go
call ml_add_table_script( 'default', 'Product', 'upload_old_row_insert',
'    INSERT INTO DBA.product_conflict( id, name, size, quantity, unit_price, row_type )
    VALUES( {ml r.id}, {ml r.name}, {ml r.size}, {ml r.quantity}, {ml r.unit_price}, ''O'' )' )
go
call ml_add_table_script( 'default', 'Product', 'upload_new_row_insert',
'    INSERT INTO DBA.product_conflict( id, name, size, quantity, unit_price, row_type )
    VALUES( {ml r.id}, {ml r.name}, {ml r.size}, {ml r.quantity}, {ml r.unit_price}, ''N'' )' )
go
call ml_add_table_script( 'default', 'Product', 'upload_fetch',
'    SELECT id, name, size, quantity, unit_price 
    FROM Product
    WHERE id = {ml r.id}' );
go
call ml_add_table_script( 'default', 'Product', 'upload_update',
'    UPDATE product
    SET name = {ml r.name}, size = {ml r.size}, quantity = {ml r.quantity}, unit_price = {ml r.unit_price}
    WHERE product.id = {ml r.id}' )
go

-- Download synchronization scripts

-- SalesRep table
-- Snapshot synchronization -- only one row downloaded.

call ml_add_table_script( 'default', 'SalesRep', 'download_cursor',
    'SELECT rep_id, name 
    FROM SalesRep 
    WHERE ml_username = {ml s.username}' )
go

call ml_add_table_script( 'default', 'SalesRep', 'download_delete_cursor', '--{ml_ignore}' )
go

-- Customer table

call ml_add_table_script( 'default', 'Customer', 'download_delete_cursor',
'    SELECT cust_id
    FROM Customer JOIN SalesRep 
    ON Customer.rep_id = SalesRep.rep_id
    WHERE Customer.last_modified >= {ml s.last_table_download}
    AND ( SalesRep.ml_username != {ml s.username} OR Customer.active = 0 )' )
go
call ml_add_table_script( 'default', 'Customer', 'download_cursor',
'    SELECT cust_id, Customer.name, Customer.rep_id
    FROM Customer key JOIN SalesRep 
    WHERE Customer.last_modified >= {ml s.last_table_download}
    AND SalesRep.ml_username = {ml s.username}
    AND Customer.active = 1' )
go

-- Contact table

call ml_add_table_script( 'default', 'Contact', 'download_delete_cursor',
'    -- Contacts for reassigned customers are deleted by cascading 
    -- referential integrity, and do not need to be handled
    -- in this script.
    SELECT contact_id 
    FROM ( Contact JOIN Customer ) JOIN SalesRep 
    ON Contact.cust_id = Customer.cust_id 
        AND Customer.rep_id = SalesRep.rep_id
    WHERE Contact.last_modified >= {ml s.last_table_download} 
        AND Contact.active = 0'
)
go
call ml_add_table_script( 'default', 'Contact', 'download_cursor',
'    -- Need to download rows that are recently changed.
    -- This includes rows corresponding to customers that are 
    -- recently reassigned, thanks to the trigger on Customer.  
    SELECT Contact_id, Contact.name, Contact.cust_id 
    FROM ( Contact JOIN Customer ) JOIN SalesRep 
    ON Contact.cust_id = Customer.cust_id 
        AND Customer.rep_id = Salesrep.rep_id 
    WHERE Contact.last_modified >= {ml s.last_table_download}
        AND SalesRep.ml_username = {ml s.username}
        AND Contact.active = 1'
)
go

-- Product table

call ml_add_table_script( 'default', 'Product', 'download_delete_cursor',
'    SELECT id, name, size, quantity, unit_price
    FROM product 
    WHERE last_modified >= {ml s.last_table_download}
    AND active = 0' )
go
call ml_add_table_script( 'default', 'Product', 'download_cursor',
'    SELECT id, name, size, quantity, unit_price
    FROM product 
    WHERE last_modified >= {ml s.last_table_download}
    AND active = 1' )
go

-- Column names

call ml_add_column( 'default', 'SalesRep', 'rep_id' , NULL )
go
call ml_add_column( 'default', 'SalesRep', 'name' , NULL )
go
call ml_add_column( 'default', 'SalesRep', 'ml_username' , NULL )
go
call ml_add_column( 'default', 'SalesRep', 'active' , NULL )
go

call ml_add_column( 'default', 'Customer', 'cust_id' , NULL )
go
call ml_add_column( 'default', 'Customer', 'name' , NULL )
go
call ml_add_column( 'default', 'Customer', 'rep_id' , NULL )
go
call ml_add_column( 'default', 'Customer', 'last_modified' , NULL )
go
call ml_add_column( 'default', 'Customer', 'active' , NULL )
go

call ml_add_column( 'default', 'Contact', 'contact_id' , NULL )
go
call ml_add_column( 'default', 'Contact', 'name' , NULL )
go
call ml_add_column( 'default', 'Contact', 'cust_id' , NULL )
go
call ml_add_column( 'default', 'Contact', 'last_modified' , NULL )
go
call ml_add_column( 'default', 'Contact', 'active' , NULL )
go

call ml_add_column( 'default', 'Product', 'id' , NULL )
go
call ml_add_column( 'default', 'Product', 'name' , NULL )
go
call ml_add_column( 'default', 'Product', 'size' , NULL )
go
call ml_add_column( 'default', 'Product', 'quantity' , NULL )
go
call ml_add_column( 'default', 'Product', 'unit_price' , NULL )
go

-------------------------------------------------
--   Set option values
-------------------------------------------------
SET OPTION "PUBLIC"."Ansi_update_constraints" = 'OFF'
go

