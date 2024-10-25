#!/usr/bin/env ruby
require 'mysql2'

# Configuration de la connexion à la base de données
client = Mysql2::Client.new(
  host: "db",
  username: "root",
  password: "root_password",
  database: 'logs_db' 
)

# Fonction pour vérifier l'existence du log
def log_exists?(client, table, log_id)
  query = "SELECT 1 FROM #{table} WHERE id = #{log_id} LIMIT 1"
  result = client.query(query)
  result.count > 0
end

# Insertion des logs dans les tables
logs = {
  mariadb_system_logs: [
    [1, '2024-10-23 13:18:41', '2024-10-23T13:18:41.955048+00:00 b8b407dbe053 root: ALERT: Utilisation CPU élevée: 100%'],
    [2, '2024-10-23 13:19:42', '2024-10-23T13:19:42.230419+00:00 b8b407dbe053 root: ALERT: Utilisation CPU élevée: 100%'],
    [3, '2024-10-23 13:20:42', '2024-10-23T13:20:42.511518+00:00 b8b407dbe053 root: ALERT: Utilisation CPU élevée: 100%']
  ],
  wordpress_system_logs: [
    [1, '2024-10-23 13:19:46', '2024-10-23T13:19:46.682719+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%'],
    [2, '2024-10-23 13:20:46', '2024-10-23T13:20:46.903814+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%'],
    [3, '2024-10-23 13:21:47', '2024-10-23T13:21:47.105616+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%']
  ],
  mariadb_error_logs: [
  [1, '2024-10-23 17:10:41', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [2, '2024-10-23 17:10:42', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [3, '2024-10-23 17:10:43', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [4, '2024-10-23 17:10:44', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [5, '2024-10-23 17:10:45', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [6, '2024-10-23 17:10:46', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [7, '2024-10-23 17:10:47', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [8, '2024-10-23 17:10:48', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [9, '2024-10-23 17:10:49', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [10, '2024-10-23 17:10:50', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [11, '2024-10-23 17:10:51', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [12, '2024-10-23 17:10:52', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [13, '2024-10-23 17:10:53', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [14, '2024-10-23 17:10:54', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [15, '2024-10-23 17:10:55', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"],
  [16, '2024-10-23 17:10:56', "[Warning] Access denied for user 'invalid_user'@'172.150.0.5' (using password: YES)"]
],
  apache_logs: [
  [1, '172.150.0.1', '2024-10-23 13:45:00', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [2, '172.150.0.1', '2024-10-23 13:45:01', 'GET', '/nonexistent_page', 'HTTP/1.1', 404, 1234, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [3, '172.150.0.1', '2024-10-23 13:45:02', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [5, '172.150.0.1', '2024-10-23 13:45:03', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [6, '172.150.0.1', '2024-10-23 13:45:04', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [7, '172.150.0.1', '2024-10-23 13:45:05', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [8, '172.150.0.1', '2024-10-23 13:45:06', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [9, '172.150.0.1', '2024-10-23 13:45:07', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [10, '172.150.0.1', '2024-10-23 13:45:08', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [11, '172.150.0.1', '2024-10-23 13:45:09', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [12, '172.150.0.1', '2024-10-23 13:46:00', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [13, '172.150.0.1', '2024-10-23 13:46:01', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [14, '172.150.0.1', '2024-10-23 13:46:02', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [15, '172.150.0.1', '2024-10-23 13:46:03', 'GET', '/nonexistent_page_2', 'HTTP/1.1', 404, 1234, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [16, '172.150.0.1', '2024-10-23 13:46:04', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [17, '172.150.0.1', '2024-10-23 13:46:05', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [18, '172.150.0.1', '2024-10-23 13:46:06', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [19, '172.150.0.1', '2024-10-23 13:46:07', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [20, '172.150.0.1', '2024-10-23 13:46:08', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [21, '172.150.0.1', '2024-10-23 13:46:09', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [22, '172.150.0.1', '2024-10-23 13:46:10', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [23, '172.150.0.1', '2024-10-23 13:46:11', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'],
  [24, '172.150.0.1', '2024-10-23 13:46:12', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3']
]

}

# Parcourir et insérer les logs
logs.each do |table, log_entries|
  log_entries.each do |log|
    log_id = log[0]
    
    # Vérification d'existence
    unless log_exists?(client, table, log_id)
      # Création de la requête d'insertion en fonction des logs
      columns = case table
                when :apache_logs
                  'id, remote_addr, log_time, request_method, request_uri, http_version, status_code, response_size, referer, user_agent'
                else
                  'id, log_time, log_message'
                end
      values = log.map { |val| client.escape(val.to_s) }.join("', '")
      query = "INSERT INTO #{table} (#{columns}) VALUES ('#{values}')"

      # Exécution de la requête d'insertion
      client.query(query)
      puts "Log ID #{log_id} inséré dans #{table}"
    else
      puts "Log ID #{log_id} existe déjà dans #{table}, insertion ignorée"
    end
  end
end

# Fermeture de la connexion
client.close

