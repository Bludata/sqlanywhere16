<html>
<title>SQL Anywhere Result All function sample</title>
<body>
<style>
    body {
	font: 12px Verdana, san-serif;
    }
    th.invisible {
	display:none;
	visibility:hidden;
    }
    tr.odd {
	background-color : #FF9533;
    }
    tr.even {
	background-bgcolor : #FFAB5D;
    }
    pre {
	background : #FFAB5D;
    }
</style>

<?php
    #*********************************************************************
    # Copyright 2013 SAP AG or an SAP affiliate company. All rights reserved.
    #
    # This sample code is provided AS IS, without warranty or liability
    # of any kind.
    # 
    # You may use, reproduce, modify and distribute this sample code
    # without limitation, on the condition that you retain the foregoing
    # copyright notice and disclaimer as to the original code.
    # 
    #*********************************************************************
    #
    # This sample program contains a hard-coded userid and password
    # to connect to the demo database. This is done to simplify the
    # sample program. The use of hard-coded passwords is strongly
    # discouraged in production code.  A best practice for production
    # code would be to prompt the user for the userid and password.
    #


    $id = $_GET[id];

    $conn = sasql_connect( "UID=DBA;PWD=sql" );

    if( ! $conn ) {
	echo "sasql_connect failed\n";
    } else {

	if ( $id ) {
	    $result = sasql_query( $conn, "SELECT * FROM Departments ORDER BY ".$id );
	} else {
	    $result = sasql_query( $conn, "SELECT * FROM Departments" );
	}
    
	if( ! $result ) {
	    echo "sasql_query failed!";
	} else {
	    ////////////////// Sample 1: One Line of Code
	    echo "<h3>Basic Sample</h3>";
	    echo "<p>This sample table produced by sasql_result_all() basic formating on ";
	    echo "theader and table.</p>";
	    sasql_result_all( $result, "border=0 bordercolor=#3F3986" , 
		"bgcolor=#FF9533 style=\"color=#211F5F\"" ,"bgcolor=#AFB5CD");
	    echo "Code:</br>";
	    echo '<pre>sasql_result_all( $result, "border=0 bordercolor=#3F3986" ,';
	    echo ' "bgcolor=#FF9533 style=\"color=#211F5F\"" ,"bgcolor=#AFB5CD)</pre>';
	   
	    ////////////////// Sample 2: Custom Headers for table for sorting
	    echo "<h3>Sorting Sample</h3>";
	    echo "<p>This sample table produced by sasql_resultall() via PHP generated ";
	    echo "table headers and footers.";
	    echo "Click on the headings to order the data.</p>";
	    echo "<table>\n<thead>";
	    echo "<th><a href='resultall.php?id=1'>ID</a></th>";
	    echo "<th><a href='resultall.php?id=2'>Department<br>Name</a></th>";
	    echo "<th><a href='resultall.php?id=3'>Manager<br>ID</a></th></thead><tbody>";
	    sasql_result_all( $result, "none" , "none" , null, "align=center" );
	    echo "</tbody><tfoot><tr> <td>Row Count = 5</td></tr></tfoot>\n";
	    echo "</table>\n";
	    
	    
	    ////////////////// Sample 3: One Line of Code to alternate rows formats via CSS
	    echo "<h3>Row Alternates via CSS</h3><p>This sample table produced by sasql_resultall() formating via CSS with alternating rows with one line of PHP code.</p>";
	    echo "Code:</br>";
	    echo '<pre>sasql_result_all( $result, "border=2 bordercolor=#3F3986" , "bgcolor=#3F3986 style=\"color=#FF9533\"" , \'class="even"&#62&#60class="odd"\');</pre>';
	    sasql_result_all( $result, "border=2 bordercolor=#3F3986" , 
		"bgcolor=#3F3986 style=\"color=#FF9533\"" , 'class="even"><class="odd"');
	   
	    ////////////////// Sample 4: Again One Line of Code
	    echo "<h3>Headers via SQL Aliases</h3>";
	    echo "<p>This sample table produced by sasql_resultall() formating via ";
	    echo "CSS with alternating rows where the query uses appropriate aliases.</p>";
	    $result2 = sasql_query( $conn, "SELECT DepartmentID AS ID, DepartmentName AS \"Department Name\" FROM Departments" );
	    sasql_result_all( $result2, "border=1 bordercolor=#008000 align=center", 
		null,  "class='even'><class='odd'"); //,"onclick=alert('me')");
	    echo "<p><a href='resultalljs.php'>Also see the sasql_result_all() using ";
	    echo "javascript</a></p>";
	    sasql_free_result( $result );
	}

	sasql_close( $conn );
    }

?>
</body>
</html>
