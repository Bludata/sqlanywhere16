<?php
#   *******************************************************************
#   Copyright 2013 SAP AG or an SAP affiliate company. All rights reserved.
#   This sample code is provided AS IS, without warranty or liability of
#   any kind.
#  
#   You may use, reproduce, modify and distribute this sample code without
#   limitation, on the condition that you retain the foregoing copyright 
#   notice and disclaimer as to the original code.  
#   
#   *******************************************************************
?>
<html>
<head><title>PHP test</title></head>
<body>
<?php

print '<p>$_SERVER = ' . serialize( $_SERVER ) . "</p>\n";
print '<p>$_GET = ' . serialize( $_GET ) . "</p>\n";
print '<p>$_POST = ' . serialize( $_POST ) . "</p>\n";
print '<p>$_COOKIE = ' . serialize( $_COOKIE ) . "</p>\n";
print '<p>$_FILES = ' . serialize( $_FILES ) . "</p>\n";
print '<p>$_REQUEST = ' . serialize( $_REQUEST ) . "</p>\n";

setcookie( "my-cookie-name", "my-cookie-value" );

print php_sapi_name();

?>
<FORM METHOD="post" ENCTYPE="multipart/form-data">
    Last file was: <?php print $_REQUEST[ "filename" ] ?><br>
    File name: <input type=text name="filename"><br>
    File: <input type=file name="file"><br>
<INPUT TYPE=SUBMIT VALUE="Submit">

</FORM>
</body>
</html>
