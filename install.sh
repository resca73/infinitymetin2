#!/usr/bin/env bash
set -e

echo "?? Starting InfinityMetin2 setup..."

# 1. Aggiornamento sistema
echo "Updating FreeBSD…"
sudo freebsd-update fetch && sudo freebsd-update install
sudo pkg update && sudo pkg upgrade -y

# 2. Installazione dipendenze
echo "Installing dependencies..."
sudo pkg install -y git gmake mysql57-server python3 py38-sqlite3 cmake wget

# 3. Abilita MySQL e SSH
sudo sysrc mysql_enable="YES"
sudo sysrc sshd_enable="YES"
sudo service mysql-server start
sudo service sshd start

# 4. Prepara database
echo "Setting up MySQL root password"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY ''; FLUSH PRIVILEGES;"

echo "Creating Metin2 database and user"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS metin2; \
CREATE USER IF NOT EXISTS 'm2'@'localhost' IDENTIFIED BY 'm2pass'; \
GRANT ALL PRIVILEGES ON metin2.* TO 'm2'@'localhost'; FLUSH PRIVILEGES;"

# 5. Clona repository Metin2 Project
echo "Cloning Metin2 server repository..."
cd ~
git clone https://github.com/Metin2-Project/Metin2.git metin2
cd metin2/server

# 6. Compilazione
echo "Building server..."
gmake all

# 7. Configurazione ambiente
echo "Applying default samples..."
cp src/settings.py.sample src/settings.py
sed -i '' "s/'DB_HOST', '127.0.0.1'/'DB_HOST', 'localhost'/g" src/settings.py
sed -i '' "s/'DB_USER', 'root'/'DB_USER', 'm2'/g" src/settings.py
sed -i '' "s/'DB_PASS', ''/'DB_PASS', 'm2pass'/g" src/settings.py
sed -i '' "s/'DB_NAME', 'metin2'/'DB_NAME', 'metin2'/g" src/settings.py

# 8. Popolamento database
echo "Loading initial schema..."
mysql metin2 < sql/create_mysql.sql

# 9. Avvio server test
echo "Starting the server for the first time..."
./start.sh start

echo "? Build and setup complete!"

echo "Run with:"
echo "  cd ~/metin2/server"
echo "  sh start.sh start"
echo "Then configure your local client with the VM's LAN IP."

# 10. Guida PDF (opzionale)
cat << EOF > ~/infinitymetin2_guida.txt
InfinityMetin2 LAN setup:

1) Import VM con FreeBSD
2) Esegui questo script: ./install.sh
3) Avvia server: sh start.sh start
4) Modifica client: file serverinfo.py -> cambia IP con quello della VM
EOF

echo "?? Manuale testuale creato in ~/infinitymetin2_guida.txt"
echo "Script finito. Buon gaming!"
