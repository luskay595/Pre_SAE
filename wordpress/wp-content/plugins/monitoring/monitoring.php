<?php
/**
 * Plugin Name: Monitoring Anomalies
 * Description: Une interface de monitoring pour les anomalies.
 * Version: 1.0
 * Author: Votre Nom
 */
// Assurez-vous que ce fichier est appelé depuis WordPress
defined('ABSPATH') or die('No script kiddies please!');

// Connexion à la base de données
global $wpdb;

// Récupération des anomalies
function get_anomalies($server_type) {
    global $wpdb;
    return $wpdb->get_results($wpdb->prepare(
        "SELECT * FROM detected_anomalies WHERE server_type = %s ORDER BY detected_at DESC", 
        $server_type
    ));
}

// Traitement de la requête de rechargement des logs
if (isset($_POST['reload_logs'])) {
    $password = 'testpsswd'; // Remplacez par votre mot de passe
    $output = shell_exec("sshpass -p '$password' ssh root@172.150.0.5 'ruby /home/user/logs/execute_log_collection.rb'");
    echo "<script>alert('Logs rechargés avec succès : $output');</script>";
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Monitoring des Anomalies</title>
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
                <?php foreach ($anomalies as $anomaly): ?>
                    <tr>
                        <td><?= $anomaly->id ?></td>
                        <td><?= htmlspecialchars($anomaly->server_type) ?></td>
                        <td><?= htmlspecialchars($anomaly->anomaly_type) ?></td>
                        <td><?= htmlspecialchars($anomaly->details) ?></td>
                        <td><?= htmlspecialchars($anomaly->detected_at) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>

    <form action="" method="post">
        <input type="hidden" name="server" value="your_server_ip">
        <input type="submit" name="reload_logs" value="Recharger les logs">
    </form>
</body>
</html>
