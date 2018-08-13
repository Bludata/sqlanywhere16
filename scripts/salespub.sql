// Add a region column to SalesOrderItems so the
// table can be partitioned by region.

ALTER TABLE SalesOrderItems ADD Region CHAR(7);

// Set new region column for existing SalesOrderss.

UPDATE SalesOrderItems 
    SET Region = ( SELECT Region FROM SalesOrders
		   WHERE SalesOrderItems.ID = SalesOrders.ID );

// Create triggers to automatically maintain the new region column
// so that applications do not need to be aware of it.
  
CREATE TRIGGER set_order_item_region BEFORE INSERT 
    ON SalesOrderItems
    REFERENCING NEW AS new_item
    FOR EACH ROW
    BEGIN
      SET new_item.Region = ( SELECT Region FROM SalesOrders
	WHERE SalesOrders.ID = new_item.ID )
    END;

CREATE TRIGGER update_order_items_region AFTER UPDATE OF Region
    ON SalesOrders
    REFERENCING NEW AS new_order
    FOR EACH ROW
    BEGIN
      UPDATE SalesOrderItems SET Region=new_order.Region
	WHERE SalesOrderItems.ID=new_order.ID
    END;
    
// Add a default value for FinancialCode column because the FinancialCodes
// table is not included in the publication.

ALTER TABLE SalesOrders MODIFY FinancialCode DEFAULT 'r1';

// Create a publication that includes 5 tables:
//   - the complete customer and products tables
//   - SalesOrders and SalesOrderItems subscribed by region 
//   - selected columns from the employees table

CREATE PUBLICATION Sales(
    TABLE Customers,
    TABLE Products,
    TABLE SalesOrders SUBSCRIBE BY Region,
    TABLE SalesOrderItems SUBSCRIBE BY Region,
    TABLE Employees(EmployeeID,GivenName,Surname,DepartmentID) 
      WHERE DepartmentID=200);
    
// Set up user IDs for replication.
  
CREATE REMOTE TYPE FILE ADDRESS 'COMPANY';
GRANT PUBLISH TO "dba";
GRANT CONNECT TO east IDENTIFIED BY east;
GRANT REMOTE TO east TYPE FILE ADDRESS 'east';

// Create a subscription for the eastern sales office.

CREATE SUBSCRIPTION TO Sales('Eastern') FOR east;
