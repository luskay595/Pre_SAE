#!/usr/bin/env ruby
require 'net/ssh'
require 'net/scp'
require 'dotenv/load'

# Paramètres des hôtes distants
machines = [
  {
    host: ENV['REMOTE_HOST_1'],
    user: ENV['REMOTE_USER'],
    password: ENV['REMOTE_PASSWORD'],
    script: '/var/lib/mysql/script/log_collector_mariadb.rb'
  },
  {
    host: ENV['REMOTE_HOST_2'],
    user: ENV['REMOTE_USER'],
    password: ENV['REMOTE_PASSWORD'],
    script: '/var/www/html/script/log_collector_wordpress.rb'
  }
]

# Fonction pour exécuter un script de collecte de logs via SSH
def execute_remote_script(machine)
  puts "Connexion à #{machine[:host]}..."
  Net::SSH.start(machine[:host], machine[:user], password: machine[:password], verify_host_key: :never) do |ssh|
    puts "Exécution du script #{machine[:script]}..."
    command = "ruby #{machine[:script]} #{ENV['LOCAL_HOST']} #{ENV['LOCAL_USER']} #{ENV['LOCAL_PASSWORD']}" # Remplacez par les bons paramètres
    output = ssh.exec!(command)
    puts output
  end
end

# Exécuter les scripts de collecte de logs sur les machines distantes
machines.each do |machine|
  execute_remote_script(machine)
end

# Insertion des logs dans la base de données locale
puts "Exécution du script local d'insertion de logs..."
system("ruby insert_logs.rb")
puts "Exécution du script local de détection d'anomalie..."
system("ruby anomaly_logs.rb")
puts "Opération terminée avec succès."

