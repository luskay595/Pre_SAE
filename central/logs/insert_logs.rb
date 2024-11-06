#!/usr/bin/env ruby
require 'mysql2'
require 'date'
require 'dotenv/load'  # Load environment variables from .env file

# Configuration de la connexion à MariaDB
client = Mysql2::Client.new(
  host: ENV['DB_HOST'],
  username: ENV['DB_USER_LOGS'],
  password: ENV['DB_PASSWORD_LOGS'],
)

# Création de la base de données si elle n'existe pas
client.query("CREATE DATABASE IF NOT EXISTS #{ENV['DB_DATABASE']};")
client.query("USE #{ENV['DB_DATABASE']};")

# Création des tables pour les logs si elles n'existent pas déjà
client.query <<-SQL
  CREATE TABLE IF NOT EXISTS wordpress_system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_time DATETIME,
    log_message TEXT,
    UNIQUE(log_time, log_message)
  );
SQL

client.query <<-SQL
  CREATE TABLE IF NOT EXISTS apache_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    remote_addr VARCHAR(45),
    log_time DATETIME,
    request_method VARCHAR(10),
    request_uri TEXT,
    http_version VARCHAR(10),
    status_code INT,
    response_size INT,
    referer TEXT,
    user_agent TEXT,
    UNIQUE(remote_addr, log_time, request_uri, status_code)
  );
SQL

client.query <<-SQL
  CREATE TABLE IF NOT EXISTS mariadb_system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_time DATETIME,
    log_message TEXT,
    UNIQUE(log_time, log_message)
  );
SQL

client.query <<-SQL
  CREATE TABLE IF NOT EXISTS mariadb_error_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_time DATETIME,
    log_message TEXT,
    UNIQUE(log_time, log_message)
  );
SQL

client.query <<-SQL
CREATE TABLE IF NOT EXISTS mariadb_slow_query_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  log_time DATETIME,
  host VARCHAR(100),
  query TEXT,
  UNIQUE(log_time, host, query)
);
SQL

# Creating log tables if they don't already exist
client.query <<-SQL
  CREATE TABLE IF NOT EXISTS mariadb_general_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_time DATETIME,
    query_number INT,   -- Ensure this column is created
    request TEXT,
    UNIQUE(log_time, query_number, request)
  );
SQL


system("ruby genrateur_log_test_anomalie.rb")

timestamp_pattern = /(\d{6} \d{1,2}:\d{2}:\d{2})/
query_pattern = /(\d+) \S+\s+(.+)/
def insert_mariadb_general_log(client, log_time, query_number, request)
  begin
    client.prepare("INSERT IGNORE INTO mariadb_general_logs (log_time, query_number, request) VALUES (?, ?, ?)").execute(log_time, query_number, request)
  rescue Mysql2::Error => e
    puts "Erreur lors de l'insertion du log mariadb général: #{e.message}"
  end
end

def process_mariadb_general_logs(client, mariadb_log_path, timestamp_pattern, query_pattern)
  current_timestamp = nil

  File.foreach(mariadb_log_path, encoding: 'UTF-8') do |line|
    # Match the timestamp pattern
    timestamp_match = timestamp_pattern.match(line)
    if timestamp_match
      current_timestamp = DateTime.strptime(timestamp_match[1], "%y%m%d %H:%M:%S").to_time
    end

    # Match the query pattern
    query_match = query_pattern.match(line)
    if query_match && current_timestamp
      query_number = query_match[1].to_i
      request = query_match[2].strip
      insert_mariadb_general_log(client, current_timestamp, query_number, request)
    end
  end
end
# Méthode pour insérer un log système WordPress
def insert_wordpress_system_log(client, log_time, log_message)
  begin
    client.prepare("INSERT IGNORE INTO wordpress_system_logs (log_time, log_message) VALUES (?, ?)").execute(log_time, log_message)
  rescue Mysql2::Error => e
    puts "Erreur lors de l'insertion du log système WordPress: #{e.message}"
  end
end

# Méthode pour insérer un log Apache
def insert_apache_log(client, log_line)
  regex = /(?<remote_addr>\S+) - - \[(?<log_time>[^\]]+)\] "(?<request_method>\S+) (?<request_uri>\S+) (?<http_version>\S+)" (?<status_code>\d+) (?<response_size>\d+) "(?<referer>[^"]*)" "(?<user_agent>[^"]*)"/
  match = regex.match(log_line)

  if match
    log_time = DateTime.strptime(match[:log_time], "%d/%b/%Y:%H:%M:%S %z").to_time
    begin
      client.prepare("INSERT IGNORE INTO apache_logs (remote_addr, log_time, request_method, request_uri, http_version, status_code, response_size, referer, user_agent) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)").execute(
        match[:remote_addr],
        log_time,
        match[:request_method],
        match[:request_uri],
        match[:http_version],
        match[:status_code].to_i,
        match[:response_size].to_i,
        match[:referer],
        match[:user_agent]
      )
    rescue Mysql2::Error => e
      puts "Erreur lors de l'insertion du log Apache: #{e.message}"
    end
  end
end

# Méthode pour insérer un log de requête lente MariaDB
def insert_mariadb_slow_query_log(client, log_time, host, query)
  return if log_time.nil? || host.nil? || query.nil?

  begin
    client.prepare("INSERT IGNORE INTO mariadb_slow_query_logs (log_time, host, query) VALUES (?, ?, ?)").execute(log_time, host, query)
  rescue Mysql2::Error => e
    puts "Erreur lors de l'insertion du log de requête lente MariaDB: #{e.message}"
  end
end

# Méthode pour insérer un log système MariaDB
def insert_mariadb_system_log(client, log_time, log_message)
  begin
    client.prepare("INSERT IGNORE INTO mariadb_system_logs (log_time, log_message) VALUES (?, ?)").execute(log_time, log_message)
  rescue Mysql2::Error => e
    puts "Erreur lors de l'insertion du log système MariaDB: #{e.message}"
  end
end

# Méthode pour insérer un log MariaDB
def insert_mariadb_error_log(client, log_line)
  regex = /(?<log_time>\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}:\d{2})\s+\d+\s+\[(?<log_message>[^\]]+\].*)/
  match = regex.match(log_line)

  if match
    log_time = DateTime.strptime(match[:log_time], "%Y-%m-%d %H:%M:%S")
    begin
      client.prepare("INSERT IGNORE INTO mariadb_error_logs (log_time, log_message) VALUES (?, ?)").execute(log_time, match[:log_message])
    rescue Mysql2::Error => e
      puts "Erreur lors de l'insertion du log MariaDB: #{e.message}"
    end
  else
    puts "Log line didn't match: #{log_line}"
  end
end

# Traitement des fichiers de log
def process_logs(client)
  # Chemins des fichiers de log
  wordpress_system_log_path = './wordpress/system/syslog'
  apache_access_log_path = './wordpress/apache/wordpress_access.log'
  mariadb_system_log_path = './sgbd/system/syslog'
  mariadb_error_log_path = './sgbd/mariadb/error.log'
  mariadb_slow_log_path = './sgbd/mariadb/mariadb-slow.log'
  mariadb_general_log_path = './sgbd/mariadb/mysql.log'

  # Traitement des logs système WordPress
  File.foreach(wordpress_system_log_path, encoding: 'UTF-8') do |line|
    log_time = DateTime.parse(line.split[0..1].join(' '))
    insert_wordpress_system_log(client, log_time, line.strip)
  end

  # Traitement des logs Apache
  File.foreach(apache_access_log_path) do |line|
    insert_apache_log(client, line.strip)
  end

  # Traitement des logs système MariaDB
  File.foreach(mariadb_system_log_path, encoding: 'UTF-8') do |line|
    log_time = DateTime.parse(line.split[0..1].join(' '))
    insert_mariadb_system_log(client, log_time, line.strip)
  end

  # Traitement des logs MariaDB
  File.foreach(mariadb_error_log_path) do |line|
    insert_mariadb_error_log(client, line.strip)
  end

  # Traitement des logs de requêtes lentes MariaDB
   process_mariadb_general_logs(client, mariadb_general_log_path, /(\d{6} \d{1,2}:\d{2}:\d{2})/, /(\d+) \S+\s+(.+)/)
  process_mariadb_slow_logs(client, mariadb_slow_log_path)
end

# Traitement des logs de requêtes lentes MariaDB
def process_mariadb_slow_logs(client, mariadb_slow_log_path)
  log_time = nil
  host = nil
  query = nil
  
  File.foreach(mariadb_slow_log_path, encoding: 'UTF-8') do |line|
    if line.strip.empty?
      # Une ligne vide indique la fin d'un log
      if log_time && host && query
        insert_mariadb_slow_query_log(client, log_time, host, query)
      end
      # Réinitialise pour le prochain log
      log_time = nil
      host = nil
      query = nil
    elsif line.start_with?("# Time:")
      log_time_str = line.split[2..3].join(' ')
      log_time = DateTime.strptime(log_time_str, "%y%m%d %H:%M:%S")
    elsif line.start_with?("# User@Host:")
      host = line.split('[')[2].chomp(']')
    elsif line.strip.start_with?("SELECT", "UPDATE", "DELETE", "INSERT", "REPLACE")
      query = line.strip

      # Insérer immédiatement après avoir récupéré une requête
      if log_time && host && query
        insert_mariadb_slow_query_log(client, log_time, host, query)
        # Réinitialiser pour le prochain log
        log_time = nil
        host = nil
        query = nil
      end
    end
  end

  # Traite les lignes restantes si le fichier ne se termine pas par une ligne vide
  insert_mariadb_slow_query_log(client, log_time, host, query) if log_time && host && query
end

# Exécution du traitement des logs
process_logs(client)

puts "Logs insérés avec succès."

