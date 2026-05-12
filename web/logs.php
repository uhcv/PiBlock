<?php

require_once "auth.php";
require_once "db.php";

if ($_SESSION['rol'] !== 'admin') {
    die("Accés denegat");
}

$stmt = $pdo->query("SELECT * FROM logs ORDER BY created_at DESC");

$logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html lang="ca">
<head>

    <meta charset="UTF-8">

    <title>Logs Sistema</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

</head>

<body class="bg-dark text-white p-5">

<div class="container">

    <h1 class="mb-4">Logs del sistema</h1>

    <a href="dashboard.php" class="btn btn-secondary mb-4">
        Tornar Dashboard
    </a>

    <table class="table table-dark table-striped">

        <thead>

            <tr>
                <th>ID</th>
                <th>Usuari</th>
                <th>Acció</th>
                <th>Data</th>
            </tr>

        </thead>

        <tbody>

        <?php foreach($logs as $log): ?>

            <tr>

                <td><?php echo $log['id']; ?></td>

                <td>
                    <?php echo htmlspecialchars($log['username']); ?>
                </td>

                <td>
                    <?php echo htmlspecialchars($log['action']); ?>
                </td>

                <td>
                    <?php echo $log['created_at']; ?>
                </td>

            </tr>

        <?php endforeach; ?>

        </tbody>

    </table>

</div>

</body>
</html>
