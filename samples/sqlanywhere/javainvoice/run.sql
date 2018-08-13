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

CALL init('Shirt',10.00,'Jacket',25.00);

SELECT getLineItem1Description() AS Item1,
	CAST( getLineItem1Cost() AS DECIMAL( 6, 2 ) ) AS Item1Cost,
        getLineItem2Description() AS Item2,
	CAST( getLineItem2Cost() AS DECIMAL( 6, 2 ) ) AS Item2Cost,
	CAST( rateOfTaxation() AS DECIMAL( 6, 2 ) ) AS TaxRate,
	CAST( totalSum() AS DECIMAL( 6, 2 ) ) AS Cost;
OUTPUT TO 'report1.txt' FORMAT TEXT;


CALL init('Work boots',79.99,'Hay fork',37.49);

SELECT getLineItem1Description() AS Item1,
	CAST( getLineItem1Cost() AS DECIMAL( 6, 2 ) ) AS Item1Cost,
        getLineItem2Description() AS Item2,
	CAST( getLineItem2Cost() AS DECIMAL( 6, 2 ) ) AS Item2Cost,
	CAST( rateOfTaxation() AS DECIMAL( 6, 2 ) ) AS TaxRate,
	CAST( totalSum() AS DECIMAL( 6, 2 ) ) AS Cost;
OUTPUT TO 'report2.txt' FORMAT TEXT;
