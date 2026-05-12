<?php

$host = "localhost";
$dbname = "piblock";
$user = "piblockuser";
$pass = "piblock";

try {

    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8",
        $user,
        $pass
    );

    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

} catch(PDOException $e) {

    die("Error DB: " . $e->getMessage());

}
