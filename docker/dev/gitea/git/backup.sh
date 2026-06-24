#!/bin/bash
set -a
source "../../../ansible/group_vars/gitea.env"
set +a

BACKUP_FILE="/backup/gitea_dump.dump"

mkdir -p "$ROOT_DATA_DIR/gitea/backups"
docker exec -t $GITEA_CONTAINER pg_dump -U $GITEA_USER -C -Fc $GITEA_DB -f "$BACKUP_FILE"