<?php
$DB_CONFIG = [
    'host' => 'db', // Vérifiez cet hôte (ex. localhost, 127.0.0.1, ou autre)
    'username' => 'rootmaispastrop',
    'password' => 'securepassword',
    'database' => 'anomaly_logs'
];

// Connexion à la base de données
$anomaly_client = new mysqli($DB_CONFIG['host'], $DB_CONFIG['username'], $DB_CONFIG['password'], $DB_CONFIG['database']);
if ($anomaly_client->connect_error) {
    die("Échec de la connexion : " . $anomaly_client->connect_error);
}
?>

