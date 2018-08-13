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

IF ( SELECT COUNT(*)
    FROM SYSJAVACLASS
    WHERE class_name = 'Invoice' ) = 1 THEN
	REMOVE JAVA CLASS Invoice
    END IF;

DROP PROCEDURE IF EXISTS InvoiceMain;

DROP PROCEDURE IF EXISTS init;
    
DROP FUNCTION IF EXISTS rateOfTaxation;
    
DROP FUNCTION IF EXISTS totalSum;
    
DROP FUNCTION IF EXISTS getLineItem1Description;

DROP FUNCTION IF EXISTS getLineItem1Cost;

DROP FUNCTION IF EXISTS getLineItem2Description;
    
DROP FUNCTION IF EXISTS getLineItem2Cost;
