<?php


require_once "auth.php";
require_once "db.php";

if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit();
}


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

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $stmt = $pdo->prepare("
        UPDATE config_servidor
        SET valor = :valor
        WHERE clau = :clau
    ");

    $stmt->execute([
        ':valor' => $_POST['dificultat'],
        ':clau' => 'dificultat'
    ]);

    $stmt->execute([
        ':valor' => $_POST['gamemode'],
        ':clau' => 'gamemode'
    ]);

    $stmt->execute([
        ':valor' => $_POST['whitelist'],
        ':clau' => 'whitelist'
    ]);

}

$configs = [];

$stmt = $pdo->query("SELECT clau, valor FROM config_servidor");

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {

    $configs[$row['clau']] = $row['valor'];

}

?>

<!DOCTYPE html>
<html lang="ca">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Configuració - PiBlock</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>

        body {
            background-color: #121212;
            color: white;
            padding: 40px;
        }

        .box {
            background-color: #1f1f1f;
            padding: 30px;
            border-radius: 15px;
            max-width: 600px;
            margin: auto;
        }

    </style>

</head>
<body>

<div class="box">

    <h1>Configuració del servidor</h1>

    <form method="POST">

        <div class="mb-3">

            <label>Dificultat</label>

            <select name="dificultat" class="form-control">

                <option value="peaceful" <?= $configs['dificultat'] == 'peaceful' ? 'selected' : '' ?>>Peaceful</option>

                <option value="easy" <?= $configs['dificultat'] == 'easy' ? 'selected' : '' ?>>Easy</option>

                <option value="normal" <?= $configs['dificultat'] == 'normal' ? 'selected' : '' ?>>Normal</option>

                <option value="hard" <?= $configs['dificultat'] == 'hard' ? 'selected' : '' ?>>Hard</option>

            </select>

        </div>

        <div class="mb-3">

            <label>Gamemode</label>

            <select name="gamemode" class="form-control">

                <option value="survival" <?= $configs['gamemode'] == 'survival' ? 'selected' : '' ?>>Survival</option>

                <option value="creative" <?= $configs['gamemode'] == 'creative' ? 'selected' : '' ?>>Creative</option>

                <option value="adventure" <?= $configs['gamemode'] == 'adventure' ? 'selected' : '' ?>>Adventure</option>

            </select>

        </div>

        <div class="mb-3">

            <label>Whitelist</label>

            <select name="whitelist" class="form-control">

                <option value="on" <?= $configs['whitelist'] == 'on' ? 'selected' : '' ?>>ON</option>

                <option value="off" <?= $configs['whitelist'] == 'off' ? 'selected' : '' ?>>OFF</option>

            </select>

        </div>

        <button type="submit" class="btn btn-primary">
            Guardar configuració
        </button>

    </form>

    <br>

    <a href="dashboard.php" class="btn btn-secondary">
        Tornar al dashboard
    </a>

</div>

</body>
</html>