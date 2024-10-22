# Utiliser l'image officielle de MariaDB
FROM mariadb:latest

# Installer Ruby, Nano, et SSH
RUN apt-get update && apt-get install -y ruby nano rsync openssh-server openssh-client sshpass && gem install net-scp

# Configurer SSH pour permettre la connexion root avec mot de passe
RUN echo 'root:testpsswd' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Créer le répertoire nécessaire pour SSH
RUN mkdir /var/run/sshd

# Exposer le port 22 pour SSH
EXPOSE 22

# Commande par défaut pour démarrer MariaDB et SSH
CMD service ssh start && docker-entrypoint.sh mariadbd

