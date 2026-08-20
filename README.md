# Odoo-Deployment

A ready-to-run **Odoo 18** local install, using Docker Compose (Odoo + PostgreSQL).
Targets Ubuntu/Debian, but works on any Docker-capable machine.

## Prerequisites

- Ubuntu/Debian (or any Linux/macOS/Windows+WSL2 host with Docker)
- ~4 GB free RAM, ~2 GB free disk

## Quick start (automated)

```bash
git clone https://github.com/mehak-seetlani/odoo-deployment.git
cd odoo-deployment
./install.sh
```

`install.sh` will:
1. Install Docker Engine + the Compose plugin if they're not already present (Ubuntu/Debian).
2. Create a `.env` file from `.env.example` with a randomly generated database password.
3. Pull the `odoo:18.0` and `postgres:15` images and start both containers.

Once it finishes, open **http://localhost:8069** and create your first database
(the master password is not required for local dev; leave it blank or set one
via `admin_passwd` in `config/odoo.conf` if you want to lock down `/web/database/manager`).

## Manual install

If you already have Docker + the Compose plugin installed:

```bash
cp .env.example .env
# edit .env to set your own POSTGRES_PASSWORD, then update
# config/odoo.conf's db_password to match

docker compose pull
docker compose up -d
```

## Project layout

```
.
├── docker-compose.yml   # odoo + postgres services
├── .env.example          # copy to .env and customize
├── config/
│   └── odoo.conf          # Odoo server config (mounted at /etc/odoo/odoo.conf)
├── addons/                # put custom/third-party Odoo modules here
└── install.sh             # one-shot Ubuntu/Debian installer
```

Custom addons: drop any Odoo module folder into `./addons/`, then restart:

```bash
docker compose restart odoo
```

## Common operations

| Task                          | Command                              |
|--------------------------------|---------------------------------------|
| View logs                      | `docker compose logs -f odoo`        |
| Stop the stack                 | `docker compose down`                |
| Stop and wipe all data         | `docker compose down -v`             |
| Restart after a config change  | `docker compose restart odoo`        |
| Update Odoo to latest 18.0     | `docker compose pull && docker compose up -d` |

## Ports

| Service          | Host port (default) | Purpose                     |
|-------------------|----------------------|------------------------------|
| Odoo web UI       | 8069                 | http://localhost:8069        |
| Odoo longpolling  | 8072                 | live chat / bus notifications|

Change `HOST_HTTP_PORT` / `HOST_LONGPOLLING_PORT` in `.env` if these ports are
already in use on your machine.

## Data persistence

Two named Docker volumes persist your data across restarts:
- `odoo-db-data` — PostgreSQL data
- `odoo-web-data` — Odoo filestore (attachments, etc.)

Removing them (`docker compose down -v`) deletes all databases and uploaded files.

## Troubleshooting

- **Port already in use**: change `HOST_HTTP_PORT` in `.env`.
- **Permission denied running docker**: log out/in after `install.sh` adds you
  to the `docker` group, or prefix commands with `sudo`.
- **Slow first start**: the first boot initializes PostgreSQL and Odoo's base
  modules; watch progress with `docker compose logs -f odoo`.
