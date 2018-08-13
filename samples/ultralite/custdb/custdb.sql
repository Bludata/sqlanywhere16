-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- You may use, reproduce, modify and distribute this sample code without limitation, 
-- on the condition that you retain the foregoing copyright notice and disclaimer as to the original code.  
--
-- *******************************************************************


--
-- custdb.sql - setup for UltraLite example for SA
--

create table ULCustomer (
    cust_id		integer	not null primary key,
    cust_name		varchar(30),
    last_modified	timestamp default timestamp
)
go
create unique index ULCustomerName on ULCustomer (cust_name)
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULCustomer', NULL, NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULCustomer', 'cust_id', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULCustomer', 'cust_name', NULL
go

create table ULProduct (
    prod_id		integer not null primary key, 
    price		integer,
    prod_name		varchar(30)
)
go
create index ULProductName on ULProduct (prod_name)
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULProduct', NULL, NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULProduct', 'prod_id', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULProduct', 'price', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULProduct', 'prod_name', NULL
go

create table ULEmployee (
    emp_id		integer	not null primary key,
    emp_name		varchar(30),
)
go
create index ULEmployeeName on ULEmployee (emp_name)
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULEmployee', NULL, NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULEmployee', 'emp_id', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULEmployee', 'emp_name', NULL
go

create table ULIdentifyEmployee_nosync (
    emp_id		integer	not null primary key
)
go

create table ULOrder (
    order_id		integer	not null primary key,
    cust_id		integer	not null,	
    prod_id		integer	not null,
    emp_id		integer	not null,
    disc		integer,
    quant		integer not null,
    notes		varchar(50),
    status		varchar(20),
    last_modified	timestamp default timestamp, 
    foreign key (cust_id) references ULCustomer (cust_id),
    foreign key (prod_id) references ULProduct (prod_id),
    foreign key (emp_id) references ULEmployee (emp_id)
)
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', NULL, NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', 'order_id', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', 'cust_id', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', 'prod_id', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', 'emp_id', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', 'disc', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', 'quant', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', 'notes', NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrder', 'status', NULL
go


--  ULEmpCust controls which customer's orders will be downloaded.
--  If the employee needs a new customer's orders, inserting the
--  employee id and customer id, will force the orders for that
--  customer to be downloaded.
--  If the employee no longer requires a customer's orders, the
--  action must be set to 'D' (delete).  A logical delete must be
--  used in this case so that the consolidated can identify which
--  rows to remove from the ULOrder table.  Once the deletes have
--  been downloaded, all records for that employee with an action
--  of 'D' can also be removed from the consolidated database.

create table ULEmpCust (
	emp_id    	  integer not null,
	cust_id 	  integer not null,
	action	 	  char(1) null,
	last_modified     timestamp default timestamp,
	PRIMARY KEY (emp_id, cust_id),
	foreign key (cust_id) references ULCustomer (cust_id),	
	foreign key (emp_id) references ULEmployee (emp_id)
)
go

create trigger ULSubscribeOrder
    after insert, update on ULOrder
    referencing new as o
    for each row
begin
    -- Make sure the employee that entered this order is downloading
    -- information for this customer.
    if not exists( select * from ULEmpCust ec 
		    where o.emp_id = ec.emp_id
		      and o.cust_id = ec.cust_id ) then
	-- Add a row to ULEmpCust
	insert into ULEmpCust (emp_id,cust_id) values (o.emp_id, o.cust_id);
    end if;
end
go

-- Utility Tables
create table ULCustomerIDPool (
    pool_cust_id	integer not null default autoincrement,
    pool_emp_id		integer not null,
    last_modified	timestamp default timestamp, 
    primary key (pool_cust_id),
    foreign key (pool_emp_id) references ULEmployee (emp_id)
)
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULCustomerIDPool', NULL, NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULCustomerIDPool', 'pool_cust_id', NULL
go

create table ULOrderIDPool (
    pool_order_id	integer not null default autoincrement,
    pool_emp_id		integer not null,
    last_modified	timestamp default timestamp, 
    primary key (pool_order_id),
    foreign key (pool_emp_id) references ULEmployee (emp_id)
)
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrderIDPool', NULL, NULL
go
exec ml_server.ml_add_column 'custdb 16.0', 'ULOrderIDPool', 'pool_order_id', NULL
go
CREATE PROCEDURE ULResetData()
BEGIN
    -- Delete existing data
    TRUNCATE TABLE ULCustomerIDPool;
    TRUNCATE TABLE ULOrderIDPool;
    TRUNCATE TABLE ULEmpCust;
    TRUNCATE TABLE ULOrder;
    TRUNCATE TABLE ULProduct;
    TRUNCATE TABLE ULCustomer;
    TRUNCATE TABLE ULEmployee;
    TRUNCATE TABLE ULIdentifyEmployee_nosync;
    -- ULEmployee table
    INSERT INTO ULEmployee (emp_id, emp_name) VALUES ( 50, 'Alan Able'  );
    INSERT INTO ULEmployee (emp_id, emp_name) VALUES ( 51, 'Betty Best' );
    INSERT INTO ULEmployee (emp_id, emp_name) VALUES ( 52, 'Chris Cash' );
    INSERT INTO ULEmployee (emp_id, emp_name) VALUES ( 53, 'Mindy Manager' );
    -- ULCustomer table
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2000, 'Apple St. Builders'     );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2001, 'Art''s Renovations'     );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2002, 'Awnings R Us'           );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2003, 'Al''s Interior Design'  );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2004, 'Alpha Hardware'         );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2005, 'Ace Properties'         );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2006, 'A1 Contracting'         );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2007, 'Archibald Inc.'         );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2008, 'Acme Construction'      );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2009, 'ABCXYZ Inc.'            );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2010, 'Buy It Co.'             );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2011, 'Bill''s Cages'          );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2012, 'Build-It Co.'           );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2013, 'Bass Interiors'         );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2014, 'Burger Franchise'       );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2015, 'Big City Builders'      );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2016, 'Bob''s Renovations'     );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2017, 'Basements R Us'         );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2018, 'BB Interior Design'     );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2019, 'Bond Hardware'          );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2020, 'Cat Properties'         );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2021, 'C & C Contracting'      );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2022, 'Classy Inc.'            );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2023, 'Cooper Construction'    );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2024, 'City Schools'           );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2025, 'Can Do It Co.'          );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2026, 'City Corrections'       );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2027, 'City Sports Arenas'     );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2028, 'Cantelope Interiors'    );
    INSERT INTO ULCustomer (cust_id, cust_name) VALUES ( 2029, 'Chicken Franchise'      );
    -- ULProduct table
    INSERT INTO ULProduct VALUES ( 1,  400,  '4x8 Drywall x100'        );
    INSERT INTO ULProduct VALUES ( 2,  3000, '8'' 2x4 Studs x1000'     );
    INSERT INTO ULProduct VALUES ( 3,  40,   'Drywall Screws 10lb'     );
    INSERT INTO ULProduct VALUES ( 4,  75,   'Joint Compound 100lb'    );
    INSERT INTO ULProduct VALUES ( 5,  100,  'Joint Tape x25x500'      );
    INSERT INTO ULProduct VALUES ( 6,  400,  'Putty Knife x25'         );
    INSERT INTO ULProduct VALUES ( 7,  3000, '8'' 2x10 Supports x 200' );
    INSERT INTO ULProduct VALUES ( 8,  75,   '400 Grit Sandpaper'      );
    INSERT INTO ULProduct VALUES ( 9,  40,   'Screwmaster Drill'       );
    INSERT INTO ULProduct VALUES ( 10, 100,  '200 Grit Sandpaper'      );
    -- ULOrder table
    -- Alan Able
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5100, 2000, 1,  50, 20, 25000 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5101, 2001, 2,  50, 10, 40 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5102, 2002, 4,  50, 10, 700 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5103, 2003, 3,  50, 5,  15 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5104, 2004, 5,  50, 20, 5000 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5105, 2005, 2,  50, 15, 75 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5106, 2006, 3,  50, 5,  40 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5107, 2007, 5,  50, 10, 48 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5108, 2008, 1,  50, 20, 6000 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5109, 2009, 4,  50, 5,  36 );
    -- Betty Best
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5110, 2010, 1,  51, 10, 200 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5111, 2011, 1,  51, 10, 300 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5112, 2012, 4,  51, 5,  30 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5113, 2013, 3,  51, 8,  10 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5114, 2014, 1,  51, 15, 600 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5200, 2015, 6,  51, 20, 25000 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5201, 2016, 7,  51, 10, 40 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5202, 2017, 8,  51, 10, 700 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5203, 2018, 9,  51, 5,  15 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5204, 2019, 10, 51, 20, 5000 );
    -- Chris Cash
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5205, 2020, 7,  52, 15, 75 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5206, 2021, 9,  52, 5,  40 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5207, 2022, 10, 52, 10, 48 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5208, 2023, 6,  52, 20, 6000 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5209, 2024, 8,  52, 5,  36 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5210, 2025, 6,  52, 10, 200 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5211, 2026, 6,  52, 10, 300 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5212, 2027, 8,  52, 5,  30 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5213, 2028, 9,  52, 8,  10 );
    INSERT INTO ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant)
	VALUES ( 5214, 2029, 6,  52, 15, 600 );

    -- ULEmptCust table
    -- Add 2 customers for Mindy Manager
    INSERT INTO ULEmpCust (emp_id, cust_id) VALUES ( 53, 2000 );
    INSERT INTO ULEmpCust (emp_id, cust_id) VALUES ( 53, 2001 );

    -- Seed values so auto-increment values will start above
    -- the pre-inserted rows.
    INSERT INTO ULCustomerIDPool (pool_cust_id, pool_emp_id) VALUES( 10000, 50 );
    INSERT INTO ULOrderIDPool (pool_order_id, pool_emp_id) VALUES( 10000, 50 );
    INSERT INTO ULCustomerIDPool (pool_cust_id, pool_emp_id) VALUES( 20000, 51 );
    INSERT INTO ULOrderIDPool (pool_order_id, pool_emp_id) VALUES( 20000, 51 );
    INSERT INTO ULCustomerIDPool (pool_cust_id, pool_emp_id) VALUES( 30000, 52 );
    INSERT INTO ULOrderIDPool (pool_order_id, pool_emp_id) VALUES( 30000, 52 );
    INSERT INTO ULCustomerIDPool (pool_cust_id, pool_emp_id) VALUES( 40000, 53 );
    INSERT INTO ULOrderIDPool (pool_order_id, pool_emp_id) VALUES( 40000, 53 );
    -- Commit all of the data.
    COMMIT;
END
go

call ULResetData()
go
CREATE PROCEDURE ULOrderDownload ( 
		IN LastDownload	    timestamp,
		IN EmployeeID	    integer )
BEGIN
  SELECT o.order_id, o.cust_id, o.prod_id, o.emp_id, o.disc, o.quant, o.notes, o.status
    FROM ULOrder o, ULEmpCust ec 
   WHERE o.cust_id = ec.cust_id 
     AND ec.emp_id = EmployeeID
     AND ( o.last_modified >= LastDownload OR ec.last_modified >= LastDownload)
     AND ( o.status IS NULL  OR  o.status != 'Approved' )
     AND ( ec.action IS NULL )
END
go
CREATE PROCEDURE ULCustomerIDPool_maintain ( IN syncuser_id INTEGER )
BEGIN
    DECLARE pool_count INTEGER;
    
    -- Determine how many ids to add to the pool
    SELECT COUNT(*) INTO pool_count
	    FROM ULCustomerIDPool WHERE pool_emp_id = syncuser_id;
	    
    -- Top up the pool with new ids
    WHILE pool_count < 20 LOOP
	INSERT INTO ULCustomerIDPool ( pool_emp_id ) VALUES ( syncuser_id );
	SET pool_count = pool_count + 1;
    END LOOP;
END
go

CREATE PROCEDURE ULOrderIDPool_maintain ( IN syncuser_id INTEGER )
BEGIN
    DECLARE pool_count INTEGER;
    
    -- Determine how many ids to add to the pool
    SELECT COUNT(*) INTO pool_count
	    FROM ULOrderIDPool WHERE pool_emp_id = syncuser_id;
	    
    -- Top up the pool with new ids
    WHILE pool_count < 20 LOOP
	INSERT INTO ULOrderIDPool ( pool_emp_id ) VALUES ( syncuser_id );
	SET pool_count = pool_count + 1;
    END LOOP;
END
go

create publication custdb_tables (
    table ULCustomer (cust_id, cust_name),
    table ULProduct (prod_id, price, prod_name),
    table ULOrder (order_id, cust_id, prod_id, emp_id, disc, quant, notes, status),
    table ULCustomerIDPool (pool_cust_id),
    table ULOrderIDPool (pool_order_id),
    table ULIdentifyEmployee_nosync ( emp_id )
)
go

-------------------------------------------------------------------------
-- Synchronization
-------------------------------------------------------------------------

create global temporary table ULOldOrder (
    order_id		integer	not null primary key,
    cust_id		integer	not null,	
    prod_id		integer	not null,
    emp_id		integer	not null,
    disc		integer,
    quant		integer not null,
    notes		varchar(50),
    status		varchar(20)
)
go
create global temporary table ULNewOrder (
    order_id		integer	not null primary key,
    cust_id		integer	not null,	
    prod_id		integer	not null,
    emp_id		integer	not null,
    disc		integer,
    quant		integer not null,
    notes		varchar(50),
    status		varchar(20)
)
go
CREATE PROCEDURE ULHandleError(
    INOUT   action	    integer,
    IN	    error_code	    integer,
    IN	    error_message   varchar(1000),
    IN	    user_name	    varchar(128),
    IN	    table_name	    varchar(128) )
BEGIN
    -- -196 is SQLE_INDEX_NOT_UNIQUE
    -- -194 is SQLE_INVALID_FOREIGN_KEY
    if error_code = -196 or error_code = -194 then
	-- ignore the error and keep going
	SET action = 1000;
    else
	-- abort the synchronization
	SET action = 3000;
    end if;
END
go

call ml_server.ml_add_connection_script( 'custdb 16.0', 'handle_error',
'CALL ULHandleError( {ml s.action_code}, {ml s.error_code}, {ml s.error_message}, {ml s.remote_id}, {ml s.username} )' )
go
call ml_server.ml_add_connection_script( 'custdb 16.0', 'end_download',
'delete from ULEmpCust 
    where
      emp_id = {ml s.username} 
      and action = ''D''  ' )
go

-- ULCustomer 
--  Allow new customers to be uploaded.
--  Download all customers modified since the last download.
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomer', 'upload_insert',
'INSERT INTO ULCustomer( cust_id, cust_name ) VALUES( {ml r.cust_id, r.cust_name } )' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomer', 'upload_update',
'UPDATE ULCustomer SET cust_name = {ml r.cust_name} WHERE cust_id = {ml r.cust_id}' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomer', 'upload_delete',
'DELETE FROM ULCustomer WHERE cust_id = {ml r.cust_id}' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomer', 'download_cursor',
'SELECT cust_id, cust_name FROM ULCustomer WHERE last_modified >= {ml s.last_table_download} ' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomer', 'download_delete_cursor',
'--{ml_ignore}' )
go
	
-- ULProduct 
--  Do not need upload scripts, because products cannot be added remotely.
--  Download all products.

call ml_server.ml_add_table_script( 'custdb 16.0', 'ULProduct', 'download_cursor',
'SELECT prod_id, price, prod_name FROM ULProduct' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULProduct', 'download_delete_cursor',
'--{ml_ignore}' )
go

-- ULOrder 
--  Allow new orders or updated orders.
--  Remove any orders that have been approved.
--  Download updated orders whose status is not approved.
--  Remove any orders if the employee no longer requires
--    that customer (ULEmpCust with an action of 'D')

call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'upload_insert',
'INSERT INTO ULOrder ( order_id, cust_id, prod_id, emp_id, disc, quant, notes, status )
   VALUES( {ml r.order_id, r.cust_id, r.prod_id, r.emp_id, r.disc, r.quant, r.notes, r.status } )' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'upload_update',
'UPDATE ULOrder SET cust_id = {ml r.cust_id}, prod_id = {ml r.prod_id}, emp_id = {ml r.emp_id}, disc = {ml r.disc}, quant = {ml r.quant}, notes = {ml r.notes}, status = {ml r.status}
   WHERE order_id = {ml r.order_id}' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'upload_delete',
'DELETE FROM ULOrder WHERE order_id = {ml r.order_id}' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'upload_fetch',
'SELECT order_id, cust_id, prod_id, emp_id, disc, quant, notes, status
   FROM ULOrder WHERE order_id = {ml r.order_id}' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'upload_old_row_insert',
'INSERT INTO ULOldOrder ( order_id, cust_id, prod_id, emp_id, disc, quant, notes, status )
   VALUES( {ml r.order_id, r.cust_id, r.prod_id, r.emp_id, r.disc, r.quant, r.notes, r.status } )' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'upload_new_row_insert',
'INSERT INTO ULNewOrder ( order_id, cust_id, prod_id, emp_id, disc, quant, notes, status )
   VALUES( {ml r.order_id, r.cust_id, r.prod_id, r.emp_id, r.disc, r.quant, r.notes, r.status } )' )
go
CREATE PROCEDURE ULResolveOrderConflict()
BEGIN
    -- approval overrides denial
    IF 'Approved' = (SELECT status FROM ULNewOrder) THEN
	UPDATE ULOrder o SET o.status = n.status, o.notes = n.notes
		FROM ULNewOrder n WHERE o.order_id = n.order_id;
    END IF;
    DELETE FROM ULOldOrder;
    DELETE FROM ULNewOrder; 
END
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'resolve_conflict',
'CALL ULResolveOrderConflict')
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'download_delete_cursor',
'SELECT o.order_id
   FROM ULOrder o, dba.ULEmpCust ec
  WHERE o.cust_id = ec.cust_id 
    AND ( ( o.status = ''Approved'' AND o.last_modified >= {ml s.last_table_download} ) 
	   OR ( ec.action = ''D''  )  )
    AND ec.emp_id = {ml s.username}
' )
go
    
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrder', 'download_cursor',
'CALL ULOrderDownload( {ml s.last_table_download}, {ml s.username} )' )
go
	
-- ULCustomerIDPool 
--  Maintain a pool of customer ids for adding new customers.

call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomerIDPool', 'begin_download',
'CALL ULCustomerIDPool_maintain( {ml s.username} )' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomerIDPool', 'download_cursor',
'SELECT pool_cust_id FROM ULCustomerIDPool 
  WHERE last_modified >= {ml s.last_table_download}
    AND pool_emp_id = {ml s.username} ' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomerIDPool', 'upload_delete',
'DELETE FROM ULCustomerIDPool WHERE pool_cust_id = {ml r.pool_cust_id}' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULCustomerIDPool', 'download_delete_cursor',
'--{ml_ignore}' )
go
	
-- ULOrderIDPool 
--  Maintain a pool of order ids for adding new orders.

call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrderIDPool', 'begin_download',
'CALL ULOrderIDPool_maintain( {ml s.username} )' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrderIDPool', 'download_cursor',
'SELECT pool_order_id FROM ULOrderIDPool 
  WHERE last_modified >= {ml s.last_table_download}
    AND pool_emp_id = {ml s.username} ' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrderIDPool', 'upload_delete',
'DELETE FROM ULOrderIDPool WHERE pool_order_id = {ml r.pool_order_id}' )
go
call ml_server.ml_add_table_script( 'custdb 16.0', 'ULOrderIDPool', 'download_delete_cursor',
'--{ml_ignore}' )
go

-- Add users
call ml_server.ml_add_user( '50', NULL, NULL )
go
call ml_server.ml_add_user( '51', NULL, NULL )
go
call ml_server.ml_add_user( '52', NULL, NULL )
go
call ml_server.ml_add_user( '53', NULL, NULL )
go

