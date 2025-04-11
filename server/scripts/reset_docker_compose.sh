#!/bin/bash
set -e

echo "Deteniendo y eliminando contenedores..."
sudo docker compose down --volumes --remove-orphans

echo "Eliminando imágenes de Prometheus y Grafana..."
PROM_IMAGE=$(sudo docker images -q prom/prometheus)
GRAFANA_IMAGE=$(sudo docker images -q grafana/grafana)

if [ -n "$PROM_IMAGE" ]; then
    sudo docker rmi $PROM_IMAGE
else
    echo "No se encontró la imagen de Prometheus."
fi

if [ -n "$GRAFANA_IMAGE" ]; then
    sudo docker rmi $GRAFANA_IMAGE
else
    echo "No se encontró la imagen de Grafana."
fi

echo "Eliminando volúmenes huérfanos..."
sudo docker volume prune -f

echo "Eliminando caché de compilación..."
sudo docker builder prune -a -f

echo "Reconstruyendo contenedores sin caché..."
sudo docker compose build --no-cache

echo "Levantando contenedores..."
sudo docker compose up -d

echo "Proceso completado. Verifica los contenedores con 'docker ps'."