#!/usr/bin/env ruby
require 'mysql2'
require 'date'

# Configuration de la connexion à MariaDB
client = Mysql2::Client.new(
  host: "db",
  username: "root",
  password: "root_password"
)

# Création de la base de données si elle n'existe pas
client.query("CREATE DATABASE IF NOT EXISTS logs_db;")
client.query("USE logs_db;")

# Création des tables pour les logs si elles n'existent pas déjà
client.query <<-SQL
  CREATE TABLE IF NOT EXISTS wordpress_system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_time DATETIME,
    log_message TEXT,
    UNIQUE(log_time, log_message) -- Pour éviter les doublons
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
    UNIQUE(remote_addr, log_time, request_uri, status_code) -- Pour éviter les doublons
  );
SQL

# Table pour les logs système de MariaDB
client.query <<-SQL
  CREATE TABLE IF NOT EXISTS mariadb_system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_time DATETIME,
    log_message TEXT,
    UNIQUE(log_time, log_message) -- Pour éviter les doublons
  );
SQL



client.query <<-SQL
  CREATE TABLE IF NOT EXISTS mariadb_error_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_time DATETIME,
    log_message TEXT,
    UNIQUE(log_time, log_message) -- Pour éviter les doublons
  );
SQL

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

  # Traitement des logs système WordPress
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
  

end

# Exécution du traitement des logs
process_logs(client)

puts "Logs insérés avec succès."

