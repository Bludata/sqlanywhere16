<?php
session_start();

print '<p>$_COOKIE = ' . serialize( $_COOKIE ) . "</p>\n";
print '<p>$_REQUEST = ' . serialize( $_REQUEST ) . "</p>\n";

if( !isset( $_SESSION['counter'] ) ) {
    $_SESSION['counter'] = 1;
}

for($i=0; $i<10; $i++){
    $_SESSION['counter']++;
    echo $_SESSION['counter'] . ' ';
}

# ensure the session is persisted
session_write_close();

?>
