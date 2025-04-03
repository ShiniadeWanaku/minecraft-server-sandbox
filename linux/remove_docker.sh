#!/bin/bash
set -e

# Eliminar contenedores y volúmenes de Docker
echo "Eliminando contenedores y volúmenes de Docker..."
sudo docker system prune -af

# Eliminar Docker y sus dependencias
echo "Eliminando Docker..."
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Eliminar dependencias no necesarias
echo "Eliminando dependencias no necesarias..."
sudo apt-get autoremove -y
sudo apt-get clean

# Eliminar archivos y configuraciones relacionadas con Docker
echo "Eliminando archivos y configuraciones de Docker..."
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
sudo rm -rf /etc/apt/sources.list.d/docker.list
sudo rm -rf /etc/apt/keyrings/docker.asc

# Eliminar el grupo Docker
echo "Eliminando el grupo Docker..."
sudo groupdel docker

# Restaurar el estado del sistema
echo "Restaurando estado del sistema..."
sudo apt-get update

echo "Reversión de la instalación de Docker completada con éxito."