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

echo "### Opcional: Limpiando reglas de firewall..."
# sudo firewall-cmd --permanent --remove-port=8080/tcp
# sudo firewall-cmd --reload

echo "### Opcional: Restaurando configuración de localización..."
# sudo localectl set-locale LANG=en_US.UTF-8

echo "### Desinstalación completada!"
