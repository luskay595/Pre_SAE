#!/usr/bin/env ruby
require 'mysql2'
require 'time'
require 'dotenv/load'  # Charger les variables d'environnement

# Configuration de la connexion à la base de données principale des logs
LOGS_DB_CONFIG = {
  host: ENV['DB_HOST'],
  username: ENV['DB_USER_LOGS'],
  password: ENV['DB_PASSWORD_LOGS'],
  database: 'logs_db' # Base de données des logs
}

# Connexion à la base de données principale des logs
logs_client = Mysql2::Client.new(LOGS_DB_CONFIG)

# Configuration de la connexion à la base de données des anomalies
ANOMALY_DB_CONFIG = {
  host: ENV['DB_HOST'],
  username: ENV['DB_USER_ANOMALY'],
  password: ENV['DB_PASSWORD_ANOMALY'],
  database: 'anomaly_logs' # Base de données des anomalies
}

# Connexion à la base de données des anomalies
anomaly_client = Mysql2::Client.new(ANOMALY_DB_CONFIG)

# Création de la table pour stocker les anomalies si elle n'existe pas
create_table_query = <<-SQL
CREATE TABLE IF NOT EXISTS detected_anomalies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    server_type VARCHAR(50),
    anomaly_type VARCHAR(50),
    details TEXT,
    detected_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_anomaly (server_type, anomaly_type, details, detected_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
SQL

begin
  anomaly_client.query(create_table_query)
rescue Mysql2::Error => e
  puts "Erreur lors de la création de la table des anomalies : #{e.message}"
end

# Fonction d'insertion d'anomalie dans la base de données anomalies
def insert_anomaly(anomaly_client, server_type, anomaly_type, details)
  check_query = <<-SQL
    SELECT COUNT(*) AS count FROM detected_anomalies
    WHERE server_type = ? AND anomaly_type = ? AND details = ? AND detected_at > NOW() - INTERVAL 5 MINUTE
  SQL

  stmt = anomaly_client.prepare(check_query)
  result = stmt.execute(server_type, anomaly_type, details)
  count = result.first['count']

  if count == 0
    insert_query = "INSERT INTO detected_anomalies (server_type, anomaly_type, details) VALUES (?, ?, ?)"
    stmt = anomaly_client.prepare(insert_query)
    stmt.execute(server_type, anomaly_type, details)
  else
    puts "Anomalie déjà enregistrée : #{details}"
  end
end

# Fonction pour détecter les erreurs 500 répétées dans les logs Apache
def detect_web_server_errors(logs_client, anomaly_client)
  query = <<-SQL
    SELECT status_code, log_time 
    FROM apache_logs
    WHERE status_code = 500
    ORDER BY log_time ASC
  SQL

  results = logs_client.query(query)
  errors = []
  last_time = nil

  results.each do |row|
    log_time = row['log_time']
    if last_time.nil? || (log_time - last_time) > 300
      errors = [log_time]
    else
      errors << log_time
      if errors.size > 5
        details = "#{errors.size} erreurs 500 détectées entre #{errors.first} et #{errors.last}"
        insert_anomaly(anomaly_client, 'wordpress', 'Erreur 500', details)
        puts "Anomalie détectée : #{details}"
        errors.clear
      end
    end
    last_time = log_time
  end
end

# Fonction pour détecter les requêtes lentes répétées dans les logs MariaDB
def detect_slow_queries(logs_client, anomaly_client)
  query = <<-SQL
    SELECT log_time, host, query
    FROM mariadb_slow_query_logs
    ORDER BY log_time ASC
  SQL

  results = logs_client.query(query)
  slow_queries = []

  results.each do |row|
    log_time = row['log_time']
    slow_queries << row if slow_queries.empty?

    if slow_queries.any?
      while slow_queries.any? && (log_time - slow_queries.first['log_time']) > 300
        slow_queries.shift
      end
    end

    slow_queries << row

    if slow_queries.size >= 5
      details = "#{slow_queries.size} requêtes lentes détectées entre #{slow_queries.first['log_time']} et #{slow_queries.last['log_time']} pour les hôtes #{slow_queries.map { |q| q['host'] }.uniq.join(', ')}"
      insert_anomaly(anomaly_client, 'sgbd', 'Requêtes lentes', details)
      puts "Anomalie détectée : #{details}"
      slow_queries = [slow_queries.last]
    end
  end
end

# Fonction pour détecter les pics d'utilisation CPU
def detect_high_cpu_usage(logs_client, anomaly_client, log_table, server_type)
  query = <<-SQL
    SELECT log_time, log_message
    FROM #{log_table}
    WHERE log_message LIKE '%Utilisation CPU élevée%'
  SQL

  results = logs_client.query(query)
  results.each do |row|
    details = row['log_message']
    insert_anomaly(anomaly_client, server_type, 'Utilisation CPU élevée', details)
    puts "Anomalie détectée : #{details}"
  end
end

# Fonction pour détecter les échecs de connexion
def detect_failed_logins(logs_client, anomaly_client)
  query = <<-SQL
    SELECT log_time, log_message
    FROM mariadb_error_logs
    WHERE log_message LIKE '%Access denied for user%'
  SQL

  results = logs_client.query(query)

  results.each do |row|
    log_message = row['log_message']
    log_time = row['log_time']

    if log_message =~ /Access denied for user '([^']+)'@'([^']+)'/
      user = $1
      ip_address = $2
      details = "Accès refusé pour l'utilisateur '#{user}' à partir de l'adresse IP '#{ip_address}' à #{log_time}"
      insert_anomaly(anomaly_client, 'sgbd', 'Échec de connexion', details)
      puts "Anomalie détectée : #{details}"
    end
  end
end

def detect_403_errors(logs_client, anomaly_client)
  query = <<-SQL
    SELECT status_code, log_time 
    FROM apache_logs
    WHERE status_code = 403
    ORDER BY log_time ASC
  SQL

  results = logs_client.query(query)
  errors = []
  last_time = nil

  results.each do |row|
    log_time = row['log_time']
    if last_time.nil? || (log_time - last_time) > 300
      errors = [log_time]
    else
      errors << log_time
      if errors.size > 5
        details = "#{errors.size} erreurs 403 détectées entre #{errors.first} et #{errors.last}"
        insert_anomaly(anomaly_client, 'wordpress', 'Erreur 403', details)
        puts "Anomalie détectée : #{details}"
        errors.clear
      end
    end
    last_time = log_time
  end
end




# Appel des fonctions pour détecter les anomalies
detect_web_server_errors(logs_client, anomaly_client)
detect_slow_queries(logs_client, anomaly_client)
detect_high_cpu_usage(logs_client, anomaly_client, 'mariadb_system_logs', 'sgbd')
detect_high_cpu_usage(logs_client, anomaly_client, 'wordpress_system_logs', 'wordpress')
detect_failed_logins(logs_client, anomaly_client)
detect_403_errors(logs_client, anomaly_client)

# Fermeture des connexions
logs_client.close
anomaly_client.close

