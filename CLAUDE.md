# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repositorio

Configuración de infraestructura homelab personal desplegado en Raspberry Pi y VMs Linux. Usa Ansible para orquestar stacks de Docker Compose.

## Comandos principales

```bash
# Inicializar Raspberry Pi (docker + config + ssh + m2 + casaos + cgroups)
ansible-playbook ansible/lab_playbook.yml --tags "raspberry" --ask-become-pass

# Inicializar VM Linux (docker + config)
ansible-playbook ansible/lab_playbook.yml --tags "linux-vm" --ask-become-pass

# Levantar todos los stacks activos
ansible-playbook ansible/lab_playbook.yml --tags "containers_up"

# Bajar todos los stacks
ansible-playbook ansible/lab_playbook.yml --tags "containers_down"

# Backup a S3 (instala rclone, crea cron semanal sábados 3 AM)
ansible-playbook ansible/lab_playbook.yml --tags "containers_backup" --ask-become-pass

# Restaurar desde S3 (requiere que rclone ya esté configurado)
ansible-playbook ansible/lab_playbook.yml --tags "containers_restore" --ask-become-pass

# Tags granulares
# --tags "docker"   → instala Docker y crea red traefik_net
# --tags "config"   → alias git + directorios base
# --tags "ssh"      → añade clave pública desde GitHub (solo raspberry)
# --tags "m2"       → monta disco M.2 por UUID (solo raspberry)
# --tags "casaos"   → instala CasaOS (solo raspberry)
```

## Arquitectura

### Plataformas soportadas

| Tag | Plataforma | Tasks incluidas |
|-----|-----------|----------------|
| `raspberry` | Raspberry Pi | `docker` + `config` + `ssh` + `m2` + `casaos` + `mem_issue` |
| `linux-vm` | VM Linux genérica | `docker` + `config` |

Las tasks `ssh`, `m2`, `casaos` y `mem_issue` solo aplican a Raspberry Pi.

### Patrón general

Los servicios se organizan por categoría: `infra`, `dashboard`, `monitoring`, `dev`, `media`, `data`, `tools`.

Cada servicio tiene dos componentes:
1. `docker/<categoría>/<stack>/docker-compose.yml` — definición del servicio con variables de entorno
2. `ansible/stacks/containers/<categoría>/<stack>.yml` — playbook que crea directorios, copia configs y ejecuta el compose

El playbook principal `ansible/lab_playbook.yml` itera sobre la lista `stacks` (en formato `<categoría>/<nombre>`) y llama a cada `ansible/stacks/containers/{{ item }}.yml`. Los stacks en `disabled_stacks` se saltan.

### Variables de configuración

Todas las variables sensibles van en `ansible/group_vars/all.yml` (no versionado; plantilla en `all.example.yml`). Las variables se inyectan como `environment:` al ejecutar `community.docker.docker_compose_v2`.

`ROOT_DATA_DIR` es la variable clave que apunta al directorio raíz de datos Docker (volúmenes, configs).

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

### Stacks activos / deshabilitados

| Stack | Categoría | Estado | Descripción |
|-------|-----------|--------|-------------|
| infra/traefik-proxy | infra | activo | Reverse proxy + TLS |
| infra/watchtower | infra | activo | Auto-updates |
| monitoring/uptimekuma | monitoring | activo | Monitor de uptime |
| dashboard/glance | dashboard | activo | Dashboard |
| dashboard/portainer | dashboard | activo | Gestión Docker UI |
| data/syncthing | data | activo | Sincronización de archivos |
| data/valkey | data | activo | Cache in-memory |
| media/transmission | media | activo | Cliente torrent |
| dev/excalidraw | dev | activo | Pizarra colaborativa |
| tools/microbin | tools | activo | Pastebin self-hosted |
| dashboard/homarr | dashboard | deshabilitado | Dashboard alternativo |
| monitoring/monitoreo | monitoring | deshabilitado | Prometheus + Grafana |
| dev/artifactory | dev | deshabilitado | Registry Docker |
| dev/cloudbeaver | dev | deshabilitado | DB manager web |
| dev/gitea | dev | deshabilitado | Git self-hosted |
| dev/jenkins | dev | deshabilitado | CI/CD |
| media/navidrome | media | deshabilitado | Streaming de música |
| data/redis | data | deshabilitado | Cache (reemplazado por valkey) |

Para habilitar/deshabilitar un stack: moverlo entre las listas `stacks` y `disabled_stacks` en `ansible/lab_playbook.yml`.

### Backup

El backup usa **rclone** para sincronizar `ROOT_DATA_DIR` hacia S3 (`BACKUP_S3_BUCKET`). El tag `containers_backup` instala rclone, genera `~/.config/rclone/rclone.conf` (no sobreescribe si existe) y crea un cron job semanal. El tag `containers_restore` hace el sync inverso S3 → local.

## Agregar un nuevo stack

1. Elegir la categoría correspondiente: `infra`, `dashboard`, `monitoring`, `dev`, `media`, `data`, `tools`
2. Crear `docker/<categoría>/<nombre>/docker-compose.yml` con labels de Traefik y Watchtower
3. Crear `ansible/stacks/containers/<categoría>/<nombre>.yml` que cree directorios, copie configs y ejecute compose
4. Agregar `<categoría>/<nombre>` a la lista `stacks` en `ansible/lab_playbook.yml`
5. Agregar variables necesarias a `ansible/group_vars/all.example.yml` y al `all.yml` real
