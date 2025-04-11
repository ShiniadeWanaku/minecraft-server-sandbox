#!/bin/bash

set -e

PYTHON_VERSION=3.12.2
INSTALL_DIR="/usr/local"
TEMP_DIR="/tmp/python-build"

echo "Instalando dependencias..."
sudo apt update
sudo apt install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    libffi-dev \
    uuid-dev \
    wget \
    curl \
    git \
    libnss3-dev \
    tk-dev \
    xz-utils

echo "Descargando Python $PYTHON_VERSION..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
tar -xf "Python-${PYTHON_VERSION}.tgz"
cd "Python-${PYTHON_VERSION}"

echo "Configurando compilación..."
./configure --enable-optimizations --prefix=$INSTALL_DIR

echo "Compilando e instalando (esto puede tardar)..."
make -j$(nproc)
sudo make altinstall

echo "Python $PYTHON_VERSION instalado como python3.12"
python3.12 --version