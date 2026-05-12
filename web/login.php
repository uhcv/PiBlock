<?php

session_start();

require_once "db.php";

$error = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $username = trim($_POST["username"]);
    $password = trim($_POST["password"]);

    if (!empty($username) && !empty($password)) {

        $stmt = $pdo->prepare("
            SELECT id, username, password_hash, rol
            FROM usuaris
            WHERE username = :user
        ");

        $stmt->execute([
            ':user' => $username
        ]);

        $userData = $stmt->fetch(PDO::FETCH_ASSOC);

if ($userData && password_verify($password, $userData['password_hash'])) {

    $_SESSION['user_id'] = $userData['id'];
    $_SESSION['username'] = $userData['username'];
    $_SESSION['rol'] = $userData['rol'];
    $log = $pdo->prepare("
    INSERT INTO logs (username, action)
    VALUES (:username, :action)
    ");

$log->execute([
    ':username' => $userData['username'],
    ':action' => 'Login correcte'
]);
    
    header("Location: dashboard.php");
    exit();

} else {

    $error = "Usuari o contrasenya incorrectes";

}

    } else {

        $error = "Omple tots els camps";

    }

}
?>

<!DOCTYPE html>
<html lang="ca">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - PiBlock</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>

        body {
            background-color: #121212;
            color: white;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: Arial, sans-serif;
        }

        .login-box {
            background-color: #1f1f1f;
            padding: 40px;
            border-radius: 15px;
            width: 400px;
            box-shadow: 0 0 20px rgba(0,0,0,0.5);
        }

        .login-box h1 {
            text-align: center;
            margin-bottom: 30px;
        }

        .form-control {
            margin-bottom: 20px;
        }

        .btn-login {
            width: 100%;
        }

        .error {
            color: red;
            text-align: center;
            margin-bottom: 15px;
        }

    </style>

</head>
<body>

<div class="login-box">

    <h1>PiBlock Login</h1>

    <?php if(!empty($error)): ?>

        <div class="error">
            <?php echo htmlspecialchars($error); ?>
        </div>

    <?php endif; ?>

    <form method="POST">

        <input
            type="text"
            name="username"
            class="form-control"
            placeholder="Usuari"
            required
        >

        <input
            type="password"
            name="password"
            class="form-control"
            placeholder="Contrasenya"
            required
        >

        <button type="submit" class="btn btn-primary btn-login">
            Iniciar Sessió
        </button>

        <br><br>

        <a href="register.php" class="btn btn-danger w-100">
            Registrar-se
        </a>

    </form>

</div>

</body>
</html>