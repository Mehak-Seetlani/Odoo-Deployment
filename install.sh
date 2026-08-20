#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Odoo 18 - one-shot local installer for Ubuntu/Debian
#
# What it does:
#   1. Installs Docker Engine + the Docker Compose plugin if not present.
#   2. Creates a .env file from .env.example (if missing) with a random
#      Postgres password.
#   3. Pulls the Odoo 18 and PostgreSQL images and starts the stack.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Checking for Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "==> Docker not found. Installing Docker Engine..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  ARCH="$(dpkg --print-architecture)"
  CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  echo \
    "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "==> Adding $USER to the docker group (log out/in for this to take effect without sudo)..."
  sudo usermod -aG docker "$USER" || true
else
  echo "==> Docker already installed: $(docker --version)"
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: 'docker compose' plugin is not available. Please install docker-compose-plugin and re-run." >&2
  exit 1
fi

echo "==> Preparing environment file..."
if [ ! -f .env ]; then
  cp .env.example .env
  # Generate a random password for Postgres instead of the placeholder.
  RANDOM_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)"
  sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${RANDOM_PASSWORD}/" .env
  # Keep odoo.conf's db_password in sync with the generated one.
  sed -i "s/^db_password = .*/db_password = ${RANDOM_PASSWORD}/" config/odoo.conf
  echo "==> Created .env with a generated Postgres password."
else
  echo "==> .env already exists, leaving it untouched."
fi

echo "==> Pulling images and starting the Odoo stack..."
if docker compose version >/dev/null 2>&1 && docker compose ls >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  COMPOSE="sudo docker compose"
fi

$COMPOSE pull
$COMPOSE up -d

echo ""
echo "==> Odoo is starting up."
echo "    Web UI:  http://localhost:$(grep -E '^HOST_HTTP_PORT=' .env | cut -d= -f2 || echo 8069)"
echo "    It may take up to a minute on first run while the database initializes."
echo "    View logs with: docker compose logs -f odoo"
