

## Pre_SAE
Dans le dossier du projet, exécutez la commande suivante pour construire et démarrer les conteneurs Docker :
   ```bash
   docker compose up --build
   ```

Accédez au conteneur `pre_sae-central-1` :
   ```bash
   docker exec -it pre_sae-central-1 bash
   ```

Dans le conteneur, allez dans le dossier des logs :
   ```bash
   cd /home/user/logs
   ```

Lancez le script de recup et d'insertion de logs :
   ```bash
   ./execute_log_collection.rb
   ```

## Accéder à l'Interface Web

Une fois les étapes précédentes complétées, ouvrez un navigateur et rendez-vous à l'adresse suivante pour accéder à l'interface de monitoring :

```
http://localhost/monitoring/index.php
```

L'interface web vous permet de visualiser et de filtrer les anomalies des serveurs en temps réel.

## Notes supplémentaires

- Les logs sont rechargés régulièrement grâce à un cron job configuré dans le conteneur.

## Auteur

Projet Pre_SAE - Interface de Monitoring - VANNESTE Lucas et SLIMANI Robin
