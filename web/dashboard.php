<?php

require_once "auth.php";

$serverOnline = false;

$connection = @fsockopen("127.0.0.1", 80);

if ($connection) {

    $serverOnline = true;

    fclose($connection);

}


?>

<!DOCTYPE html>
<html lang="ca">

<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Dashboard - PiBlock</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

    <link rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">

    <link rel="stylesheet" href="style.css">

</head>

<body>

<nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow">

    <div class="container-fluid">

        <a class="navbar-brand d-flex align-items-center" href="#">

            PiBlock Dashboard

        </a>

        <div class="d-flex align-items-center text-white">

            <span class="me-3">

                Usuari:
                <strong>
                    <?php echo htmlspecialchars($_SESSION['username']); ?>
                </strong>

            </span>

            <a href="logout.php"
            class="btn btn-danger btn-sm">

                Logout

            </a>

        </div>

    </div>

</nav>

<div class="container mt-4">

    <div class="p-4 bg-dark rounded shadow welcome-box">

        <h2>

            Benvingut,
            <?php echo htmlspecialchars($_SESSION['username']); ?>

        </h2>

        <p class="text-secondary mb-0">

            Panel de control del sistema PiBlock

        </p>

    </div>

</div>

<div class="container mt-5">

    <div class="row g-4">

        <div class="col-md-4">

            <div class="card dashboard-card bg-dark text-white h-100">

                <div class="card-body">

                    <h3>
                        <i class="bi bi-hdd-network"></i>
                        Servidor
                    </h3>

                    <p>
                        Estat del servidor principal PiBlock.
                    </p>

<?php if($serverOnline): ?>

    <button class="btn btn-success w-100">

        Online

    </button>

<?php else: ?>

    <button class="btn btn-danger w-100">

        Offline

    </button>

<?php endif; ?>

                </div>

            </div>

        </div>

        <div class="col-md-4">

            <div class="card dashboard-card bg-dark text-white h-100">

                <div class="card-body">

                    <h3>
                        <i class="bi bi-gear"></i>
                        Configuració
                    </h3>

                    <p>
                        Configuració del servidor i serveis.
                    </p>

                    <a href="config.php"
                    class="btn btn-primary w-100 mb-3">

                        Obrir Configuració

                    </a>

                    <a href="admin_users.php"
                    class="btn btn-info w-100 mb-3">

                        Gestionar usuaris

                    </a>

                    <a href="logs.php"
                    class="btn btn-warning w-100">

                        Veure logs

                    </a>

                </div>

            </div>

        </div>

        <div class="col-md-4">

            <div class="card dashboard-card bg-dark text-white h-100">

                <div class="card-body">

                    <h3>
                        <i class="bi bi-controller"></i>
                        Pyrodactyl
                    </h3>

                    <p>
                        Accés al panel de servidors.
                    </p>

                    <a href="http://127.0.0.1/auth/login"
                    class="btn btn-danger w-100">

                        Obrir Panel

                    </a>

                </div>

            </div>

        </div>

    </div>

    <div class="row mt-4 g-4">

        <div class="col-md-6">

            <div class="card dashboard-card bg-dark text-white h-100">

                <div class="card-body">

                    <h3>
                        <i class="bi bi-person-circle"></i>
                        Informació Usuari
                    </h3>

                    <hr>

                    <p>

                        <strong>Nom:</strong>

                        <?php echo htmlspecialchars($_SESSION['username']); ?>

                    </p>

                    <p>

                        <strong>Rol:</strong>

                        <?php echo htmlspecialchars($_SESSION['rol']); ?>

                    </p>

                </div>

            </div>

        </div>

        <div class="col-md-6">

            <div class="card dashboard-card bg-dark text-white h-100">

                <div class="card-body">

                    <h3>
                        <i class="bi bi-pc-display"></i>
                        Projecte SMX
                    </h3>

                    <hr>

                    <p>
                        Sistema de gestió PiBlock desenvolupat amb:
                    </p>

                    <ul>

                        <li>PHP</li>
                        <li>MariaDB</li>
                        <li>Nginx</li>
                        <li>Ubuntu Server</li>
                        <li>Bootstrap</li>

                    </ul>

                </div>

            </div>

        </div>

    </div>

</div>

</body>
</html>
```
