Quiero dockerizar Syncthing en mi homelab siguiendo exactamente los patrones existentes del proyecto.
Contexto del proyecto:

Stack: Raspberry Pi 5, Docker, Ansible, Traefik
Patrón de stacks: cada servicio tiene docker/<nombre>/docker-compose.yml y ansible/stacks/<nombre>.yml
Variables globales en ansible/group_vars/all.yml (ver all.example.yml como referencia)
El playbook principal es ansible/lab_playbook.yml

Requerimientos para Syncthing:

Imagen: linuxserver/syncthing:latest
UI accesible mediante Traefik (igual que el resto de servicios), con variable SYNCTHING_DOMAIN
Puerto de sincronización 22000 expuesto directamente (TCP y UDP), igual que Gitea expone el 2222 para SSH
Volúmenes:

Config en ${ROOT_DATA_DIR}/syncthing/config
Vaults de Obsidian montados desde una variable ${SYNCTHING_DATA_DIR} que se pasa como environment desde Ansible


Variables nuevas a agregar en all.example.yml: SYNCTHING_DOMAIN y SYNCTHING_DATA_DIR
Label de Watchtower para actualizaciones automáticas
Agregar syncthing a la lista stacks en lab_playbook.yml (no en disabled_stacks)
Seguir la estructura de stacks simples como uptimekuma.yml como referencia

No hacer:

No modificar archivos existentes salvo all.example.yml y lab_playbook.yml

Por favor genera un plan detallado antes de hacer cualquier cambio.

