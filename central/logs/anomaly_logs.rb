#!/usr/bin/env ruby
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
    detected_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_anomaly (server_type, anomaly_type, details, detected_at) -- Index unique
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
SQL

begin
  anomaly_client.query(create_table_query)
rescue Mysql2::Error => e
  puts "Erreur lors de la création de la table des anomalies : #{e.message}"
end

def insert_anomaly(anomaly_client, server_type, anomaly_type, details)
  # Vérification de l'existence de l'anomalie
  check_query = <<-SQL
    SELECT COUNT(*) AS count FROM detected_anomalies
    WHERE server_type = ? AND anomaly_type = ? AND details = ? AND detected_at > NOW() - INTERVAL 5 MINUTE
  SQL

  stmt = anomaly_client.prepare(check_query)
  result = stmt.execute(server_type, anomaly_type, details)
  count = result.first['count']

  if count == 0
    # Insérer l'anomalie uniquement si elle n'existe pas
    insert_query = "INSERT INTO detected_anomalies (server_type, anomaly_type, details) VALUES (?, ?, ?)"
    stmt = anomaly_client.prepare(insert_query)
    stmt.execute(server_type, anomaly_type, details)
  else
    puts "Anomalie déjà enregistrée : #{details}"
  end
end


# Détection d'erreurs 500 répétées avec moins de 5 minutes d'intervalle
def detect_web_server_errors(client, anomaly_client)
  query = <<-SQL
    SELECT status_code, log_time 
    FROM apache_logs
    WHERE status_code = 500
    ORDER BY log_time ASC
  SQL

  results = client.query(query)
  errors = []
  last_time = nil

  results.each do |row|
    log_time = row['log_time'] # Utilisation directe de log_time sans Time.parse
    if last_time.nil? || (log_time - last_time) > 300 # plus de 5 minutes
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


# Détection de requêtes lentes (plus de 2 secondes) répétées au moins 5 fois
# Détection de requêtes lentes (plus de 2 secondes) répétées au moins 5 fois
def detect_slow_queries(client, anomaly_client)
  # Sélection de toutes les requêtes lentes dans l'ordre de leur log_time
  query = <<-SQL
    SELECT log_time, host, query
    FROM mariadb_slow_query_logs
    ORDER BY log_time ASC
  SQL

  results = client.query(query)
  slow_queries = []

  results.each do |row|
    log_time = row['log_time']

    # Si le tableau est vide, on initialise avec la première entrée
    slow_queries << row if slow_queries.empty?

    # Vérification avant d'accéder à slow_queries.first
    if slow_queries.any?
      # Tant que le temps écoulé entre la première et la dernière requête dépasse 5 minutes, on vide la liste
      while slow_queries.any? && (log_time - slow_queries.first['log_time']) > 300 # 300 secondes = 5 minutes
        slow_queries.shift
      end
    end

    # Ajouter la requête actuelle
    slow_queries << row

    # Si nous avons plus de 5 requêtes lentes dans un intervalle de 5 minutes, détecter une anomalie
    if slow_queries.size >= 5
      details = "#{slow_queries.size} requêtes lentes détectées entre #{slow_queries.first['log_time']} et #{slow_queries.last['log_time']} pour les hôtes #{slow_queries.map { |q| q['host'] }.uniq.join(', ')}"
      insert_anomaly(anomaly_client, 'sgbd', 'Requêtes lentes', details)
      puts "Anomalie détectée : #{details}"

      # On ne vide pas tout slow_queries, on conserve la dernière requête pour continuer
      slow_queries = [slow_queries.last]
    end
  end
end




# Détection de pics d'utilisation CPU dans les logs
def detect_high_cpu_usage(client, anomaly_client, log_table, server_type)
  query = <<-SQL
    SELECT log_time, log_message
    FROM #{log_table}
    WHERE log_message LIKE '%Utilisation CPU élevée%'
  SQL

  results = client.query(query)
  results.each do |row|
    details = row['log_message']
    insert_anomaly(anomaly_client, server_type, 'Utilisation CPU élevée', details)
    puts "Anomalie détectée : #{details}"
  end
end

def detect_failed_logins(client, anomaly_client)
  query = <<-SQL
    SELECT log_time, log_message
    FROM mariadb_error_logs
    WHERE log_message LIKE '%Access denied for user%'
  SQL

  results = client.query(query)

  results.each do |row|
    log_message = row['log_message']
    log_time = row['log_time']
    
    # Extraire le nom d'utilisateur et l'adresse IP à partir du log_message
    if log_message =~ /Access denied for user '([^']+)'@'([^']+)'/
      user = $1
      ip_address = $2
      details = "Accès refusé pour l'utilisateur '#{user}' à partir de l'adresse IP '#{ip_address}' à #{log_time}"

      # Insérer l'anomalie
      insert_anomaly(anomaly_client, 'sgbd', 'Échec de connexion', details)
      puts "Anomalie détectée : #{details}"
    end
  end
end

# Appel des fonctions pour détecter les anomalies
detect_web_server_errors(client, anomaly_client)
detect_slow_queries(client, anomaly_client)
detect_high_cpu_usage(client, anomaly_client, 'mariadb_system_logs', 'sgbd')
detect_high_cpu_usage(client, anomaly_client, 'wordpress_system_logs', 'wordpress')
detect_failed_logins(client, anomaly_client)

# Fermeture des connexions
client.close
anomaly_client.close

