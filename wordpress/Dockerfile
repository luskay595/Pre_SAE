# Utiliser l'image officielle de WordPress
FROM wordpress:latest

# Installer Ruby, Nano, rsyslog, ssh, et la gem net-scp
RUN apt-get update && apt-get install -y ruby nano rsyslog rsync openssh-server openssh-client sshpass sysstat bc && gem install net-scp

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

RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_UPSTREAM_VERSION}.tar.gz \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& tar -xzf wordpress.tar.gz -C /usr/src/ \
	&& rm wordpress.tar.gz \
	&& chown -R www-data:www-data /usr/src/wordpress

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

# Exposer le port 80 pour Apache et 22 pour SSH
EXPOSE 80
EXPOSE 22

# Commande par défaut pour démarrer rsyslogd, SSH et Apache
CMD ["bash", "-c", "service ssh start; rsyslogd; /usr/local/bin/cpu_usage_monitor.sh & apache2-foreground"]

