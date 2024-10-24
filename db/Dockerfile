# Utiliser l'image officielle de MariaDB
FROM mariadb:latest

# Installer Ruby, Nano, SSH, sysstat, et rsyslog
RUN apt-get update && apt-get install -y ruby nano rsyslog rsync openssh-server openssh-client sshpass sysstat bc && gem install net-scp

# Configurer SSH pour permettre la connexion root avec mot de passe
RUN echo 'root:testpsswd' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Créer le répertoire nécessaire pour SSH
RUN mkdir /var/run/sshd

# Créer le répertoire de log pour MySQL
RUN mkdir -p /var/log/mysql
RUN chown mysql:mysql /var/log/mysql
RUN chmod 750 /var/log/mysql

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

