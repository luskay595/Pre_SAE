# Utiliser l'image officielle de WordPress
FROM wordpress:latest

# Installer Ruby, Nano, rsyslog et la gem net-scp
RUN apt-get update && apt-get install -y ruby nano rsyslog rsync openssh-client sshpass && gem install net-scp

# Copier le fichier de configuration Apache VirtualHost dans le conteneur
COPY apache-config/my-custom.conf /etc/apache2/sites-available/my-custom.conf

# Activer le VirtualHost et désactiver le VirtualHost par défaut
RUN a2dissite 000-default \
    && a2ensite my-custom

# Exposer le port 80 (déjà exposé par l'image WordPress)
EXPOSE 80

# Commande par défaut pour démarrer rsyslogd et Apache
CMD rsyslogd && apache2-foreground

