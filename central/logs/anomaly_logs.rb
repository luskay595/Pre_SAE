require 'mysql2'
require 'time'

# Configuration de la connexion à la base de données principale
DB_CONFIG = {
  host: 'db',
  username: 'root',
  password: 'root_password',
  database: 'logs_db' # Base de données des logs
}

# Connexion à la base de données principale
client = Mysql2::Client.new(DB_CONFIG)

# Création de la base de données anomalies si elle n'existe pas
anomaly_db_name = 'anomaly_logs'
begin
  client.query("CREATE DATABASE IF NOT EXISTS #{anomaly_db_name}")
rescue Mysql2::Error => e
  puts "Erreur lors de la création de la base de données : #{e.message}"
end

# Connexion à la nouvelle base de données
ANOMALY_DB_CONFIG = {
  host: 'db',
  username: 'root',
  password: 'root_password',
  database: anomaly_db_name # Base de données des anomalies
}

anomaly_client = Mysql2::Client.new(ANOMALY_DB_CONFIG)

# Création de la table pour stocker les anomalies si elle n'existe pas
create_table_query = <<-SQL
CREATE TABLE IF NOT EXISTS detected_anomalies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    server_type VARCHAR(50),
    anomaly_type VARCHAR(50),
    details TEXT,
    detected_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
SQL

begin
  anomaly_client.query(create_table_query)
rescue Mysql2::Error => e
  puts "Erreur lors de la création de la table des anomalies : #{e.message}"
end

def insert_anomaly(anomaly_client, server_type, anomaly_type, details)
  insert_query = "INSERT INTO detected_anomalies (server_type, anomaly_type, details) VALUES (?, ?, ?)"
  stmt = anomaly_client.prepare(insert_query)
  stmt.execute(server_type, anomaly_type, details)
end

def detect_web_server_errors(client, anomaly_client)
  # Erreurs serveur web : plus de 5 erreurs 500 en moins de 5 minutes
  query_500 = <<-SQL
    SELECT COUNT(*) AS error_count, 
           DATE_FORMAT(log_time, '%Y-%m-%d %H:%i') AS time_slot
    FROM apache_logs
    WHERE status_code = 500
    AND log_time >= NOW() - INTERVAL 5 MINUTE
    GROUP BY time_slot
    HAVING error_count > 5
  SQL

  results_500 = client.query(query_500)
  puts "Détection d'erreurs 500 : #{results_500.count} résultats trouvés."
  results_500.each do |row|
    details = "#{row['error_count']} erreurs 500 détectées à #{row['time_slot']}"
    insert_anomaly(anomaly_client, 'wordpress', 'Erreur 500', details)
    puts "Anomalie détectée : #{details}"
  end

  # Erreurs serveur web : plus de 5 erreurs 403 en moins de 5 minutes
  query_403 = <<-SQL
    SELECT COUNT(*) AS error_count, 
           DATE_FORMAT(log_time, '%Y-%m-%d %H:%i') AS time_slot
    FROM apache_logs
    WHERE status_code = 403
    AND log_time >= NOW() - INTERVAL 5 MINUTE
    GROUP BY time_slot
    HAVING error_count > 5
  SQL

  results_403 = client.query(query_403)
  puts "Détection d'erreurs 403 : #{results_403.count} résultats trouvés."
  results_403.each do |row|
    details = "#{row['error_count']} erreurs 403 détectées à #{row['time_slot']}"
    insert_anomaly(anomaly_client, 'wordpress', 'Erreur 403', details)
    puts "Anomalie détectée : #{details}"
  end
end

def detect_slow_queries(client, anomaly_client)
  # Requêtes lentes dans la base de données : toutes les requêtes dans la table ont déjà pris plus de 2 secondes
  query = <<-SQL
    SELECT COUNT(*) AS query_count, 
           DATE_FORMAT(log_time, '%Y-%m-%d %H:%i') AS time_slot
    FROM mariadb_slow_query_logs
    WHERE log_time >= NOW() - INTERVAL 1 HOUR
    GROUP BY time_slot
    HAVING query_count > 3
  SQL

  results = client.query(query)
  puts "Détection de requêtes lentes : #{results.count} résultats trouvés."
  results.each do |row|
    details = "#{row['query_count']} requêtes lentes détectées à #{row['time_slot']}"
    insert_anomaly(anomaly_client, 'sgbd', 'Requête lente', details)
    puts "Anomalie détectée : #{details}"
  end
end

def detect_high_cpu_usage_sgbd(client, anomaly_client)
  # Utilisation excessive du CPU : détecter des pics d'utilisation CPU
  cpu_query = <<-SQL
    SELECT log_time, log_message
    FROM mariadb_system_logs
    WHERE log_message LIKE '%Utilisation CPU élevée%'
  SQL

  results = client.query(cpu_query)
  puts "Détection d'utilisation CPU élevée : #{results.count} résultats trouvés."
  results.each do |row|
    details = row['log_message']
    insert_anomaly(anomaly_client, 'sgbd', 'Utilisation CPU élevée', details)
    puts "Anomalie détectée : #{details}"
  end
end
def detect_high_cpu_usage_wordpress(client, anomaly_client)
  # Utilisation excessive du CPU : détecter des pics d'utilisation CPU
  cpu_query = <<-SQL
    SELECT log_time, log_message
    FROM wordpress_system_logs
    WHERE log_message LIKE '%Utilisation CPU élevée%'
  SQL

  results = client.query(cpu_query)
  puts "Détection d'utilisation CPU élevée : #{results.count} résultats trouvés."
  results.each do |row|
    details = row['log_message']
    insert_anomaly(anomaly_client, 'wordpress', 'Utilisation CPU élevée', details)
    puts "Anomalie détectée : #{details}"
  end
end
def detect_failed_logins(client, anomaly_client)
  # Tentatives multiples de connexion échouées
  login_query = <<-SQL
    SELECT COUNT(*) AS failed_count, 
           DATE_FORMAT(log_time, '%Y-%m-%d %H:%i') AS time_slot
    FROM mariadb_error_logs
    WHERE log_message LIKE '%Access denied for user%'
    AND log_time >= NOW() - INTERVAL 5 MINUTE
    GROUP BY time_slot
    HAVING failed_count > 5
  SQL

  results = client.query(login_query)
  puts "Détection d'échecs de connexion : #{results.count} résultats trouvés."
  results.each do |row|
    details = "#{row['failed_count']} tentatives de connexion échouées à #{row['time_slot']}"
    insert_anomaly(anomaly_client, 'sgbd', 'Échecs de connexion', details)
    puts "Anomalie détectée : #{details}"
  end
end


def detect_rate_of_errors(client, anomaly_client)
  # Taux d'erreurs supérieur à 10% des requêtes dans une heure
  error_rate_query = <<-SQL
    SELECT COUNT(*) AS total_requests, 
           SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) AS error_count,
           DATE_FORMAT(log_time, '%Y-%m-%d %H:%i') AS time_slot
    FROM apache_logs
    WHERE log_time >= NOW() - INTERVAL 1 HOUR
    GROUP BY time_slot
    HAVING (error_count / total_requests) > 0.10
  SQL

  results = client.query(error_rate_query)
  puts "Détection de taux d'erreurs : #{results.count} résultats trouvés."
  results.each do |row|
    details = "#{row['error_count']} erreurs détectées sur #{row['total_requests']} requêtes à #{row['time_slot']}"
    insert_anomaly(anomaly_client, 'wordpress', 'Taux d\'erreurs élevé', details)
    puts "Anomalie détectée : #{details}"
  end
end

def detect_high_unique_requests(client, anomaly_client)
  # Nombre élevé de requêtes uniques : plus de 1000 dans une heure
  unique_requests_query = <<-SQL
    SELECT COUNT(DISTINCT remote_addr) AS unique_requests,
           DATE_FORMAT(log_time, '%Y-%m-%d %H:%i') AS time_slot
    FROM apache_logs
    WHERE log_time >= NOW() - INTERVAL 1 HOUR
    GROUP BY time_slot
    HAVING unique_requests > 1000
  SQL

  results = client.query(unique_requests_query)
  puts "Détection de requêtes uniques : #{results.count} résultats trouvés."
  results.each do |row|
    details = "#{row['unique_requests']} requêtes uniques détectées à #{row['time_slot']}"
    insert_anomaly(anomaly_client, 'wordpress', 'Nombre élevé de requêtes uniques', details)
    puts "Anomalie détectée : #{details}"
  end
end

# Appel des fonctions pour détecter les anomalies
detect_web_server_errors(client, anomaly_client)
detect_slow_queries(client, anomaly_client)
detect_high_cpu_usage_sgbd(client, anomaly_client)
detect_high_cpu_usage_wordpress(client, anomaly_client)
detect_failed_logins(client, anomaly_client)
detect_rate_of_errors(client, anomaly_client)
detect_high_unique_requests(client, anomaly_client)

# Fermeture des connexions
client.close
anomaly_client.close

