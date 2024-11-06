<?php
// Activer l'affichage des erreurs pour le débogage
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Connexion à la base de données anomaly_logs
$DB_CONFIG = [
    'host' => 'db', // Vérifiez cet hôte (ex. localhost, 127.0.0.1, ou autre)
    'username' => 'root',
    'password' => 'root_password',
    'database' => 'anomaly_logs'
];

$anomaly_client = new mysqli($DB_CONFIG['host'], $DB_CONFIG['username'], $DB_CONFIG['password'], $DB_CONFIG['database']);
if ($anomaly_client->connect_error) {
    die("Échec de la connexion : " . $anomaly_client->connect_error);
}

// Fonction pour récupérer les anomalies
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

// Fonction pour obtenir le nombre d'anomalies par type
function get_anomaly_counts() {
    global $anomaly_client;
    $query = "SELECT anomaly_type, COUNT(*) AS count FROM detected_anomalies GROUP BY anomaly_type";
    $result = $anomaly_client->query($query);

    $anomaly_counts = [];
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $anomaly_counts[$row['anomaly_type']] = $row['count'];
        }
    }
    return $anomaly_counts;
}

// Récupérer les données des formulaires
$server_type = $_POST['server_type'] ?? '';
$anomaly_type = $_POST['anomaly_type'] ?? '';
$anomalies = get_anomalies($server_type, $anomaly_type);
$anomaly_counts = get_anomaly_counts();
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monitoring des Anomalies</title>
    <style>
        /* Styles CSS simplifiés */
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
            cursor: pointer; /* Indique que les colonnes sont cliquables */
        }
        table tr:nth-child(even) {
            background-color: #f9f9f9;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        // Graphique avec Chart.js
        window.onload = function() {
            const anomalyCounts = <?= json_encode($anomaly_counts) ?>;
            const ctx = document.getElementById('anomalyChart').getContext('2d');
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: Object.keys(anomalyCounts),
                    datasets: [{
                        label: 'Nombre d\'anomalies',
                        data: Object.values(anomalyCounts),
                        backgroundColor: 'rgba(0, 123, 255, 0.5)',
                        borderColor: 'rgba(0, 123, 255, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
        };

        // Fonction de tri des colonnes du tableau
        function sortTable(n, table) {
            let rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
            switching = true;
            dir = "asc"; // Tri croissant par défaut
            while (switching) {
                switching = false;
                rows = table.rows;
                for (i = 1; i < (rows.length - 1); i++) {
                    shouldSwitch = false;
                    x = rows[i].getElementsByTagName("TD")[n];
                    y = rows[i + 1].getElementsByTagName("TD")[n];
                    if (dir === "asc") {
                        if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
                            shouldSwitch = true;
                            break;
                        }
                    } else if (dir === "desc") {
                        if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
                            shouldSwitch = true;
                            break;
                        }
                    }
                }
                if (shouldSwitch) {
                    rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                    switching = true;
                    switchcount++;
                } else {
                    if (switchcount === 0 && dir === "asc") {
                        dir = "desc";
                        switching = true;
                    }
                }
            }
        }
    </script>
</head>
<body>
    <div class="container">
        <h1>Monitoring des Anomalies</h1>
        <form action="" method="post">
            <div>
                <label for="server_type">Sélectionnez un serveur :</label>
                <select name="server_type" id="server_type" onchange="updateAnomalyOptions()">
                    <option value="">Tous les serveurs</option>
                    <option value="wordpress" <?= $server_type == 'wordpress' ? 'selected' : '' ?>>WordPress</option>
                    <option value="sgbd" <?= $server_type == 'sgbd' ? 'selected' : '' ?>>SGDB</option>
                </select>
            </div>
            <div>
                <label for="anomaly_type">Sélectionnez un type d'anomalie :</label>
                <select name="anomaly_type" id="anomaly_type">
                    <option value="">Tous les types</option>
                    <option value="Utilisation CPU élevée" <?= $anomaly_type == 'Utilisation CPU élevée' ? 'selected' : '' ?>>Utilisation CPU élevée</option>
                    <option value="Échec de connexion" <?= $anomaly_type == 'Échec de connexion' ? 'selected' : '' ?>>Échec de connexion</option>
                    <option value="Erreur 500" <?= $anomaly_type == 'Erreur 500' ? 'selected' : '' ?>>Erreur 500</option>
                    <option value="Requêtes lentes" <?= $anomaly_type == 'Requêtes lentes' ? 'selected' : '' ?>>Requêtes lentes</option>
                </select>
            </div>
            <input type="submit" value="Afficher les anomalies">
        </form>

        <h2>Anomalies</h2>
        <table id="anomalyTable">
            <thead>
                <tr>
                    <th onclick="sortTable(0, this.closest('table'))">ID</th>
                    <th onclick="sortTable(1, this.closest('table'))">Type de serveur</th>
                    <th onclick="sortTable(2, this.closest('table'))">Type d'anomalie</th>
                    <th onclick="sortTable(3, this.closest('table'))">Détails</th>
                    <th onclick="sortTable(4, this.closest('table'))">Date de détection</th>
                </tr>
            </thead>
            <tbody>
                <?php if ($anomalies->num_rows > 0): ?>
                    <?php while ($anomaly = $anomalies->fetch_assoc()): ?>
                        <tr>
                            <td><?= htmlspecialchars($anomaly['id']) ?></td>
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

        <h2>Statistiques des Anomalies</h2>
        <canvas id="anomalyChart"></canvas>
    </div>
</body>
</html>

