<html><title>Performance Comparison</title>
<body>
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

function microtime_diff($a, $b) {
    list($a_dec, $a_sec) = explode(" ", $a);
    list($b_dec, $b_sec) = explode(" ", $b);
    return $b_sec - $a_sec + $b_dec - $a_dec;
}
function QueryToHTML($res, $sTable, $sRow, $sCell, $sHead, $sHeadings) {
    $time = microtime();
    $cFields = sasql_num_fields($res);
    $strTable = "<table $sTable ><tr>";  
    if ($sHeadCols == null ) {
	for ($n=1; $n<=$cFields; $n++) {
	    $field = sasql_fetch_field( $res );
	    $strTable .= "<th $sHead>". str_replace("_", " ", $field->name ) . "</th>";
	    //$strTable .= "<th $sHead>"  . "</th>";
	}
    } else {
	$strTable .= $sHeadings;
    }
    $strTable .= "</thead><tbody>";
    $row = sasql_fetch_row($res);
    while( $row ) { 
	$strTable .= "<tr $sRow>";
	    for ($n=0; $n<=$cFields; $n++) {
		$cell = $row[$n];
		if ($cell=='') {
		    $strTable .= "<td $sCell>&nbsp;</td>";
		} else {
		    $strTable .= "<td $sCell>". $cell . "</td>";
		}
	    }
	    $strTable .= "</tr>";
	    $row = sasql_fetch_row($res);
    }
    $strTable .= "</tbody></table>";
    return $strTable;
}

    $time= microtime();
    $conn = sasql_connect( "UID=DBA;PWD=sql" );

    if( ! $conn ) {
	echo "sasql_connect failed\n";
    } else {

        $result = sasql_query( $conn, "SELECT * FROM Customers");

	if( ! $result ) {
	    echo "sasql_query failed!";
	    echo sasql_error($conn);
	} else {

	    echo "<p>Query completed successfully!!!</p><p>Now compare resulting time on bottom of page after commenting out lines 58 and 59 and uncommenting line 57</p>";
	    echo "<p>You should find that using result all performs better.</p>";
	    $html = sasql_result_all( $result  , "border=2px cellspacing=0 outline=0 padding=0 borderColor=#2A96C2 outlinewidth=0", null, null ,"border=0 bgcolor=#FF9533 onclick='alert(this)'");
	    //$html = QueryToHTML( $result , "" ,"onclick=\"alert(this)\"");
	    //echo $html;
		
	
	    sasql_free_result( $result );
	}

	echo "\nConnected successfully\n";
	sasql_close( $conn );
	echo "Time elapsed:  ".microtime_diff($time, microtime());
    
    }

?>

</body></html>
