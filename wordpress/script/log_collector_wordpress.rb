#!/usr/bin/env ruby

require 'fileutils'
require 'net/scp'

# Configuration du serveur central
central_server = '172.150.0.5' # Adresse IP du serveur central
destination_user = 'username'    # Remplace par le nom d'utilisateur pour se connecter au serveur central
destination_dir = 'logs/central/sysweb' # Répertoire de destination sur le serveur central

# Sources de logs à collecter
log_sources = {
  apache: '/var/log/apache2/access.log',
  syslog: '/var/log/syslog'
}

# Fonction pour collecter et envoyer les logs
def collect_and_send_logs(log_sources, central_server, destination_user, destination_dir)
  log_sources.each do |type, source|
    if File.exist?(source)
      # Créer le répertoire local pour le type de log
      local_dir = File.join(destination_dir, type.to_s)
      FileUtils.mkdir_p(local_dir)

      # Copier le log dans le répertoire local
      FileUtils.cp(source, File.join(local_dir, File.basename(source)))
      puts "Collected log from: #{source}"

      # Transférer le log au serveur central
      Net::SCP.start(central_server, destination_user) do |scp|
        scp.upload!(File.join(local_dir, File.basename(source)), "#{destination_dir}/#{type}/#{File.basename(source)}")
        puts "Sent log to central server: #{destination_dir}/#{type}/#{File.basename(source)}"
      end
    else
      puts "Log source does not exist: #{source}"
    end
  end
end

# Exécuter la collecte et l'envoi
collect_and_send_logs(log_sources, central_server, destination_user, destination_dir)

