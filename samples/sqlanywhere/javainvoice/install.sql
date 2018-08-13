-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
-- This sample code is provided AS IS, without warranty or liability
-- of any kind.
-- 
-- You may use, reproduce, modify and distribute this sample code
-- without limitation, on the condition that you retain the foregoing
-- copyright notice and disclaimer as to the original code.  
-- 
-- *********************************************************************

-- If Java VM not in path, tell us where it is.
-- SET OPTION PUBLIC.java_location='c:\jdk1.6.0_20\bin\java.exe'
-- GO

READ remove.sql;

INSTALL JAVA NEW FROM FILE 'Invoice.class';

-- A wrapper for the main method of our Java class
CREATE PROCEDURE InvoiceMain( IN arg1 CHAR(50) )
  EXTERNAL NAME 'Invoice.main([Ljava/lang/String;)V'
  LANGUAGE JAVA;

-- Invoice.init takes a string argument (Ljava/lang/String;)
-- a double (D), a string argument (Ljava/lang/String;), and
-- another double (D), and returns nothing (V)
CREATE PROCEDURE init( IN arg1 CHAR(50),
                       IN arg2 DOUBLE, 
                       IN arg3 CHAR(50), 
                       IN arg4 DOUBLE) 
EXTERNAL NAME 'Invoice.init(Ljava/lang/String;DLjava/lang/String;D)V' 
LANGUAGE JAVA;

-- The Java methods below take no arguments and return a double (D)
-- or a string (Ljava/lang/String;)

CREATE FUNCTION rateOfTaxation() 
RETURNS DOUBLE 
EXTERNAL NAME 'Invoice.rateOfTaxation()D' 
LANGUAGE JAVA;

CREATE FUNCTION totalSum() 
RETURNS DOUBLE 
EXTERNAL NAME 'Invoice.totalSum()D' 
LANGUAGE JAVA;

CREATE FUNCTION getLineItem1Description() 
RETURNS CHAR(50) 
EXTERNAL NAME 'Invoice.getLineItem1Description()Ljava/lang/String;' 
LANGUAGE JAVA;

CREATE FUNCTION getLineItem1Cost() 
RETURNS DOUBLE 
EXTERNAL NAME 'Invoice.getLineItem1Cost()D' 
LANGUAGE JAVA;

CREATE FUNCTION getLineItem2Description() 
RETURNS CHAR(50) 
EXTERNAL NAME 'Invoice.getLineItem2Description()Ljava/lang/String;' 
LANGUAGE JAVA;

CREATE FUNCTION getLineItem2Cost() 
RETURNS DOUBLE 
EXTERNAL NAME 'Invoice.getLineItem2Cost()D' 
LANGUAGE JAVA;
