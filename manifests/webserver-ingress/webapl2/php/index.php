<?php
session_start();
if (!isset($_SESSION['count'])) {
    $_SESSION['count'] = 1;
} else {
    $_SESSION['count']++;
}
echo "Hostname: ".gethostname()."<br>\n";
echo $_SESSION['count']."th time access.\n";
echo "<br>\n";
echo "HTTP_CLIENT_IP = ".$_SERVER['HTTP_CLIENT_IP']."<br>\n";
echo "HTTP_X_FORWARDED_FOR = ".$_SERVER['HTTP_X_FORWARDED_FOR']."<br>\n";
echo "HTTP_X_FORWARDED = ".$_SERVER['HTTP_X_FORWARDED']."<br>\n";
echo "HTTP_X_CLUSTER_CLIENT_IP = ".$_SERVER['HTTP_X_CLUSTER_CLIENT_IP']."<br>\n";
echo "HTTP_FORWARDED_FOR = ".$_SERVER['HTTP_FORWARDED_FOR']."<br>\n";
echo "HTTP_FORWARDED = ".$_SERVER['HTTP_FORWARDED']."<br>\n";
echo "REMOTE_ADDR = ".$_SERVER['REMOTE_ADDR']."<br>\n";

?>
