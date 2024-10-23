#!/usr/bin/env ruby

require 'fileutils'

# Paramètres à passer en ligne de commande
if ARGV.length < 3
  puts "Usage: #{$0} <REMOTE_HOST> <REMOTE_USER> <REMOTE_PASSWORD>"
  exit 1
end

# Configuration du serveur central
REMOTE_HOST = ARGV[0]             # Adresse IP ou nom d'hôte du serveur distant
REMOTE_USER = ARGV[1]             # Nom d'utilisateur sur le serveur distant
REMOTE_PASSWORD = ARGV[2]         # Mot de passe de l'utilisateur
REMOTE_PATH = '/home/user/logs/sgbd'   # Chemin racine sur le serveur distant pour stocker les logs

# Sources de logs à collecter
MARIADB_LOGS = [
  '/var/log/mysql/error.log',
  '/var/log/mysql/mariadb-slow.log'
]
SYSTEM_LOGS = [
  '/var/log/syslog'
]


# Fonction pour créer les dossiers si nécessaire
def ensure_remote_directories(remote_host, remote_user, remote_password, base_path, subdirectories)
  subdirectories.each do |subdir|
    puts "Création du répertoire #{subdir} sur #{remote_host}..."
    command = "sshpass -p '#{remote_password}' ssh -o StrictHostKeyChecking=no #{remote_user}@#{remote_host} 'mkdir -p #{base_path}/#{subdir}'"
    if system(command)
      puts "Répertoire #{subdir} créé avec succès."
    else
      puts "Erreur lors de la création du répertoire #{subdir}."
    end
  end
end

# Fonction pour synchroniser les logs avec rsync
def sync_logs(log_files, remote_host, remote_user, remote_password, remote_path, subdirectory)
  log_files.each do |log_file|
    if File.exist?(log_file)
      puts "Synchronisation du fichier de log : #{log_file} vers #{subdirectory}..."

      # Commande rsync pour transférer uniquement les nouveaux fichiers
      command = "sshpass -p '#{remote_password}' rsync -avz --progress -e 'ssh -o StrictHostKeyChecking=no' #{log_file} #{remote_user}@#{remote_host}:#{remote_path}/#{subdirectory}/"
      if system(command)
        puts "Synchronisation réussie pour #{log_file}."
      else
        puts "Erreur lors de la synchronisation de #{log_file}."
      end
    else
      puts "Le fichier #{log_file} n'existe pas."
    end
  end
end

# Exécution du script
def collect_and_send_logs(remote_host, remote_user, remote_password)
  # Créer les sous-répertoires sur le serveur distant
  ensure_remote_directories(remote_host, remote_user, remote_password, REMOTE_PATH, ['mariadb','system'])

  # Synchroniser les logs MariaDB
  sync_logs(MARIADB_LOGS, remote_host, remote_user, remote_password, REMOTE_PATH, 'mariadb')

  # Synchroniser les logs système
  sync_logs(SYSTEM_LOGS, remote_host, remote_user, remote_password, REMOTE_PATH, 'system')

  # Synchroniser les logs système
end

# Appeler la fonction principale
collect_and_send_logs(REMOTE_HOST, REMOTE_USER, REMOTE_PASSWORD)
