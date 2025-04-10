#!/bin/bash

# Script automático de instalación de Zabbix Server + PostgreSQL + Nginx en RHEL 9 / Rocky / AlmaLinux
# Autor: Tú :)

set -e  # Si falla algo, para el script
set -u  # Si se usa una variable no definida, para el script

# Variables
DB_PASSWORD="zabbix"
ZABBIX_VERSION="7.2"

echo "### Actualizando sistema..."
sudo dnf update -y

echo "### Instalando repositorio de Zabbix..."
sudo rpm -Uvh https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/rhel/9/noarch/zabbix-release-latest-${ZABBIX_VERSION}.el9.noarch.rpm
sudo dnf clean all

echo "### Instalando paquetes necesarios..."
sudo dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent postgresql-server postgresql-contrib nano glibc-langpack-es

echo "### Inicializando PostgreSQL..."
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql

echo "### Configurando base de datos PostgreSQL para Zabbix..."
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '${DB_PASSWORD}';"
sudo -u postgres psql -c "CREATE DATABASE zabbix OWNER zabbix;"
sudo -u postgres psql -c "\l"

echo "### Importando esquema inicial de la base de datos..."
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

echo "### Configurando zabbix_server.conf..."
sudo sed -i "s|^# DBPassword=|DBPassword=${DB_PASSWORD}|" /etc/zabbix/zabbix_server.conf

echo "### Configurando nginx para Zabbix..."
SERVER_IP=$(hostname -I | awk '{print $1}')
sudo sed -i "s|#\s*listen\s*8080;|listen 8080;|" /etc/nginx/conf.d/zabbix.conf
sudo sed -i "s|#\s*server_name\s*example.com;|server_name ${SERVER_IP};|" /etc/nginx/conf.d/zabbix.conf

echo "### Configurando idioma del sistema..."
sudo localectl set-locale LANG=es_ES.UTF-8
source /etc/locale.conf

echo "### Configurando pg_hba.conf para acceso con contraseña..."
PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
sudo sed -i "s|local\s\+all\s\+all\s\+peer|local all all md5|" $PG_HBA
sudo sed -i "s|host\s\+all\s\+all\s\+127\.0\.0\.1/32\s\+ident|host all all 127.0.0.1/32 md5|" $PG_HBA
sudo sed -i "s|host\s\+all\s\+all\s\+::1/128\s\+ident|host all all ::1/128 md5|" $PG_HBA

echo "### Otorgando permisos en la base de datos..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE zabbix TO zabbix;"

echo "### Reiniciando servicios..."
sudo systemctl restart postgresql
sudo systemctl enable zabbix-server zabbix-agent nginx php-fpm
sudo systemctl restart zabbix-server zabbix-agent nginx php-fpm

echo "### Instalación completada correctamente."
echo "Accede a: http://${SERVER_IP}:8080/setup.php"
