<?php

require_once "auth.php";
require_once "db.php";

if ($_SESSION['rol'] !== 'admin') {
    die("Accés denegat");
}

if (isset($_GET['id'])) {

    $id = intval($_GET['id']);

    $stmt = $pdo->prepare("DELETE FROM usuaris WHERE id = :id");

    $stmt->execute([
        ':id' => $id
    ]);

}

header("Location: admin_users.php");
exit();
