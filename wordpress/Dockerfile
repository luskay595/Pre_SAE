# Utiliser l'image officielle de WordPress
FROM wordpress:latest

# Copier le fichier de configuration Apache dans le conteneur
COPY apache-config/my-custom.conf /etc/apache2/conf-available/my-custom.conf

# Activer le fichier de configuration
RUN a2enconf my-custom

# Exposer le port 80 (déjà exposé par l'image par défaut, mais inclus pour clarté)
EXPOSE 80

# Commande par défaut pour démarrer Apache
CMD ["apache2-foreground"]
