require 'mysql2'

def wait_for_mariadb
  connected = false
  until connected
    begin
      client = Mysql2::Client.new(host: 'localhost', username: 'root')
      client.query('SELECT 1')
      connected = true
      puts 'MariaDB is ready.'
    rescue Mysql2::Error
      puts 'Waiting for MariaDB to be ready...'
      sleep 2
    end
  end
end

def setup_databases_and_users
  client = Mysql2::Client.new(host: 'localhost', username: 'root')

  # Créer les bases de données
  client.query("CREATE DATABASE IF NOT EXISTS logs_db;")
  client.query("CREATE DATABASE IF NOT EXISTS anomaly_logs;")

  # Créer les utilisateurs et accorder les privilèges
  client.query("CREATE USER IF NOT EXISTS 'user_logs'@'%' IDENTIFIED BY 'password1';")
  client.query("GRANT ALL PRIVILEGES ON logs_db.* TO 'user_logs'@'%';")

  client.query("CREATE USER IF NOT EXISTS 'user_anomaly'@'%' IDENTIFIED BY 'password2';")
  client.query("GRANT ALL PRIVILEGES ON anomaly_logs.* TO 'user_anomaly'@'%';")

  client.query("CREATE USER IF NOT EXISTS 'rootmaispastrop'@'%' IDENTIFIED BY 'securepassword';")
  client.query("GRANT SELECT ON *.* TO 'rootmaispastrop'@'%';")

  # Appliquer les changements de privilèges
  client.query("FLUSH PRIVILEGES;")

  puts 'Database setup completed.'
end

# Attendre que MariaDB soit prêt, puis configurer les bases de données et les utilisateurs
wait_for_mariadb
setup_databases_and_users
