# Utiliser l'image Debian Alpine
FROM debian:stable-slim

# Installer les paquets nécessaires
RUN apt-get update && \
    apt-get install -y openssh-server rsync ruby nano rsyslog ruby-dev build-essential libmariadb-dev openssh-client sshpass cron && \
    mkdir /var/run/sshd && \
    gem install net-scp && \
    gem install bundler && \
    gem install mysql2 && \
    apt-get clean

# Configurer SSH
RUN echo 'root:testpsswd' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Créer un nouvel utilisateur
RUN useradd -m -s /bin/bash user

# Définir un mot de passe pour l'utilisateur
RUN echo 'user:user123' | chpasswd

# Ajouter l'utilisateur au groupe sudo (optionnel)
RUN apt-get update && apt-get install -y sudo && \
    usermod -aG sudo user

# Créer le répertoire de logs en tant qu'utilisateur non-root
USER user
RUN mkdir -p /home/user/logs

# Revenir à l'utilisateur root pour configurer cron
USER root

# Ajouter une tâche cron pour exécuter le script Ruby toutes les 30 minutes
RUN echo "*/30 * * * * ruby /home/user/logs/execute_log_collection.rb" > /etc/cron.d/log_collector

# Appliquer les permissions adéquates au fichier cron
RUN chmod 0644 /etc/cron.d/log_collector

# Assurer le démarrage de cron en parallèle du service SSH
RUN crontab /etc/cron.d/log_collector

# Exposer le port SSH
EXPOSE 22

# Commande pour démarrer cron et le service SSH
CMD cron && /usr/sbin/sshd -D 


