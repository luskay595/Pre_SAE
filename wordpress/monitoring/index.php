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

// Récupération des anomalies avec filtrage
function get_anomalies($server_type, $anomaly_type) {
    global $anomaly_client;
    $query = "SELECT * FROM detected_anomalies WHERE 1=1";
    $params = [];
    $types = '';

    if ($server_type) {
        $query .= " AND server_type = ?";
        $params[] = $server_type;
        $types .= 's';
    }

    if ($anomaly_type) {
        $query .= " AND anomaly_type = ?";
        $params[] = $anomaly_type;
        $types .= 's';
    }

    $query .= " ORDER BY detected_at DESC";

    $stmt = $anomaly_client->prepare($query);
    if ($types) {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    return $stmt->get_result();
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monitoring des Anomalies</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            color: #333;
            margin: 0;
            padding: 0;
        }
        .container {
            width: 90%;
            margin: auto;
            padding: 20px;
            background-color: white;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            text-align: center;
            color: #007BFF;
        }
        form {
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        form label, form select {
            margin-right: 10px;
        }
        form input[type="submit"] {
            padding: 10px 20px;
            background-color: #007BFF;
            color: white;
            border: none;
            cursor: pointer;
        }
        form input[type="submit"]:hover {
            background-color: #0056b3;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table th, table td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }
        table th {
            background-color: #f2f2f2;
            color: #333;
        }
        table tr:nth-child(even) {
            background-color: #f9f9f9;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Monitoring des Anomalies</h1>
        <form action="" method="post">
            <div>
                <label for="server_type">Sélectionnez un serveur :</label>
                <select name="server_type" id="server_type">
                    <option value="">Tous les serveurs</option>
                    <option value="wordpress">WordPress</option>
                    <option value="sgbd">SGDB</option>
                </select>
            </div>
            <div>
                <label for="anomaly_type">Sélectionnez un type d'anomalie :</label>
                <select name="anomaly_type" id="anomaly_type">
                    <option value="">Tous les types</option>
                    <option value="Utilisation CPU élevée">Utilisation CPU élevée</option>
                    <option value="Échec de connexion">Échec de connexion</option>
                    <option value="Erreur 500">Erreur 500</option>
                    <option value="Requêtes lentes">Requêtes lentes</option> <!-- New option added -->
                </select>
            </div>
            <input type="submit" value="Afficher les anomalies">
        </form>

        <?php if ($_SERVER['REQUEST_METHOD'] === 'POST'): ?>
            <?php
                $server_type = $_POST['server_type'] ?? '';
                $anomaly_type = $_POST['anomaly_type'] ?? '';
                $anomalies = get_anomalies($server_type, $anomaly_type);
            ?>
            <h2>Anomalies</h2>
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
                    <?php if ($anomalies->num_rows > 0): ?>
                        <?php while ($anomaly = $anomalies->fetch_assoc()): ?>
                            <tr>
                                <td><?= $anomaly['id'] ?></td>
                                <td><?= htmlspecialchars($anomaly['server_type']) ?></td>
                                <td><?= htmlspecialchars($anomaly['anomaly_type']) ?></td>
                                <td><?= htmlspecialchars($anomaly['details']) ?></td>
                                <td><?= htmlspecialchars($anomaly['detected_at']) ?></td>
                            </tr>
                        <?php endwhile; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="5" style="text-align: center;">Aucune anomalie trouvée.</td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        <?php endif; ?>
    </div>
</body>
</html>

<?php
$anomaly_client->close();
?>

