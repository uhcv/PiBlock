<?php

session_start();

require_once "db.php";

if (isset($_SESSION['username'])) {

    $log = $pdo->prepare("
    INSERT INTO logs (username, action)
    VALUES (:username, :action)
    ");

    $log->execute([
        ':username' => $_SESSION['username'],
        ':action' => 'Logout'
    ]);

}

session_destroy();

header("Location: login.php");
exit();