Migra el stack de Homarr a la versión 1.0. Esta versión es un rewrite completo e incompatible con la estructura anterior.
 
---
 
## 📝 Archivos a modificar
 
### `docker/homarr/docker-compose.yml`
 
Reemplazar completamente con la nueva configuración v1.0:
 
- Nueva imagen: `ghcr.io/homarr-labs/homarr:latest`
- El volumen de datos ahora es un único mount: `${ROOT_DATA_DIR}/homarr/appdata:/appdata`
- Eliminar los tres volúmenes anteriores (`configs`, `icons`, `data`)
- Mantener el mount de `/var/run/docker.sock`
- Agregar variable de entorno `SECRET_ENCRYPTION_KEY=${HOMARR_SECRET_KEY}`
- Mantener todos los labels de Traefik y Watchtower existentes, sin cambios
- Mantener la red `traefik_net`
---
 
### `ansible/stacks/homarr.yml`
 
Reemplazar completamente con la nueva lógica:
 
1. Crear directorio `{{ ROOT_DATA_DIR }}/homarr/appdata`
2. Verificar si existe el archivo `{{ ROOT_DATA_DIR }}/homarr/secret_key`
3. Si **no existe**: generar una key con `openssl rand -hex 32`, guardarla en ese archivo con permisos `0600`
4. Leer el contenido de `{{ ROOT_DATA_DIR }}/homarr/secret_key` en una variable `homarr_secret_key`
5. Ejecutar `community.docker.docker_compose_v2` pasando en el bloque `environment`:
   - `ROOT_DATA_DIR`
   - `TIMEZONE`
   - `HOMARR_DOMAIN`
   - `HOMARR_SECRET_KEY: "{{ homarr_secret_key }}"`
6. Mostrar resultado con debug
---
 
## 🗑️ Archivos a eliminar
 
- `docker/homarr/config/default.json`
---
 
## 🚫 Restricciones
 
- No modificar `ansible/group_vars/all.example.yml`
- No modificar `ansible/lab_playbook.yml`
- No modificar ningún otro `docker-compose.yml`
- No agregar `HOMARR_SECRET_KEY` como variable en `all.example.yml` — la key es generada y persistida por Ansible automáticamente, no configurada por el usuario