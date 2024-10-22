# Utiliser l'image officielle de WordPress
FROM wordpress:latest

# Installer Ruby, Nano, rsyslog, ssh et la gem net-scp
RUN apt-get update && apt-get install -y ruby nano rsyslog rsync openssh-server openssh-client sshpass && gem install net-scp

# Copier le fichier de configuration Apache VirtualHost dans le conteneur
COPY apache-config/my-custom.conf /etc/apache2/sites-available/my-custom.conf

# Activer le VirtualHost et désactiver le VirtualHost par défaut
RUN a2dissite 000-default \
    && a2ensite my-custom

# Configurer SSH pour permettre la connexion root avec mot de passe
RUN echo 'root:testpsswd' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Créer le répertoire nécessaire pour SSH
RUN mkdir /var/run/sshd

# Exposer le port 80 pour Apache et 22 pour SSH
EXPOSE 80
EXPOSE 22

# Commande par défaut pour démarrer rsyslogd, SSH et Apache
CMD service ssh start && rsyslogd && apache2-foreground

