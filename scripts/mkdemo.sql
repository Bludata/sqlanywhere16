//
//  This SQL file creates the demonstration database.
//

SET TEMPORARY OPTION Command_Delimiter=';'
GO

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Create users, roles, user-extended roles and
//   grant roles to users
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CREATE USER "GROUPO";
CREATE ROLE FOR USER "GROUPO";
CREATE ROLE "READ_ROLE";
CREATE ROLE "MODIFY_ROLE";
CREATE ROLE "EXEC_ROLE";

COMMENT ON USER "GROUPO" IS 
    'GROUPO is the owner of the tables created for the sporting goods company. This role allows table references without owner qualification.';
COMMENT ON ROLE "READ_ROLE" IS 
    'Users with role READ_ROLE have read access to the tables. Users with this role can perform SELECTs on all the tables.';
COMMENT ON ROLE "MODIFY_ROLE" IS 
    'Users with role MODIFY_ROLE have write access to the tables. Users with the role can perform INSERTs, UPDATEs, and DELETEs on all the tables.';
COMMENT ON ROLE "EXEC_ROLE" IS 
    'Users with role EXEC_ROLE can execute most demo procedures.';

-- CREATE USER "DBA" IDENTIFIED BY "sql";
COMMENT ON USER "DBA" IS 'the database administrator. The DBA can alter schema.';
GRANT ROLE "GROUPO" TO "DBA";

CREATE USER "BROWSER" IDENTIFIED BY "browse";
COMMENT ON USER "BROWSER" IS 'has read-only access to the tables and can run most demo procedures.'
GRANT ROLE "GROUPO" TO "BROWSER";
GRANT ROLE "READ_ROLE" TO "BROWSER";
GRANT ROLE "EXEC_ROLE" TO "BROWSER";
    
CREATE USER "UPDATER" IDENTIFIED BY "update";
COMMENT ON USER "UPDATER" IS 'has read-write access to the tables and can run all the demo procedures.'
GRANT ROLE "GROUPO" TO "UPDATER";
GRANT ROLE "READ_ROLE" TO "UPDATER";
GRANT ROLE "MODIFY_ROLE" TO "UPDATER";
GRANT ROLE "EXEC_ROLE" TO "UPDATER";

commit work;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Create the domains that we will use
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CREATE DOMAIN company_name_t CHAR( 32 );
CREATE DOMAIN person_name_t CHAR( 20 );
CREATE DOMAIN person_title_t VARCHAR( 34 );
CREATE DOMAIN street_t CHAR( 30 );
CREATE DOMAIN city_t CHAR( 20 );
CREATE DOMAIN state_t CHAR( 16 );
CREATE DOMAIN country_t CHAR( 16 );
CREATE DOMAIN postal_code_t CHAR( 10 );
CREATE DOMAIN phone_number_t CHAR( 13 );

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Create tables and grant privileges
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CREATE TABLE GROUPO.Customers
(
        ID                    integer NOT NULL default autoincrement,
        Surname               person_name_t NOT NULL,
        GivenName             person_name_t NOT NULL,
        Street                street_t NOT NULL,
        City                  city_t NOT NULL,
        State                 state_t NULL,
        Country               country_t NULL,
        PostalCode            postal_code_t NULL,
        Phone                 phone_number_t NOT NULL,
        CompanyName           company_name_t NULL,
        CONSTRAINT CustomersKey PRIMARY KEY (ID)
);

GRANT SELECT ON GROUPO.Customers TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.Customers TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.Customers IS 'customers of the sporting goods company';

CREATE TABLE GROUPO.Contacts
(
        ID                    integer NOT NULL,
        Surname               person_name_t NOT NULL,
        GivenName             person_name_t NOT NULL,
        Title                 person_title_t NULL,
        Street                street_t NULL,
        City                  city_t NULL,
        State                 state_t NULL,
        Country               country_t NULL,
        PostalCode            postal_code_t NULL,
        Phone                 phone_number_t NULL,
        Fax                   phone_number_t NULL,
	CustomerID            integer NULL default NULL,
        CONSTRAINT ContactsKey PRIMARY KEY (ID)
);

GRANT SELECT ON GROUPO.Contacts TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.Contacts TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.Contacts IS 'names, addresses and telephone numbers of all people with whom the company wishes to retain contact information';

CREATE TABLE GROUPO.SalesOrders
(
        ID                    integer NOT NULL default autoincrement,
        CustomerID            integer NOT NULL,
        OrderDate             date NOT NULL,
        FinancialCode         char(2) NULL,
        Region                char(7) NULL,
        SalesRepresentative   integer NOT NULL,
        CONSTRAINT SalesOrdersKey PRIMARY KEY (ID)
);

GRANT SELECT ON GROUPO.SalesOrders TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.SalesOrders TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.SalesOrders IS 'sales orders that customers have submitted to the sporting goods company';

CREATE TABLE GROUPO.SalesOrderItems
(
        ID                    integer NOT NULL,
        LineID                smallint NOT NULL,
        ProductID             integer NOT NULL,
        Quantity              integer NOT NULL,
        ShipDate              date NOT NULL,
        CONSTRAINT SalesOrderItemsKey PRIMARY KEY (ID, LineID)
);

GRANT SELECT ON GROUPO.SalesOrderItems TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.SalesOrderItems TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.SalesOrderItems IS 'individual items that make up the sales orders';

CREATE TABLE GROUPO.Products
(
        ID                    integer NOT NULL,
        Name                  char(15) NOT NULL,
        Description           char(30) NOT NULL,
        Size                  char(18) NOT NULL,
        Color                 char(18) NOT NULL,
        Quantity              integer NOT NULL,
        UnitPrice             numeric(15,2) NOT NULL,
        Photo                 image NULL,
        CONSTRAINT ProductsKey PRIMARY KEY (ID)
);

GRANT SELECT ON GROUPO.Products TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.Products TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.Products IS 'products sold by the sporting goods company';

CREATE TABLE GROUPO.FinancialCodes
(
        Code                  char(2) NOT NULL,
        Type                  char(10) NOT NULL,
        Description           char(50) NULL,
        CONSTRAINT FinancialCodesKey PRIMARY KEY (Code)
);

GRANT SELECT ON GROUPO.FinancialCodes TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.FinancialCodes TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.FinancialCodes IS 'types of revenue and expenses that the sporting goods company has';

CREATE TABLE GROUPO.FinancialData
(
        Year                  char(4) NOT NULL,
        Quarter               char(2) NOT NULL,
        Code                  char(2) NOT NULL,
        Amount                numeric(9,0) NULL,
        CONSTRAINT FinancialDataKey PRIMARY KEY (Year, Quarter, Code)
);

GRANT SELECT ON GROUPO.FinancialData TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.FinancialData TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.FinancialData IS 'revenues and expenses of the sporting goods company';

CREATE TABLE GROUPO.Departments
(
        DepartmentID          integer NOT NULL,
        DepartmentName        char(40) NOT NULL,
        DepartmentHeadID      integer NULL,
	CONSTRAINT DepartmentRange CHECK (DepartmentID > 0 AND DepartmentID <= 999),
        CONSTRAINT DepartmentsKey PRIMARY KEY (DepartmentID)
);

GRANT SELECT ON GROUPO.Departments TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.Departments TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.Departments IS 'contains the names and heads of the various departments in the sporting goods company';

CREATE TABLE GROUPO.Employees
(
        EmployeeID            integer NOT NULL,
        ManagerID             integer NULL,
        Surname               person_name_t NOT NULL,
        GivenName             person_name_t NOT NULL,
        DepartmentID          integer NOT NULL,
        Street                street_t NOT NULL,
        City                  city_t NOT NULL,
        State                 state_t NULL,
        Country               country_t NULL,
        PostalCode            postal_code_t NULL,
        Phone                 phone_number_t NULL,
        Status                char(2) NULL,
        SocialSecurityNumber  char(11) NULL CONSTRAINT SSN UNIQUE,
        Salary                numeric(20,3) NOT NULL,
        StartDate             date NOT NULL,
        TerminationDate       date NULL,
        BirthDate             date NULL,
        BenefitHealthInsurance bit NULL,
        BenefitLifeInsurance  bit NULL,
        BenefitDayCare        bit NULL,
        Sex                   char(2) NULL CONSTRAINT Sexes CHECK (Sex in ('F','M','NA')),
        CONSTRAINT EmployeesKey PRIMARY KEY (EmployeeID)
);

GRANT SELECT ON GROUPO.Employees TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.Employees TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.Employees IS 'contains information such as names, addresses, salary, hire date, and birthdays of the employees of the sporting goods company';

CREATE TABLE GROUPO.MarketingInformation 
(
	ID			integer NOT NULL,
	ProductID		integer NOT NULL,
	Description	        long varchar NULL,
	CONSTRAINT MarketingKey PRIMARY KEY (ID)
);

GRANT SELECT ON GROUPO.MarketingInformation TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.MarketingInformation TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.MarketingInformation IS 'contains marketing information for the sporting goods company';

CREATE TABLE GROUPO.SpatialContacts 
(
	ID			integer NOT NULL default autoincrement,
	Surname			person_name_t NOT NULL,
	GivenName		person_name_t NOT NULL,
	Street			street_t NOT NULL,
	City			city_t NOT NULL,
	State			state_t NULL,
	Country			country_t NULL,
	PostalCode		postal_code_t NULL,
	CONSTRAINT STContactsKey PRIMARY KEY (ID ASC)
);

GRANT SELECT ON GROUPO.SpatialContacts TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.SpatialContacts TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.SpatialContacts IS 'contains contacts in Massachusetts for use with the spatial tutorial';


CREATE TABLE GROUPO.SpatialShapes 
(
	ShapeID			integer NOT NULL default autoincrement,
	Description		CHAR(32) NULL,
	Shape			ST_Geometry NULL,
        CONSTRAINT ShapesKey PRIMARY KEY (ShapeID ASC)
);

GRANT SELECT ON GROUPO.SpatialShapes TO READ_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.SpatialShapes TO MODIFY_ROLE;
COMMENT ON TABLE GROUPO.SpatialShapes IS 'contains generic shapes for use when trying out spatial features';

commit work;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Reload data
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

read adata/sales_o.sql;
read adata/sales_oi.sql;
read adata/contact.sql;
read adata/customer.sql;
read adata/fin_code.sql;
read adata/fin_data.sql;
read adata/product.sql;
read adata/dept.sql;
read adata/employee.sql;
read adata/marketinfo.sql;
read adata/stcontacts.sql;
read adata/stshapes.sql;

commit work;

SET TEMPORARY OPTION allow_read_client_file = 'on';

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/TankTop.jpg' )
WHERE Products.ID=300;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/V-Neck.jpg' )
WHERE Products.ID=301;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/CrewNeck.jpg' )
WHERE Products.ID=302;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/CottonCap.jpg' )
WHERE Products.ID=400;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/WoolCap.jpg' )
WHERE Products.ID=401;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/ClothVisor.jpg' )
WHERE Products.ID=500;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/PlasticVisor.jpg' )
WHERE Products.ID=501;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/HoodedSweatshirt.jpg' )
WHERE Products.ID=600;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/ZippedSweatshirt.jpg' )
WHERE Products.ID=601;

UPDATE Products
SET Photo=READ_CLIENT_FILE( 'adata/CottonShorts.jpg' )
WHERE Products.ID=700;

commit work;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Add foreign key definitions
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ALTER TABLE GROUPO.SalesOrders
        ADD CONSTRAINT FK_SalesRepresentative_EmployeeID FOREIGN KEY (SalesRepresentative) REFERENCES GROUPO.Employees (EmployeeID);

ALTER TABLE GROUPO.SalesOrders
        ADD CONSTRAINT FK_FinancialCode_Code FOREIGN KEY (FinancialCode) REFERENCES GROUPO.FinancialCodes (Code) ON DELETE SET NULL;

ALTER TABLE GROUPO.SalesOrders
        ADD CONSTRAINT FK_CustomerID_ID FOREIGN KEY (CustomerID) REFERENCES GROUPO.Customers (ID);

ALTER TABLE GROUPO.SalesOrderItems
        ADD CONSTRAINT FK_ProductID_ID FOREIGN KEY (ProductID) REFERENCES GROUPO.Products (ID);

ALTER TABLE GROUPO.SalesOrderItems
        ADD CONSTRAINT FK_ID_ID FOREIGN KEY (ID) REFERENCES GROUPO.SalesOrders (ID) ON DELETE CASCADE;

ALTER TABLE GROUPO.Contacts
	ADD CONSTRAINT FK_CustomerID_ID FOREIGN KEY (CustomerID) REFERENCES GROUPO.Customers (ID);

ALTER TABLE GROUPO.FinancialData
        ADD CONSTRAINT FK_Code_Code FOREIGN KEY (Code) REFERENCES GROUPO.FinancialCodes (Code) ON DELETE CASCADE;

ALTER TABLE GROUPO.Departments
        ADD CONSTRAINT FK_DepartmentHeadID_EmployeeID FOREIGN KEY (DepartmentHeadID) REFERENCES GROUPO.Employees (EmployeeID) ON DELETE SET NULL;

ALTER TABLE GROUPO.Employees
        ADD CONSTRAINT FK_DepartmentID_DepartmentID FOREIGN KEY (DepartmentID) REFERENCES GROUPO.Departments (DepartmentID);

ALTER TABLE GROUPO.MarketingInformation
        ADD CONSTRAINT FK_ProductID_ID FOREIGN KEY (ProductID) REFERENCES GROUPO.Products (ID);

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Create indexes
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CREATE INDEX IX_customer_name ON GROUPO.Customers
(
        Surname ASC,
        GivenName ASC
);

CREATE INDEX IX_product_name ON GROUPO.Products
(
        Name ASC
);
CREATE INDEX IX_product_description ON GROUPO.Products
(
        Description ASC
);
CREATE INDEX IX_product_size ON GROUPO.Products
(
        Size ASC
);
CREATE INDEX IX_product_color ON GROUPO.Products
(
        Color ASC
);

commit work;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Create text indexes
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CREATE TEXT CONFIGURATION MarketingTextConfig FROM default_char;

ALTER TEXT CONFIGURATION MarketingTextConfig
   STOPLIST 'and the';
   
COMMENT ON TEXT CONFIGURATION MarketingTextConfig 
    IS 'a text configuration object that inherits from default_char';

CREATE TEXT INDEX MarketingTextIndex ON GROUPO.MarketingInformation ( Description ) 
   CONFIGURATION MarketingTextConfig
   AUTO REFRESH EVERY 24 HOURS;

COMMENT ON TEXT INDEX MarketingTextIndex ON GROUPO.MarketingInformation 
    IS 'a text index on the marketing information table';

REFRESH TEXT INDEX MarketingTextIndex ON MarketingInformation;

commit work;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Create views (including materialized ones)
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CREATE VIEW GROUPO.ViewSalesOrders
(ID,LineID,ProductID,Quantity,OrderDate,ShipDate,Region,SalesRepresentativeName)
AS
  SELECT i.ID,i.LineID,i.ProductID,i.Quantity,
         s.OrderDate,i.ShipDate,
         s.Region,e.GivenName||' '||e.Surname
    FROM GROUPO.SalesOrderItems AS i
        JOIN GROUPO.SalesOrders AS s
        JOIN GROUPO.Employees AS e
    WHERE s.ID=i.ID
        AND s.SalesRepresentative=e.EmployeeID;
	
COMMENT ON VIEW GROUPO.ViewSalesOrders IS 'a view that lists all the sales orders together with the sales representatives';

CREATE MATERIALIZED VIEW GROUPO.EmployeeConfidential 
AS
  SELECT e.EmployeeID, e.DepartmentID, 
        e.SocialSecurityNumber, e.Salary, e.ManagerID, 
        d.DepartmentName, d.DepartmentHeadID
    FROM GROUPO.Employees AS e, GROUPO.Departments as d
    WHERE e.DepartmentID=d.DepartmentID;
    
    
GRANT SELECT ON GROUPO.EmployeeConfidential TO MODIFY_ROLE;
GRANT DELETE, INSERT, UPDATE ON GROUPO.EmployeeConfidential TO MODIFY_ROLE;
COMMENT ON MATERIALIZED VIEW GROUPO.EmployeeConfidential IS 'a materialized view of the employees of the sporting goods company (enable to use)';

ALTER MATERIALIZED VIEW GROUPO.EmployeeConfidential DISABLE;
	
commit work;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Create procedures and grant privileges
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CREATE PROCEDURE GROUPO.ShowContacts( IN contact_ID integer DEFAULT NULL)
RESULT(ID integer,
Surname person_name_t,
GivenName person_name_t,Title person_title_t,
Street street_t,
City city_t,
State state_t,
Country country_t,
PostalCode postal_code_t,
Phone phone_number_t,
Fax phone_number_t)
BEGIN
  IF contact_ID IS NULL THEN
    SELECT ID,Surname,GivenName,Title,
           Street,City,State,Country,PostalCode,Phone,Fax
      FROM GROUPO.Contacts 
      ORDER BY Contacts.ID ASC
  ELSE
    SELECT ID,Surname,GivenName,Title,
           Street,City,State,Country,PostalCode,Phone,Fax
      FROM GROUPO.Contacts
      WHERE Contacts.ID=contact_ID
      ORDER BY Contacts.ID ASC
  END IF;
END;

GRANT EXECUTE ON GROUPO.ShowContacts TO EXEC_ROLE;
COMMENT ON PROCEDURE GROUPO.ShowContacts IS 'ShowContacts shows contact information. It takes an optional argument, the contact identifier.';

CREATE PROCEDURE GROUPO.ManageContacts(IN action char(1),
IN contact_ID integer,
IN contact_new_ID integer DEFAULT 0,
IN contact_surname person_name_t DEFAULT NULL,
IN contact_given_name person_name_t DEFAULT NULL,
IN contact_title person_title_t DEFAULT NULL,
IN contact_street street_t DEFAULT NULL,
IN contact_city city_t DEFAULT NULL,
IN contact_state state_t DEFAULT NULL,
IN contact_country country_t DEFAULT NULL,
IN contact_postal_code postal_code_t DEFAULT NULL,
IN contact_phone phone_number_t DEFAULT NULL,
IN contact_fax phone_number_t DEFAULT NULL)
RESULT(ID integer,
Surname person_name_t,
GivenName person_name_t,Title person_title_t,
Street street_t,
City city_t,
State state_t,
Country country_t,
PostalCode postal_code_t,
Phone phone_number_t,
Fax phone_number_t)
BEGIN
  CASE action
  WHEN 'L' THEN
    SELECT * FROM GROUPO.Contacts 
      WHERE Contacts.ID=contact_ID
  WHEN 'I' THEN
    INSERT INTO GROUPO.Contacts
        (ID,Surname,GivenName,Title,
        Street,City,State,Country,PostalCode,
        Phone,Fax)
      VALUES
        (contact_ID,contact_surname,contact_given_name,contact_title,
        contact_street,contact_city,contact_state,contact_country,contact_postal_code,
        contact_phone,contact_fax)
  WHEN 'U' THEN
    UPDATE GROUPO.Contacts SET
        Contacts.ID=contact_new_ID,
        Contacts.Surname=contact_surname,
        Contacts.GivenName=contact_given_name,
        Contacts.Title=contact_title,
        Contacts.Street=contact_street,
        Contacts.City=contact_city,
        Contacts.State=contact_state,
        Contacts.Country=contact_country,
        Contacts.PostalCode=contact_postal_code,
        Contacts.Phone=contact_phone,
        Contacts.Fax=contact_fax
      WHERE Contacts.ID=contact_ID
  WHEN 'D' THEN
    DELETE FROM GROUPO.Contacts 
      WHERE Contacts.ID=contact_ID
  END CASE
END;

GRANT EXECUTE ON GROUPO.ManageContacts TO MODIFY_ROLE;
COMMENT ON PROCEDURE GROUPO.ManageContacts IS 'ManageContacts manages contact information. This procedure can be used to show information on all contacts or just one.';

CREATE PROCEDURE GROUPO.ShowCustomers()
result(ID integer,
CompanyName company_name_t)
BEGIN
  SELECT ID,CompanyName 
    FROM GROUPO.Customers
END;

GRANT EXECUTE ON GROUPO.ShowCustomers TO EXEC_ROLE;
COMMENT ON PROCEDURE GROUPO.ShowCustomers IS 'ShowCustomers shows the identifiers and company names of customers. It takes no arguments.';

CREATE PROCEDURE GROUPO.ShowCustomerProducts(INOUT customer_ID integer)
RESULT(ID integer,
Name char(15),
QuantityOrdered integer)
BEGIN
  SELECT Products.ID,Products.Name,SUM(SalesOrderItems.Quantity)
    FROM GROUPO.Products,
         GROUPO.SalesOrderItems,
         GROUPO.SalesOrders
    WHERE SalesOrders.CustomerID=customer_ID
      AND SalesOrders.ID=SalesOrderItems.ID 
      AND Products.ID=SalesOrderItems.ProductID
    GROUP BY Products.ID,Products.Name
END;

GRANT EXECUTE ON GROUPO.ShowCustomerProducts TO EXEC_ROLE;
COMMENT ON PROCEDURE GROUPO.ShowCustomerProducts IS 'ShowCustomerProducts shows the quantiities of all products ordered by a particular customer. It takes the customer identifier as an argument.';

CREATE PROCEDURE GROUPO.ShowProductInfo(INOUT product_ID integer)
RESULT(ID integer,
Name char(15),
Description char(30),
Size char(18),
Color char(18),
Quantity integer,
UnitPrice decimal(15,2))
BEGIN
  SELECT ID,Name,Description,Size,Color,Quantity,UnitPrice
    FROM GROUPO.Products
    WHERE Products.ID=product_ID
END;

GRANT EXECUTE ON GROUPO.ShowProductInfo TO EXEC_ROLE;
COMMENT ON PROCEDURE GROUPO.ShowProductInfo IS 'ShowProductInfo shows information on a product. It takes the product identifier as an argument.';

CREATE PROCEDURE GROUPO.ShowSalesOrders(IN customer_ID integer)
RESULT(ID integer,
LineID integer,
ProductID integer,
Quantity integer,
OrderDate date,
ShipDate date,
Region char(7),
SalesRepresentativeName char(40))
BEGIN
  SELECT i.ID,i.LineID,i.ProductID,i.Quantity,
        s.OrderDate,i.ShipDate,
        s.Region,e.GivenName||' '||e.Surname
    FROM GROUPO.SalesOrderItems AS i
        JOIN GROUPO.SalesOrders AS s
        JOIN GROUPO.Employees AS e
    WHERE s.CustomerID=customer_ID AND s.ID=i.ID 
        AND s.SalesRepresentative=e.EmployeeID
END;

GRANT EXECUTE ON GROUPO.ShowSalesOrders TO EXEC_ROLE;
COMMENT ON PROCEDURE GROUPO.ShowSalesOrders IS 'ShowSalesOrders shows all the sales orders made by a particular customer. It takes the customer identifier as an argument.';

CREATE PROCEDURE GROUPO.ShowSalesOrderDetail(IN customer_ID integer,
    IN product_ID integer)
RESULT(ID integer,
OrderDate date,
FinancialCode char(2),
Region char(7),
SalesRepresentative integer)
BEGIN
  SELECT s.ID,s.OrderDate,s.FinancialCode,
         s.Region,s.SalesRepresentative
    FROM GROUPO.SalesOrders AS s, 
         GROUPO.SalesOrderItems AS i
    WHERE s.CustomerID=customer_ID
        AND i.ProductID=product_ID
	AND s.ID=i.ID
END;

GRANT EXECUTE ON GROUPO.ShowSalesOrderDetail TO EXEC_ROLE;
COMMENT ON PROCEDURE GROUPO.ShowSalesOrderDetail IS 'ShowSalesOrderDetail shows some details on a specified product from the sales orders made by a particular customer. It takes the customer identifier and product identified as arguments.';

CREATE PROCEDURE GROUPO.ShowSalesOrderItems(IN order_ID integer)
RESULT(LineID integer,
ProductID integer,
Quantity integer,
ShipDate date)
BEGIN
  SELECT LineID,ProductID,Quantity,ShipDate
    FROM GROUPO.SalesOrderItems
    where SalesOrderItems.ID=order_ID
END;

GRANT EXECUTE ON GROUPO.ShowSalesOrderItems TO EXEC_ROLE;
COMMENT ON PROCEDURE GROUPO.ShowSalesOrderItems IS 'ShowSalesOrderItems shows items that were ordered in the speciifed sales order. It takes the sales order identifier as an argument.';

CREATE PROCEDURE GROUPO.debugger_tutorial()
RESULT( top_company varchar(35), top_value int )
-- This stored procedure contains an intentional bug.
-- Finding the bug is the subject of the debugger tutorial
-- in the SQL User's Guide.
BEGIN
  DECLARE top_company varchar(35);
  DECLARE top_value int;
  DECLARE error_not_found EXCEPTION FOR sqlState VALUE '02000';
  DECLARE cursor_this_customer DYNAMIC SCROLL CURSOR FOR
      SELECT CompanyName,
             CAST( SUM( SalesOrderItems.Quantity *
                 Products.UnitPrice ) AS integer) AS Value
      FROM
	GROUPO.Customers LEFT OUTER JOIN
	GROUPO.SalesOrders LEFT OUTER JOIN
	GROUPO.SalesOrderItems LEFT OUTER JOIN
	GROUPO.Products
      GROUP BY CompanyName;
  DECLARE this_value integer;
  DECLARE this_company char(35);
  OPEN cursor_this_customer;
  customer_loop: LOOP
    FETCH NEXT cursor_this_customer INTO this_company,
      this_value;
    IF sqlState = error_not_found THEN
      LEAVE customer_loop
    END IF;
    IF this_value > top_value THEN
      SET top_value=this_value;
      SET top_company=this_company
    END IF
  END LOOP customer_loop;
  CLOSE cursor_this_customer;
  SELECT top_company, top_value;
END;

GRANT EXECUTE ON GROUPO.debugger_tutorial TO EXEC_ROLE;
COMMENT ON PROCEDURE GROUPO.debugger_tutorial IS 'This stored procedure is used in a tutorial in the documentation.';

commit work;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//   Create triggers
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CREATE TRIGGER TR_change_managers 
  BEFORE UPDATE OF DepartmentHeadID
    ON GROUPO.Departments
  REFERENCING OLD AS old_department
            NEW AS new_department
FOR EACH ROW
BEGIN
  UPDATE GROUPO.Employees
    SET Employees.ManagerID=new_department.DepartmentHeadID
    WHERE Employees.DepartmentID=old_department.DepartmentID
END;

CREATE TRIGGER TR_change_departments 
  AFTER UPDATE OF DepartmentID
    ON GROUPO.Departments
  REFERENCING OLD AS old_department
            NEW AS new_department
FOR EACH ROW
BEGIN
  UPDATE GROUPO.Employees
    SET Employees.DepartmentID=new_department.DepartmentID
    WHERE Employees.DepartmentID=old_department.DepartmentID
END;

commit work;

