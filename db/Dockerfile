# Utiliser l'image officielle de MariaDB
FROM mariadb:latest

# Installer Ruby, Nano, SSH, sysstat, et rsyslog
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
    usermod -aG sudo,adm,syslog limiteduser

# Configurer SSH pour interdire la connexion root mais autoriser limiteduser
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo 'AllowUsers limiteduser' >> /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Créer le répertoire nécessaire pour SSH
RUN mkdir /var/run/sshd

# Ajouter limiteduser aux groupes 'adm' et 'syslog' pour accéder aux fichiers de log
RUN usermod -aG adm,syslog limiteduser

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

# Exposer le port 22 pour SSH
EXPOSE 22

# Démarrer MariaDB, SSH et le script de surveillance CPU
CMD ["bash", "-c", "service ssh start; rsyslogd; /usr/local/bin/cpu_usage_monitor.sh & docker-entrypoint.sh mariadbd"]

