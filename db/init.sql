CREATE DATABASE IF NOT EXISTS logs_db;

-- Vérifiez si l'utilisateur existe, sinon créez-le
CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY 'password';

GRANT ALL PRIVILEGES ON logs_db.* TO 'user'@'%';

FLUSH PRIVILEGES;

