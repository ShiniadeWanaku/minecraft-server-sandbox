#!/bin/bash
set -e

# Eliminar repositorios antiguos de Docker si existen
echo "Eliminando repositorios antiguos de Docker..."
sudo rm -f /etc/apt/sources.list.d/docker.list

# Actualizar el sistema
echo "Actualizando el sistema..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Descargar e instalar Docker usando el script oficial
echo "Instalando Docker..."
curl -fsSL https://get.docker.com | sudo sh

# Verificar la instalación de Docker
echo "Verificando la instalación de Docker..."
sudo docker --version

# Agregar el usuario actual al grupo 'docker'
echo "Agregando el usuario al grupo Docker..."
sudo usermod -aG docker $USER

# Habilitar y arrancar Docker
echo "Habilitando y arrancando el servicio Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# Probar que Docker esté funcionando correctamente
echo "Probando Docker..."
sudo docker run hello-world

echo "Instalación de Docker completada con éxito."
