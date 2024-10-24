require 'time'
require 'securerandom'

# Configuration des paramètres du log
apache_log_file_path = 'wordpress/apache/wordpress_access.log'  # Chemin du fichier de log Apache
mariadb_log_file_path = './sgbd/mariadb/error.log'  # Chemin du fichier de log MariaDB
resources = {
  'index.html' => 200,             # Accès réussi
  'about.html' => 403,             # Accès refusé
  'contact.html' => 404,           # Ressource non trouvée
  'server_error.html' => 500       # Erreur interne
}
log_count = 50                     # Nombre total d'accès à simuler

# Fonction pour générer une entrée de log Apache
def generate_apache_log_entry(resource, status_code)
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  ip_address = "#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}" # Générer une adresse IP aléatoire
  user = "user_#{SecureRandom.hex(4)}" # Générer un nom d'utilisateur aléatoire

  case status_code
  when 200
    log_message = "[#{timestamp}] #{status_code} OK: User '#{user}' accessed '#{resource}' from IP '#{ip_address}'"
  when 403
    log_message = "[#{timestamp}] #{status_code} Forbidden: Access denied for user '#{user}' trying to access '#{resource}' from IP '#{ip_address}'"
  when 404
    log_message = "[#{timestamp}] #{status_code} Not Found: User '#{user}' attempted to access non-existent resource '#{resource}' from IP '#{ip_address}'"
  when 500
    log_message = "[#{timestamp}] #{status_code} Internal Server Error: User '#{user}' encountered a server error while accessing '#{resource}' from IP '#{ip_address}'"
  end
  
  log_message
end

# Fonction pour générer une entrée de log MariaDB
def generate_mariadb_log_entry(user, query, status_code)
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  log_message = "[#{timestamp}] User '#{user}' executed query '#{query}' - Status Code: #{status_code}"
  log_message
end

# Ouvrir les fichiers en écriture
File.open(apache_log_file_path, 'w') do |apache_file|
  File.open(mariadb_log_file_path, 'w') do |mariadb_file|
    log_count.times do
      # Simuler une requête pour le log Apache
      resource = resources.keys.sample
      status_code = resources[resource]
      apache_log_entry = generate_apache_log_entry(resource, status_code)
      apache_file.puts(apache_log_entry)

      # Simuler une requête pour le log MariaDB
      user = "user_#{SecureRandom.hex(4)}" # Générer un nom d'utilisateur aléatoire
      query = "SELECT * FROM users WHERE id = #{rand(1..100)}" # Simuler une requête SQL
      mariadb_status_code = status_code == 200 ? 0 : 1 # 0 pour succès, 1 pour erreur
      mariadb_log_entry = generate_mariadb_log_entry(user, query, mariadb_status_code)
      mariadb_file.puts(mariadb_log_entry)
    end
  end
end

puts "Logs d'erreurs générés dans '#{apache_log_file_path}' et '#{mariadb_log_file_path}' avec #{log_count} entrées."
