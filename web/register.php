<?php

require_once "db.php";

$message = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $username = trim($_POST["username"]);
    $password = trim($_POST["password"]);
    $invite = trim($_POST["invite_code"]);

    if (!empty($username) && !empty($password) && !empty($invite)) {

        // Buscar autorización

        $stmt = $pdo->prepare("
            SELECT * FROM authorized_users
            WHERE username = :username
            AND invite_code = :invite
            AND used = 0
        ");

        $stmt->execute([
            ':username' => $username,
            ':invite' => $invite
        ]);

        $authorized = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($authorized) {

            // Comprobar si ya existe usuario

            $check = $pdo->prepare("
                SELECT id FROM usuaris
                WHERE username = :username
            ");

            $check->execute([
                ':username' => $username
            ]);

            if ($check->fetch()) {

                $message = "Aquest usuari ja existeix.";

            } else {

                // Crear hash

                $hash = password_hash($password, PASSWORD_DEFAULT);

                // Insertar usuario

                $insert = $pdo->prepare("
                    INSERT INTO usuaris
                    (username, password_hash, rol)
                    VALUES
                    (:username, :password_hash, 'professor')
                ");

                $insert->execute([
                    ':username' => $username,
                    ':password_hash' => $hash
                ]);

                // Marcar invitación usada

                $update = $pdo->prepare("
                    UPDATE authorized_users
                    SET used = 1
                    WHERE id = :id
                ");

                $update->execute([
                    ':id' => $authorized['id']
                ]);

                $message = "Usuari registrat correctament.";

            }

        } else {

            $message = "Codi o usuari incorrectes.";

        }

    } else {

        $message = "Omple tots els camps.";

    }

}
?>

<!DOCTYPE html>
<html lang="ca">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register - PiBlock</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>

        body {
            background-color: #121212;
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }

        .box {
            background-color: #1f1f1f;
            padding: 40px;
            border-radius: 15px;
            width: 400px;
        }

    </style>

</head>
<body>

<div class="box">

    <h1>Register</h1>

    <?php if(!empty($message)): ?>

        <div class="alert alert-info">
            <?php echo htmlspecialchars($message); ?>
        </div>

    <?php endif; ?>

    <form method="POST">

        <input
            type="text"
            name="username"
            class="form-control mb-3"
            placeholder="Usuari"
            required
        >

        <input
            type="password"
            name="password"
            class="form-control mb-3"
            placeholder="Contrasenya"
            required
        >

        <input
            type="text"
            name="invite_code"
            class="form-control mb-3"
            placeholder="Codi invitació"
            required
        >

        <button type="submit" class="btn btn-success w-100">
            Registrar
        </button>

    </form>

    <br>

    <a href="login.php" class="btn btn-secondary w-100">
        Tornar al login
    </a>

</div>

</body>
</html>