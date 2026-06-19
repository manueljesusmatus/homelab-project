# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repositorio

Configuración de infraestructura homelab personal desplegado en Raspberry Pi. Usa Ansible para orquestar stacks de Docker Compose.

## Comandos principales

```bash
# Desplegar todos los stacks activos
sudo ansible-playbook ansible/lab_playbook.yml --verbose --skip-tags "down,init"

# Solo levantar contenedores
sudo ansible-playbook ansible/lab_playbook.yml --verbose --tags "up"

# Solo configuración inicial (Docker, red, cgroups, CasaOS)
sudo ansible-playbook ansible/lab_playbook.yml --verbose --tags "init"

# Bajar todos los stacks
sudo ansible-playbook ansible/lab_playbook.yml --verbose --tags "down"

# Backup manual a S3 (también instala rclone y crea cron semanal sabados 3 AM)
sudo ansible-playbook ansible/lab_playbook.yml --tags "backup"

# Restaurar desde S3 (requiere que rclone ya esté configurado; corre backup primero)
sudo ansible-playbook ansible/lab_playbook.yml --tags "restore"
```

## Arquitectura

### Patrón general

Cada servicio tiene dos componentes:
1. `docker/<stack>/docker-compose.yml` — definición del servicio con variables de entorno
2. `ansible/stacks/<stack>.yml` — playbook que crea directorios, copia configs y ejecuta el compose

El playbook principal `ansible/lab_playbook.yml` itera sobre la lista `stacks` y llama a cada `ansible/stacks/<stack>.yml`. Los stacks en `disabled_stacks` se saltan.

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

| Stack | Estado | Descripción |
|-------|--------|-------------|
| traefik-proxy | activo | Reverse proxy + TLS |
| watchtower | activo | Auto-updates |
| uptimekuma | activo | Monitor de uptime |
| homarr | activo | Dashboard |
| microbin | activo | Pastebin self-hosted |
| syncthing | activo | Sincronización de archivos |
| portainer | activo | Gestión Docker UI |
| artifactory | deshabilitado | Registry Docker |
| cloudbeaver | deshabilitado | DB manager web |
| gitea | deshabilitado | Git self-hosted |
| jenkins | deshabilitado | CI/CD |
| monitoreo | deshabilitado | Prometheus + Grafana + node_exporter + cAdvisor |
| navidrome | deshabilitado | Streaming de música |
| redis | deshabilitado | Cache |

Para habilitar/deshabilitar un stack: moverlo entre las listas `stacks` y `disabled_stacks` en `ansible/lab_playbook.yml`.

### Backup

El backup usa **rclone** para sincronizar `ROOT_DATA_DIR` hacia S3 (`BACKUP_S3_BUCKET`). El tag `backup` instala rclone, genera `~/.config/rclone/rclone.conf` (no sobreescribe si existe) y crea un cron job semanal. El tag `restore` hace el sync inverso S3 → local.

## Agregar un nuevo stack

1. Crear `docker/<nombre>/docker-compose.yml` con labels de Traefik y Watchtower
2. Crear `ansible/stacks/<nombre>.yml` que cree directorios, copie configs y ejecute compose
3. Agregar `<nombre>` a la lista `stacks` en `ansible/lab_playbook.yml`
4. Agregar variables necesarias a `ansible/group_vars/all.example.yml` y al `all.yml` real
