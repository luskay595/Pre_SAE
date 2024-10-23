<?php
// Connexion à la base de données
$DB_CONFIG = [
    'host' => 'db',
    'username' => 'root',
    'password' => 'root_password',
    'database' => 'logs_db' // Base de données des logs
];

$anomaly_db_name = 'anomaly_logs';
$anomaly_client = new mysqli($DB_CONFIG['host'], $DB_CONFIG['username'], $DB_CONFIG['password'], $anomaly_db_name);

if ($anomaly_client->connect_error) {
    die("Connection failed: " . $anomaly_client->connect_error);
}

// Récupération des anomalies
function get_anomalies($server_type) {
    global $anomaly_client;
    $stmt = $anomaly_client->prepare("SELECT * FROM detected_anomalies WHERE server_type = ? ORDER BY detected_at DESC");
    $stmt->bind_param("s", $server_type);
    $stmt->execute();
    return $stmt->get_result();
}

// Traitement de la requête de rechargement des logs
if (isset($_POST['reload_logs'])) {
    $password = 'your_password'; // Remplacez par votre mot de passe
    $output = shell_exec("sshpass -p '$password' ssh root@172.150.0.5 'ruby /home/user/logs/execute_log_collection.rb'");
    echo "<script>alert('Logs rechargés avec succès : $output');</script>";
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monitoring des Anomalies</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Monitoring des Anomalies</h1>
    <form action="" method="post">
        <label for="server_type">Sélectionnez un serveur :</label>
        <select name="server_type" id="server_type">
            <option value="wordpress">WordPress</option>
            <option value="sgbd">SGDB</option>
        </select>
        <input type="submit" value="Afficher les anomalies">
    </form>

    <?php if (isset($_POST['server_type'])): ?>
        <?php
            $server_type = $_POST['server_type'];
            $anomalies = get_anomalies($server_type);
        ?>
        <h2>Anomalies pour <?= htmlspecialchars($server_type) ?></h2>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Type de serveur</th>
                    <th>Type d'anomalie</th>
                    <th>Détails</th>
                    <th>Date de détection</th>
                </tr>
            </thead>
            <tbody>
                <?php while ($anomaly = $anomalies->fetch_assoc()): ?>
                    <tr>
                        <td><?= $anomaly['id'] ?></td>
                        <td><?= htmlspecialchars($anomaly['server_type']) ?></td>
                        <td><?= htmlspecialchars($anomaly['anomaly_type']) ?></td>
                        <td><?= htmlspecialchars($anomaly['details']) ?></td>
                        <td><?= htmlspecialchars($anomaly['detected_at']) ?></td>
                    </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    <?php endif; ?>

    <form action="" method="post">
        <input type="hidden" name="server" value="your_server_ip">
        <input type="submit" name="reload_logs" value="Recharger les logs">
    </form>
</body>
</html>

<?php
$anomaly_client->close();
?>
