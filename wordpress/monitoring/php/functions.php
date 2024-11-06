<?php
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
?>

