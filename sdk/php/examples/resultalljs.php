<html>
<title>SQL Anywhere Result All function sample</title>
<body>
<script>

//Function to handle when a row is clicked.
function clickRow(row) {

    if (window.ActiveXObject) {  // code for IE
	var ord = clickRowHeader(row);
	alert("Record: " + ord);

    } else {

	var objSib = row.previousSibling;
	if ( objSib == null ) {
	    alert(1);
	} else {
	    for (var i = 1; ;i++) {
		objSib = objSib.previousSibling;
	    	if ( objSib.previousSibling != null && i != 1 ) {
		    objSib=objSib.previousSibling;
		}
		if (objSib == null || objSib.previousSibling == null ) {
		    if ( i == 1 ) {
			alert("Record :" + 2 );
			break;
		    
		    } else {
			var ord = i + 1;
			alert("Record :" + ord );
			break;
		    }
		}
	    }
	}
    }
}

//Function to handle when a cell <td> is clicked.
function clickCell(obj) {
    var ord = clickRowHeader(obj);
    alert("Cell: " + ord);
    alert("Cell Value:" + obj.innerHTML);
}

//Function to handle when a column header <th> is clicked.
function clickHeader(obj) {
    var ord = clickRowHeader(obj);
    alert("Sort By : " + ord);
    window.location="resultalljs.php?id="+ord;
}

//Function to handle when a column header <th> is clicked
//Same code can be used when a row is click on MSIE.
function clickRowHeader(obj) {
    var objSib = obj.previousSibling;
    if ( objSib == null ) {
  	return 1;
    } else {
	for (var i = 0; ;i++) {
	    objSib=objSib.previousSibling;
	    if (objSib == null ) {
		var ord = i + 2;
		return ord;
		break;
	    }
	}
    }
}
</script>

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
	    ////////////////// Sample 1: One line of code to format table.
	    echo "<h3>Basic Example</h3>";
	    echo "<p>This sample table produced by sasql_resultall() basic formating on ";
	    echo "theader and table. This sample is something we will build upon.</p>";
	    
	    sasql_result_all( $result, "border=0 bordercolor=#3F3986" , 
		"bgcolor=#FF9533 style=\"color=#211F5F\"" ,"bgcolor=#AFB5CD");
	   
	    ////////////////// Sample 2:  Javascript Sorting
	    echo "<h3>Javascript sorting</h3>";
	    echo "<p>This sample table produced by sasql_resultall() basic formating on";
	    echo " theader and table.";
	    echo "Click on the headers to sort the data. Table generated is generated in one line";
	    echo " of code.</p>";
	    echo "Code:";
	    echo '<pre>sasql_result_all( $result, "border=0 bordercolor=#3F3986" , <br>';
	    echo '     "onclick=\"clickHeader(this)\" bgcolor=#FF9533 style=\"color=#211F5F\"","bgcolor=#AFB5CD" );</pre>';
	    
	    sasql_result_all( $result, "border=0 bordercolor=#3F3986" , 
		"onclick=\"clickHeader(this)\" bgcolor=#FF9533 style=\"color=#211F5F\"", "bgcolor=#AFB5CD" );
	    
	    
	    ////////////////// Sample 3:  Getting Row information.
	    echo "<h3>Getting Row information</h3>";
	    echo "<p>This sample table produced by sasql_resultall() formating via CSS ";
	    echo "with alternating rows.";
	    echo "Click on the any row to find to help identify the row in Javascript. Again";
	    echo " this table generated is generated in one line of code.</p>";
	    echo "Code:";
	    echo '<pre>sasql_result_all( $result, "border=2 bordercolor=#3F3986" , ';
	    echo '"bgcolor=#3F3986 style=\"color=#FF9533\"" , <br>';
	    echo '     \'onclick="clickRow(this)" class="even"&#62&#60class="odd" ';
	    echo 'onclick="clickRow(this)" \');</pre>';
	    
	    sasql_result_all( $result, "border=2 bordercolor=#3F3986" , 
		"bgcolor=#3F3986 style=\"color=#FF9533\"" , 
		'onclick="clickRow(this)" class="even"><class="odd" onclick="clickRow(this)" ');
	   
	    ////////////////// Sample 4:  Getting cell information.
	    echo "<h3>Getting Cell inforamtion</h3>";
	    echo "<p>This sample table produced by sasql_resultall() formating via CSS with ";
	    echo "alternating rows where the query uses appropriate aliases.";
	    echo "Click on the any row to find to help identify the cell in Javascript. Again this ";
	    echo "table generated is generated in one line of code.</p>";
	    echo "Code:";
	    echo '<pre>sasql_result_all( $result2, "border=1 bordercolor=#008000 align=center", null,  <br>';
	    echo '     "class=\'even\'&#62&#60class=\'odd\'","onclick=\"clickCell(this)\"");</pre>';
	    
	    $result2 = sasql_query( $conn, "SELECT DepartmentID AS ID, DepartmentName AS \"Department Name\" FROM Departments" );
	    sasql_result_all( $result2, "border=1 bordercolor=#008000 align=center", null,
		"class='even'><class='odd'","onclick=\"clickCell(this)\"");
	
	
	    sasql_free_result( $result );
	}

	sasql_close( $conn );
    }

?>
</body>
</html>
