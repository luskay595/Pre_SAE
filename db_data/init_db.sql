CREATE DATABASE IF NOT EXISTS logs_db;
GRANT ALL PRIVILEGES ON logs_db.* TO 'user'@'%';
FLUSH PRIVILEGES;