# Utiliser l'image Debian stable-slim
FROM debian:stable-slim

# Installer les paquets nécessaires
RUN apt-get update && \
    apt-get install -y openssh-server rsync ruby nano rsyslog ruby-dev build-essential libmariadb-dev openssh-client sshpass cron && \
    mkdir /var/run/sshd && \
    gem install net-scp && \
    gem install bundler && \
    gem install mysql2 && \
    apt-get clean

# Créer l'utilisateur `user` avec un mot de passe
RUN useradd -m -s /bin/bash user && \
    echo 'user:user123' | chpasswd

# Configurer SSH pour interdire la connexion root
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo 'AllowUsers user' >> /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Changer d'utilisateur pour créer le répertoire logs
USER user

# Créer le répertoire pour les logs (pas besoin de permissions ici, car il sera monté)
RUN mkdir -p /home/user/logs

# Revenir à l'utilisateur root pour ajouter la tâche cron
USER root

# Ajouter une tâche cron pour exécuter le script Ruby toutes les 30 minutes
RUN echo "*/30 * * * * ruby /home/user/logs/execute_log_collection.rb" > /etc/cron.d/log_collector && \
    chmod 0644 /etc/cron.d/log_collector && \
    crontab -u user /etc/cron.d/log_collector

# Exposer le port 22 pour SSH
EXPOSE 22

# Commande pour démarrer cron et le service SSH
CMD ["bash", "-c", "chown user:user /home/user/logs && cron && /usr/sbin/sshd -D"]

