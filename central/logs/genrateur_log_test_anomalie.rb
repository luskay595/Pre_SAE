require 'mysql2'

# Database connection settings
client = Mysql2::Client.new(
  host: 'localhost',
  username: 'your_username',
  password: 'your_password',
  database: 'your_database'
)

def record_exists?(client, table, conditions)
  query = "SELECT 1 FROM #{table} WHERE #{conditions} LIMIT 1;"
  result = client.query(query)
  result.any?
end

def insert_if_not_exists(client, table, query, conditions)
  if record_exists?(client, table, conditions)
    puts "Record already exists in #{table} with #{conditions}. Skipping insert."
  else
    client.query(query)
    puts "Inserted new record into #{table}."
  end
end

# Apache logs insertions with verification
apache_logs = [
  [1, '172.150.0.1', '2024-10-23 13:45:00', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [2, '172.150.0.1', '2024-10-23 13:45:01', 'GET', '/nonexistent_page', 'HTTP/1.1', 404, 1234, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [3, '172.150.0.1', '2024-10-23 13:45:02', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [5, '172.150.0.1', '2024-10-23 13:45:03', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [6, '172.150.0.1', '2024-10-23 13:45:04', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [7, '172.150.0.1', '2024-10-23 13:45:05', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [8, '172.150.0.1', '2024-10-23 13:45:06', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [9, '172.150.0.1', '2024-10-23 13:45:07', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [10, '172.150.0.1', '2024-10-23 13:45:08', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [11, '172.150.0.1', '2024-10-23 13:45:09', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [12, '172.150.0.1', '2024-10-23 13:46:00', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [13, '172.150.0.1', '2024-10-23 13:46:01', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [14, '172.150.0.1', '2024-10-23 13:46:02', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [15, '172.150.0.1', '2024-10-23 13:46:03', 'GET', '/nonexistent_page_2', 'HTTP/1.1', 404, 1234, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [16, '172.150.0.1', '2024-10-23 13:46:04', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [17, '172.150.0.1', '2024-10-23 13:46:05', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [18, '172.150.0.1', '2024-10-23 13:46:06', 'GET', '/', 'HTTP/1.1', 500, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [19, '172.150.0.1', '2024-10-23 13:46:07', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [20, '172.150.0.1', '2024-10-23 13:46:08', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [21, '172.150.0.1', '2024-10-23 13:46:09', 'GET', '/', 'HTTP/1.1', 403, 0, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [22, '172.150.0.1', '2024-10-23 13:46:10', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [23, '172.150.0.1', '2024-10-23 13:46:11', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [24, '172.150.0.1', '2024-10-23 13:46:12', 'GET', '/nonexistent_page_3', 'HTTP/1.1', 404, 1234, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3'],
  [25, '172.150.0.1', '2024-10-23 13:46:13', 'GET', '/', 'HTTP/1.1', 200, 15338, '-', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/58.0.3029.110 Safari/537.3']
]

apache_logs.each do |log|
  conditions = "id = #{log[0]}"
  query = "INSERT INTO `apache_logs` (`id`, `remote_addr`, `log_time`, `request_method`, `request_uri`, `http_version`, `status_code`, `response_size`, `referer`, `user_agent`) VALUES (#{log[0]}, '#{log[1]}', '#{log[2]}', '#{log[3]}', '#{log[4]}', '#{log[5]}', #{log[6]}, #{log[7]}, '#{log[8]}', '#{log[9]}');"
  insert_if_not_exists(client, 'apache_logs', query, conditions)
end

# MariaDB error logs insertions with verification
mariadb_logs = [
  [1, '2024-10-23 17:10:41', 'Warning] Access denied for user \'invalid_user\'@\'172.150.0.5\' (using password: YES)'],
  [2, '2024-10-23 17:10:42', 'Error] Table \'example_database.example_table\' doesn\'t exist'],
  [3, '2024-10-23 17:10:43', 'Warning] Access denied for user \'invalid_user\'@\'172.150.0.5\' (using password: YES)'],
  [4, '2024-10-23 17:10:44', 'Error] Table \'example_database.example_table_2\' doesn\'t exist'],
  [5, '2024-10-23 17:10:45', 'Warning] Access denied for user \'invalid_user\'@\'172.150.0.5\' (using password: YES)'],
  [6, '2024-10-23 17:10:46', 'Error] Table \'example_database.example_table_3\' doesn\'t exist'],
  [7, '2024-10-23 17:10:47', 'Warning] Access denied for user \'invalid_user\'@\'172.150.0.5\' (using password: YES)'],
  [8, '2024-10-23 17:10:48', 'Error] Table \'example_database.example_table_4\' doesn\'t exist'],
  [9, '2024-10-23 17:10:49', 'Warning] Access denied for user \'invalid_user\'@\'172.150.0.5\' (using password: YES)'],
  [10, '2024-10-23 17:10:50', 'Error] Table \'example_database.example_table_5\' doesn\'t exist']
]

mariadb_logs.each do |log|
  conditions = "id = #{log[0]}"
  query = "INSERT INTO `mariadb_error_logs` (`id`, `log_time`, `log_message`) VALUES (#{log[0]}, '#{log[1]}', '#{log[2]}');"
  insert_if_not_exists(client, 'mariadb_error_logs', query, conditions)
end

# WordPress system logs insertions with verification
wordpress_logs = [
  [1, '2024-10-23 13:18:46', '2024-10-23T13:18:46.468147+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%'],
  [5, '2024-10-23 13:19:46', '2024-10-23T13:19:46.682719+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%'],
  [6, '2024-10-23 13:20:46', '2024-10-23T13:20:46.903814+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%'],
  [7, '2024-10-23 13:21:47', '2024-10-23T13:21:47.105616+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%'],
  [8, '2024-10-23 13:22:47', '2024-10-23T13:22:47.311404+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%'],
  [9, '2024-10-23 13:23:47', '2024-10-23T13:23:47.514975+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%'],
  [10, '2024-10-23 13:24:47', '2024-10-23T13:24:47.711533+00:00 fc2faf99b817 root: ALERT: Utilisation CPU élevée: 100%']
]

wordpress_logs.each do |log|
  conditions = "id = #{log[0]}"
  query = "INSERT INTO `wordpress_system_logs` (`id`, `log_time`, `log_message`) VALUES (#{log[0]}, '#{log[1]}', '#{log[2]}');"
  insert_if_not_exists(client, 'wordpress_system_logs', query, conditions)
end

# MariaDB system logs insertions with verification
mariadb_system_logs = [
  [1, '2024-10-23 13:18:41', '2024-10-23T13:18:41.955048+00:00 b8b407dbe053 root: ALERT: Utilisation CPU élevée: 100%'],
  [2, '2024-10-23 13:19:42', '2024-10-23T13:19:42.230419+00:00 b8b407dbe053 root: ALERT: Utilisation CPU élevée: 100%'],
  [3, '2024-10-23 13:20:42', '2024-10-23T13:20:42.511518+00:00 b8b407dbe053 root: ALERT: Utilisation CPU élevée: 100%'],
  [4, '2024-10-23 13:21:42', '2024-10-23T13:21:42.772820+00:00 b8b407dbe053 root: ALERT: Utilisation CPU élevée: 100%'],
  [5, '2024-10-23 13:22:43', '2024-10-23T13:22:43.031734+00:00 b8b407dbe053 root: ALERT: Utilisation CPU élevée: 100%']
]

mariadb_system_logs.each do |log|
  conditions = "id = #{log[0]}"
  query = "INSERT INTO `mariadb_system_logs` (`id`, `log_time`, `log_message`) VALUES (#{log[0]}, '#{log[1]}', '#{log[2]}');"
  insert_if_not_exists(client, 'mariadb_system_logs', query, conditions)
end


puts "Data insertion process completed."
