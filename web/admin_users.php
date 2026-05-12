<?php

require_once "auth.php";
require_once "db.php";

if ($_SESSION['rol'] !== 'admin') {
    die("Accés denegat");
}

$stmt = $pdo->query("SELECT id, username, rol FROM usuaris");

$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $newUser = trim($_POST['username']);
    $newPass = trim($_POST['password']);
    $newRole = trim($_POST['rol']);

    if (!empty($newUser) && !empty($newPass)) {

        $hash = password_hash($newPass, PASSWORD_DEFAULT);

        $insert = $pdo->prepare("
        INSERT INTO usuaris (username, password_hash, rol)
        VALUES (:username, :password_hash, :rol)
        ");

        $insert->execute([
            ':username' => $newUser,
            ':password_hash' => $hash,
            ':rol' => $newRole
        ]);

        header("Location: admin_users.php");
        exit();

    }

}

?>

<!DOCTYPE html>
<html lang="ca">
<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Gestió Usuaris</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

</head>

<body class="bg-dark text-white p-5">

<div class="container">

    <h1 class="mb-4">Gestió d'usuaris</h1>

    <a href="dashboard.php" class="btn btn-secondary mb-4">
        Tornar Dashboard
    </a>

    <div class="card bg-secondary text-white mb-4">

    <div class="card-body">

        <h3 class="mb-3">Crear usuari</h3>

        <form method="POST">

            <input
                type="text"
                name="username"
                class="form-control mb-3"
                placeholder="Nom usuari"
                required
            >

            <input
                type="password"
                name="password"
                class="form-control mb-3"
                placeholder="Contrasenya"
                required
            >

            <select name="rol" class="form-control mb-3">

                <option value="user">
                    User
                </option>

                <option value="admin">
                    Admin
                </option>

            </select>

            <button type="submit" class="btn btn-success w-100">
                Crear usuari
            </button>

        </form>

    </div>

</div>

    <table class="table table-dark table-striped">

        <thead>

            <tr>
                <th>ID</th>
                <th>Usuari</th>
                <th>Rol</th>
                <th>Accions</th>
            </tr>

        </thead>

        <tbody>

        <?php foreach($users as $user): ?>

            <tr>

                <td><?php echo $user['id']; ?></td>

                <td>
                    <?php echo htmlspecialchars($user['username']); ?>
                </td>

                <td>
                    <?php echo htmlspecialchars($user['rol']); ?>
                </td>

                <td>

                    <a href="delete_user.php?id=<?php echo $user['id']; ?>"
                       class="btn btn-danger btn-sm">

                        Eliminar

                    </a>

                </td>

            </tr>

        <?php endforeach; ?>

        </tbody>

    </table>

</div>

</body>
</html>
