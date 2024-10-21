# Utiliser l'image Debian Alpine
FROM debian:stable-slim

# Installer les paquets nécessaires
RUN apt-get update && \
    apt-get install -y openssh-server rsync && \
    mkdir /var/run/sshd && \
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

# Exposer le port SSH
EXPOSE 22

# Commande pour démarrer le service SSH
CMD ["/usr/sbin/sshd", "-D"]

