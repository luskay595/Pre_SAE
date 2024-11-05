# Utiliser l'image officielle de WordPress
FROM wordpress:latest

# Mettre à jour le système et installer les paquets nécessaires
RUN apt-get update && apt-get install -y \
    ruby \
    nano \
    rsyslog \
    rsync \
    openssh-server \
    openssh-client \
    sshpass \
    sysstat \
    bc && \
    gem install net-scp

# Ajouter un utilisateur avec des privilèges limités
RUN useradd -m -d /home/limiteduser -s /bin/bash limiteduser && \
    echo 'limiteduser:testpassword' | chpasswd && \
    usermod -aG sudo,www-data limiteduser

# Configurer SSH pour interdire la connexion root mais autoriser limiteduser
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo 'AllowUsers limiteduser' >> /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Copier et configurer le fichier de configuration Apache
COPY apache-config/my-custom.conf /etc/apache2/sites-available/my-custom.conf
RUN chown root:root /etc/apache2/sites-available/my-custom.conf && chmod 644 /etc/apache2/sites-available/my-custom.conf

# Activer le VirtualHost personnalisé et désactiver le VirtualHost par défaut
RUN a2dissite 000-default && a2ensite my-custom

# Créer le répertoire nécessaire pour SSH
RUN mkdir /var/run/sshd

# Configurer les permissions pour le répertoire web
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

# Ajouter le ServerName dans la configuration Apache pour éviter les avertissements
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Ajouter limiteduser aux groupes 'www-data' pour l'accès aux logs Apache
RUN usermod -aG www-data limiteduser

# Créer un script pour surveiller l'utilisation du CPU
RUN echo '#!/bin/bash\n\
THRESHOLD=80\n\
check_cpu_usage() {\n\
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk "{print 100 - \$1}")\n\
    if (( $(echo "$CPU_USAGE > $THRESHOLD" | bc -l) )); then\n\
        logger "ALERT: Utilisation CPU élevée: $CPU_USAGE%"\n\
    fi\n\
}\n\
while true; do\n\
    check_cpu_usage\n\
    sleep 60\n\
done' > /usr/local/bin/cpu_usage_monitor.sh && \
    chmod +x /usr/local/bin/cpu_usage_monitor.sh

# Exposer les ports 80 pour Apache et 22 pour SSH
EXPOSE 80 22

# Démarrer SSH, rsyslog, le script de surveillance du CPU, et Apache
CMD ["bash", "-c", "service ssh start; rsyslogd; /usr/local/bin/cpu_usage_monitor.sh & docker-entrypoint.sh apache2-foreground"]

