# Refactorizar sistema de backup del homelab

## Contexto del proyecto

Proyecto de infraestructura homelab en Raspberry Pi 5. Usa Ansible para orquestar 
stacks de Docker Compose. Lee CLAUDE.md para entender la arquitectura completa antes 
de proponer cualquier cambio.

## Objetivo

Reemplazar el sistema de backup actual (backup.sh + mega.sh usando megatools) por 
una solución basada en rclone + AWS S3, integrada nativamente en Ansible.

## Stack tecnológico del nuevo sistema

- **Herramienta**: rclone
- **Destino**: AWS S3
- **Credenciales**: AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY vía variables Ansible

## Requerimientos de backup

### Ansible tag: `backup`

1. Instalar rclone si no está presente (via apt o instalador oficial)
2. Generar la configuración de rclone para S3 en `~/.config/rclone/rclone.conf`
   a partir de las variables Ansible (idempotente, no sobreescribir si ya existe)
3. Ejecutar sync de los volúmenes Docker hacia S3:
   - Origen: `{{ ROOT_DATA_DIR }}/docker`
   - Dentro de esa carpeta cada servicio tiene su propia subcarpeta de volúmenes
     EJ: /home/mmatush/docker/homarr/data, /home/mmatush/docker/gitea/db, etc.
   - Destino: bucket S3 configurable via variable `BACKUP_S3_BUCKET`
   - Comando: `rclone sync` con flags apropiados para logging
4. Crear cron job que ejecute el backup los **sábados a las 3 AM**:
   - El cron debe llamar al propio playbook Ansible con el tag `backup`:
     `ansible-playbook <path>/ansible/lab_playbook.yml --tags "backup"`
   - Usar `ansible.builtin.cron` con un `name` único descriptivo
   - Al ser idempotente, re-ejecutar el playbook no duplicará el cron ni la config

### Ansible tag: `restore`

1. Instalar rclone si no está presente (igual que en backup, idempotente)
2. Verificar que la configuración de rclone exista (fallar con mensaje claro si no)
3. Detener todos los contenedores Docker activos antes de restaurar
4. Ejecutar `rclone sync` en dirección inversa: S3 → `{{ ROOT_DATA_DIR }}/docker`
5. **No levantar los contenedores** — eso lo hace el tag `up` por separado
   El flujo esperado post-restore es:
   `ansible-playbook lab_playbook.yml --tags restore`
   seguido de:
   `ansible-playbook lab_playbook.yml --tags up`

## Escalabilidad

- Todos los volúmenes de todos los servicios viven bajo `{{ ROOT_DATA_DIR }}/docker`
- El sync apunta a esa carpeta base completa, sin listar servicios uno a uno
- Agregar un nuevo servicio no requiere ningún cambio en la lógica de backup

## Variables nuevas a agregar en `ansible/group_vars/all.example.yml`

- `BACKUP_S3_BUCKET`: nombre del bucket S3
- `BACKUP_S3_REGION`: región AWS (ej: us-east-1)
- `AWS_ACCESS_KEY_ID`: access key de AWS
- `AWS_SECRET_ACCESS_KEY`: secret key de AWS

## Archivos a crear

- `ansible/stacks/backup.yml` — tareas: install rclone + config + sync + cron
- `ansible/stacks/restore.yml` — tareas: install rclone + verify config + stop containers + sync inverso

## Archivos a modificar

- `ansible/group_vars/all.example.yml` — agregar las 4 variables nuevas
- `ansible/lab_playbook.yml` — agregar los tags `backup` y `restore` como tasks
  independientes fuera del loop de stacks, siguiendo este patrón:

    - name: Ejecutar backup a S3
      import_tasks: "stacks/backup.yml"
      tags:
        - backup

    - name: Restaurar desde S3
      import_tasks: "stacks/restore.yml"
      tags:
        - restore

## No hacer

- No modificar ningún docker-compose.yml existente
- No modificar los scripts en backup/ (dejarlos como legacy)
- No agregar backup ni restore a la lista `stacks` del loop principal
- No levantar contenedores dentro del tag restore