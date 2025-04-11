#!/bin/bash

# Script de desinstalación de Zabbix Server + PostgreSQL + Nginx en RHEL 9 / Rocky / AlmaLinux
# Autor: Tú :)

set -e
set -u

echo "### Deteniendo servicios..."
sudo systemctl stop zabbix-server zabbix-agent nginx php-fpm postgresql || true
sudo systemctl disable zabbix-server zabbix-agent nginx php-fpm postgresql || true

echo "### Eliminando paquetes instalados..."
sudo dnf remove -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent postgresql-server postgresql-contrib nginx php-fpm nano glibc-langpack-es

echo "### Eliminando repositorio de Zabbix..."
sudo rm -f /etc/yum.repos.d/zabbix.repo
sudo dnf clean all

echo "### Eliminando base de datos y usuario de PostgreSQL..."
sudo systemctl enable --now postgresql || true
sudo -u postgres psql -c "DROP DATABASE IF EXISTS zabbix;" || true
sudo -u postgres psql -c "DROP USER IF EXISTS zabbix;" || true
sudo systemctl stop postgresql
sudo systemctl disable postgresql

echo "### Eliminando archivos de configuración restantes..."
sudo rm -rf /etc/zabbix
sudo rm -rf /var/lib/pgsql
sudo rm -rf /etc/nginx/conf.d/zabbix.conf
sudo rm -rf /var/lib/zabbix
sudo rm -rf /var/log/zabbix
sudo rm -rf /var/log/nginx
sudo rm -rf /var/log/php-fpm

echo "### Verificando limpieza completa..."

echo "--- Servicios activos relacionados:"
sudo systemctl list-units --type=service | grep -E 'zabbix|nginx|postgres|php' || echo "No hay servicios activos."

echo "--- Procesos en ejecución relacionados:"
ps aux | grep -E 'zabbix|nginx|postgres|php' | grep -v grep || echo "No hay procesos en ejecución."

echo "--- Puertos en escucha relacionados:"
sudo ss -tuln | grep -E '80|443|5432|10050|10051' || echo "No hay puertos en uso."

echo "--- Paquetes instalados relacionados:"
rpm -qa | grep -E 'zabbix|postgres|nginx|php' || echo "No hay paquetes instalados."

echo "--- Directorios residuales:"
for dir in /etc/zabbix /var/lib/pgsql /etc/nginx/conf.d/zabbix.conf /var/log/zabbix /var/log/nginx /var/log/php-fpm; do
    if [ -e "$dir" ]; then
        echo "Existe: $dir"
    else
        echo "No existe: $dir"
    fi
done

echo "--- Repositorios habilitados:"
sudo dnf repolist | grep zabbix || echo "No hay repositorios de Zabbix."

echo "--- Reglas de firewall relacionadas (puertos comunes):"
sudo firewall-cmd --list-all | grep -E '80|443|5432|10050|10051' || echo "No hay reglas de firewall para estos puertos."

echo "### Desinstalación y limpieza completadas ✅"
