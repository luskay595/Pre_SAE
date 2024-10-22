# Utiliser l'image Debian Alpine
FROM debian:stable-slim

# Installer les paquets nécessaires
RUN apt-get update && \
    apt-get install -y openssh-server rsync ruby nano && \
    mkdir /var/run/sshd && \
    gem install net-scp && \
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

# Revenir à l'utilisateur root pour démarrer le service SSH
USER root

# Exposer le port SSH
EXPOSE 22

# Commande pour démarrer le service SSH
CMD ["/usr/sbin/sshd", "-D"]


