#!/usr/bin/env ruby
require 'net/scp'
require 'net/ssh'

# Configuration
REMOTE_HOST = '172.150.0.5'      
REMOTE_USER = 'user'          
REMOTE_PASSWORD = 'user123'   
REMOTE_PATH = '/home/user'    

# Liste des fichiers de log à collecter
LOG_FILES = [
  '/var/log/mysql/error.log',
]

def collect_and_send_logs
  LOG_FILES.each do |log_file|
    begin
      # Vérifiez si le fichier de log existe
      if File.exist?(log_file)
        puts "Collecte du fichier de log : #{log_file}"

        # Connexion SSH et transfert SCP
        Net::SSH.start(REMOTE_HOST, REMOTE_USER, password: REMOTE_PASSWORD) do |ssh|
          ssh.scp.upload!(log_file, "#{REMOTE_PATH}/#{File.basename(log_file)}") do |ch, name, sent, total|
            puts "#{name}: #{sent}/#{total} octets transférés."
          end
        end

        puts "Transfert réussi pour #{log_file}."
      else
        puts "Le fichier #{log_file} n'existe pas."
      end
    rescue Net::SCP::Error => e
      puts "Erreur SCP : #{e.message}"
    rescue Net::SSH::AuthenticationFailed
      puts "Échec de l'authentification. Vérifiez le nom d'utilisateur et le mot de passe."
    rescue => e
      puts "Erreur inattendue : #{e.message}"
    end
  end
end

# Exécution du script
collect_and_send_logs
