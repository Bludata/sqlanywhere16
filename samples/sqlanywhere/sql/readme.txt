// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
// 
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.  
// 
// *********************************************************************

SQL Anywhere Sample Stored Procedures and Functions
===================================================

The procedures and functions in this directory are provided as examples.

*******************************************************************************************

verify_password
---------------

This example defines a function which implements advanced password rules 
including requiring certain types of characters in the password and 
disallowing password reuse. The f_verify_pwd function is called by the 
server using the verify_password_function option when a User ID is created 
or a password is changed.  

The DEFAULT login profile is configured to expire passwords every 180 days
and lock non-DBA accounts after 5 consecutive failed login attempts.
The application may call the procedure specified by the 
post_login_procedure option to report that the password should be changed 
before it expires.


*******************************************************************************************

sa_get_column_list
------------------

Parameters:
1) table name
2) exclude list (optional)
3) separator (optional)
4) include only key or non-key columns (optional)


If connected to demo.db as DBA:
        Select * from sa_get_column_list('GROUPO.SalesOrderItems')
returns:
        column_list
        ------------------------------------------------------
        ID, LineID, ProductID, Quantity, ShipDate


If you want to specify a different table owner:
        Select * from sa_get_column_list('SYS.SYSTABLE')
returns:
        column_list
        ------------------------------------------------------
        table_id, file_id, count, first_page, last_page, primary_root, creator, ...


You can also exclude columns:
        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems','LineID,Quantity')
returns:
        column_list
        -------------------------------
        ID, ProductID, ShipDate

This might be used when:
1.  creating publications and article lists
2.  Generating SQL statements on the fly (e.g. INSERT)


You can also specify the separator:
        Select '<td>'||column_list||'</td>' as cells
        from sa_get_column_list('GROUPO.SalesOrderItems', '', '</td><td>',)
returns:
        cells
        ------------------------------------------------------
        <td>ID</td><td>LineID</td><td>ProductID</td><td>Quantity</td><td>ShipDate</td>


Finally, you can indicate if you want only the primary key columns, or the
non-primary key columns.
        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', '', ', ', NULL)
returns:
        ID, LineID, ProductID, Quantity, ShipDate

        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', '', ', ', 'Y')
or
        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', @only_keys='Y')
returns:
        ID, LineID

        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', '', ', ', 'N')
or
        Select column_list
        from sa_get_column_list('GROUPO.SalesOrderItems', @only_keys='N')
returns:
        ID, LineID, ProductID, Quantity, ShipDate

This may be used to generate the SET and WHERE parts of an UPDATE statement.

*******************************************************************************************

create_default_stoplist
-----------------------

This example creates and loads two tables.  One table defines default
stoplists for a number of languages.  The other maps the iso_639
language code to the name returned by the 'language' server property.
After the tables are loaded, they are used to set the default_char and
default_nchar text configurations based on the value of the 'language'
server property.

Before you run this sample, you need to:

    1. Modify the load commands to specify the full path to the .csv files.
    Remember to use double backslahes under Windows

    2. Copy the .csv files to the database directory

*******************************************************************************************

simplify_geometry
-----------------

This example implements functions which can be used to reduce the
number of points in linestrings and polygon rings.  The eliminated points
change the geometry by less than the specified tolerance.  This can be
useful to reduce the complexity of geometries that have many consecutive
points which are colinear or nearly colinear.

The simplify_geometry function takes two parameters:
1) g is the input geometry to be simplified.  It must use a planar 
   spatial reference system.
2) toler is the maximum difference (tolerance) between the original
   geometry and the resulting simplified geometry.  It is specified
   in the default linear unit of measure for the spatial reference system.
It returns a simplified geometry of the same type and spatial reference
system as g.  Not all geometries or geometry types can be simplified,
and the original geometry is returned if it can not be simplified.

WARNING: THE RETURNED GEOMETRY MAY NOT BE VALID (ST_IsValid returns 0)
EVEN IF THE INPUT LINESTRING IS VALID.  By removing points which are
within the specified tolerance of the simplified geometry, self
intersections and "bow ties" can result.  It is recommended that
you confirm the returned geometries are valid with the ST_IsValid method
before using them.
