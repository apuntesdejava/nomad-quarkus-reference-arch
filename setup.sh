#!/bin/bash
# setup.sh - La Revuelta HashiCorp en WSL

echo "🔥 Iniciando configuración en WSL..."

# 1. Asegurar dependencias básicas
sudo apt-get update && sudo apt-get install -y curl unzip gnupg software-properties-common

# 2. Instalar Java 25 (Si no lo tienes ya)
sudo apt-get install -y openjdk-25-jdk

# 3. Añadir el repositorio oficial de HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

# 4. Instalar Nomad y Consul
sudo apt-get update && sudo apt-get install -y nomad consul

# 5. Verificaciones de Docker (WSL suele usar Docker Desktop o Docker nativo)
if ! command -v docker &> /dev/null; then
    echo "⚠️  ADVERTENCIA: Docker no parece estar instalado o en el PATH."
    echo "    Asegúrate de tener Docker Desktop corriendo en Windows y la integración WSL activada."
else
    echo "✅ Docker detectado."
fi

echo "🚀 ¡Instalación completada! Ahora corre: 'nomad agent -dev' y 'consul agent -dev'"
