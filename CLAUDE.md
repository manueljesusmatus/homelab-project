# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repositorio

Configuración de infraestructura homelab personal desplegado en Raspberry Pi. Usa Ansible para orquestar stacks de Docker Compose.

## Comandos principales

```bash
# Desplegar todos los stacks (excluyendo down e init)
sudo ansible-playbook ansible/lab_playbook.yml --verbose --skip-tags "down,init"

# Solo levantar contenedores
sudo ansible-playbook ansible/lab_playbook.yml --verbose --tags "up"

# Solo configuración inicial (red Docker, directorios)
sudo ansible-playbook ansible/lab_playbook.yml --verbose --tags "init"

# Bajar todos los stacks
sudo ansible-playbook ansible/lab_playbook.yml --verbose --tags "down"

# Backup manual
sudo sh backup/backup.sh

# Subir backup a MEGA
sudo sh backup/mega.sh

# Restaurar desde MEGA
sh backup/restore.sh
```

## Arquitectura

### Patrón general

Cada servicio tiene dos componentes:
1. `docker/<stack>/docker-compose.yml` — definición del servicio con variables de entorno
2. `ansible/stacks/<stack>.yml` — playbook que crea volúmenes, copia configs y ejecuta el compose

El playbook principal `ansible/lab_playbook.yml` itera sobre la lista `stacks` y llama a cada `ansible/stacks/<stack>.yml`. Los stacks en `disabled_stacks` se saltan.

### Variables de configuración

Todas las variables sensibles van en `ansible/group_vars/all.yml` (no versionado; plantilla en `all.example.yml`). Las variables se inyectan como `environment:` al ejecutar `community.docker.docker_compose_v2`.

### Red Docker

Todos los servicios comparten la red externa `traefik_net` (subnet `172.21.0.0/24`). Traefik actúa como reverse proxy con TLS via Cloudflare DNS challenge.

### Exposición de servicios

Los servicios se exponen con labels de Traefik:
```yaml
- "traefik.enable=true"
- "traefik.http.routers.<nombre>.rule=Host(`${DOMINIO}`)"
- "traefik.http.routers.<nombre>.entrypoints=websecure"
- "traefik.http.routers.<nombre>.tls.certresolver=cloudflare"
- "traefik.http.services.<nombre>.loadbalancer.server.port=<puerto>"
```

### Watchtower

Todos los contenedores gestionados tienen el label `com.centurylinklabs.watchtower.enable=true` para actualizaciones automáticas de imágenes.

### Stacks activos

| Stack | Descripción |
|-------|-------------|
| traefik-proxy | Reverse proxy + TLS |
| portainer | Gestión Docker UI |
| watchtower | Auto-updates |
| gitea | Git self-hosted |
| monitoreo | Prometheus + Grafana + node_exporter + cAdvisor |
| homarr | Dashboard |
| navidrome | Streaming de música |
| cloudbeaver | DB manager web |
| uptimekuma | Monitor de uptime |
| jenkins | CI/CD |
| microbin | Pastebin self-hosted |
| artifactory | Registry Docker (deshabilitado) |

### Backup

`backup/backup.sh` comprime `~/docker/` en `~/backup/backup-YYYY-MM-DD.zip` y elimina backups >7 días. `backup/mega.sh` sube a MEGA via megatools (requiere `~/.megarc`).

## Agregar un nuevo stack

1. Crear `docker/<nombre>/docker-compose.yml` con labels de Traefik y Watchtower
2. Crear `ansible/stacks/<nombre>.yml` que cree directorios, copie configs y ejecute compose
3. Agregar `<nombre>` a la lista `stacks` en `ansible/lab_playbook.yml`
4. Agregar variables necesarias a `ansible/group_vars/all.example.yml` y al `all.yml` real
