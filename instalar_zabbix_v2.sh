#!/bin/bash

# Script de desinstalación de Zabbix Server + PostgreSQL + Nginx en RHEL 9 / Rocky / AlmaLinux
# Autor: Tú :)

set -e
set -u

echo "### Deteniendo servicios..."
SERVICES=("zabbix-server" "zabbix-agent" "nginx" "php-fpm" "postgresql")
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "→ Deteniendo servicio $service"
        sudo systemctl stop "$service"
    else
        echo "→ Servicio $service no está activo"
    fi

    if systemctl is-enabled --quiet "$service"; then
        echo "→ Deshabilitando servicio $service"
        sudo systemctl disable "$service"
    else
        echo "→ Servicio $service ya estaba deshabilitado"
    fi
done

echo "### Eliminando paquetes instalados..."
sudo dnf remove -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent postgresql-server postgresql-contrib nginx php-fpm nano glibc-langpack-es || true

echo "### Eliminando repositorio de Zabbix..."
if [ -f /etc/yum.repos.d/zabbix.repo ]; then
    echo "→ Eliminando archivo de repositorio Zabbix"
    sudo rm -f /etc/yum.repos.d/zabbix.repo
else
    echo "→ Repositorio Zabbix ya estaba eliminado"
fi
sudo dnf clean all

echo "### Eliminando base de datos y usuario de PostgreSQL..."
sudo systemctl enable --now postgresql || true

DB_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='zabbix'")
if [ "$DB_EXISTS" = "1" ]; then
    echo "→ Eliminando base de datos 'zabbix'"
    sudo -u postgres psql -c "DROP DATABASE zabbix;"
else
    echo "→ La base de datos 'zabbix' no existe"
fi

USER_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='zabbix'")
if [ "$USER_EXISTS" = "1" ]; then
    echo "→ Eliminando usuario 'zabbix'"
    sudo -u postgres psql -c "DROP USER zabbix;"
else
    echo "→ El usuario 'zabbix' no existe"
fi

sudo systemctl stop postgresql
sudo systemctl disable postgresql

echo "### Eliminando archivos de configuración restantes..."
FILES_AND_DIRS=(
    "/etc/zabbix"
    "/var/lib/pgsql"
    "/etc/nginx/conf.d/zabbix.conf"
    "/var/lib/zabbix"
    "/var/log/zabbix"
    "/var/log/nginx"
    "/var/log/php-fpm"
)

for path in "${FILES_AND_DIRS[@]}"; do
    if [ -e "$path" ]; then
        echo "→ Eliminando $path"
        sudo rm -rf "$path"
    else
        echo "→ $path no existe"
    fi
done

echo "### Opcional: Limpiando reglas de firewall..."
# sudo firewall-cmd --permanent --remove-port=8080/tcp
# sudo firewall-cmd --reload

echo "### Opcional: Restaurando configuración de localización..."
# sudo localectl set-locale LANG=en_US.UTF-8

echo "### Desinstalación completada!"
