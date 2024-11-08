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

// Fonction pour récupérer les anomalies en fonction des filtres sélectionnés
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
            cursor: pointer;
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

        // Mise à jour des options d'anomalie en fonction du type de serveur
        function updateAnomalyOptions() {
            const serverType = document.getElementById('server_type').value;
            const anomalyType = document.getElementById('anomaly_type');
            
            // Réinitialiser les options
            anomalyType.innerHTML = '<option value="">Tous les types</option>';

            if (serverType === 'wordpress') {
                anomalyType.innerHTML += `
                    <option value="Utilisation CPU élevée">Utilisation CPU élevée</option>
                    <option value="Erreur 500">Erreur 500</option>
                    <option value="Erreur 403">Erreur 403</option>
                `;
            } else if (serverType === 'sgbd') {
                anomalyType.innerHTML += `
                    <option value="Utilisation CPU élevée">Utilisation CPU élevée</option>
                    <option value="Échec de connexion">Échec de connexion</option>
                    <option value="Requêtes lentes">Requêtes lentes</option>
                `;
            } else {
                anomalyType.innerHTML += `
                    <option value="Utilisation CPU élevée">Utilisation CPU élevée</option>
                    <option value="Erreur 500">Erreur 500</option>
                    <option value="Erreur 403">Erreur 403</option>
                    <option value="Échec de connexion">Échec de connexion</option>
                    <option value="Requêtes lentes">Requêtes lentes</option>
                `;
            }
        }

        // Fonction de tri des colonnes du tableau avec tri croissant et décroissant
        let sortDirections = [true, true, true, true]; // Initialiser les directions pour chaque colonne

        function sortTable(n) {
            const table = document.getElementById("anomaliesTable");
            let rows, switching, i, x, y, shouldSwitch;
            switching = true;
            const dir = sortDirections[n] ? "asc" : "desc"; // Récupérer la direction de tri
            sortDirections[n] = !sortDirections[n]; // Inverser la direction de tri pour la prochaine fois

            while (switching) {
                switching = false;
                rows = table.rows;
                for (i = 1; i < (rows.length - 1); i++) {
                    shouldSwitch = false;
                    x = rows[i].getElementsByTagName("TD")[n];
                    y = rows[i + 1].getElementsByTagName("TD")[n];
                    
                    if (dir === "asc" && x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
                        shouldSwitch = true;
                        break;
                    } else if (dir === "desc" && x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
                        shouldSwitch = true;
                        break;
                    }
                }
                if (shouldSwitch) {
                    rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                    switching = true;
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
                    <option value="sgbd" <?= $server_type == 'sgbd' ? 'selected' : '' ?>>SGBD</option>
                </select>
            </div>
            <div>
                <label for="anomaly_type">Sélectionnez un type d'anomalie :</label>
                                <select name="anomaly_type" id="anomaly_type">
                    <option value="">Tous les types</option>
                    <?php foreach ($anomaly_counts as $type => $count): ?>
                        <option value="<?= $type ?>" <?= $anomaly_type == $type ? 'selected' : '' ?>><?= $type ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <input type="submit" value="Filtrer">
        </form>

        <!-- Affichage du graphique -->
        <div style="width: 100%; height: 300px;">
            <canvas id="anomalyChart"></canvas>
        </div>

        <!-- Tableau des anomalies -->
        <table id="anomaliesTable">
            <thead>
                <tr>
                    <th onclick="sortTable(0)">ID</th>
                    <th onclick="sortTable(1)">Type d'anomalie</th>
                    <th onclick="sortTable(2)">Serveur</th>
                    <th onclick="sortTable(3)">Date de détection</th>
                </tr>
            </thead>
            <tbody>
                <?php if ($anomalies->num_rows > 0): ?>
                    <?php while ($row = $anomalies->fetch_assoc()): ?>
                        <tr>
                            <td><?= $row['id'] ?></td>
                            <td><?= $row['anomaly_type'] ?></td>
                            <td><?= $row['server_type'] ?></td>
                            <td><?= $row['detected_at'] ?></td>
                        </tr>
                    <?php endwhile; ?>
                <?php else: ?>
                    <tr>
                        <td colspan="4">Aucune anomalie trouvée.</td>
                    </tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</body>
</html>


