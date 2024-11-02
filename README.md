# homelab-project
Diferentes archivos de configuración para instalar aplicaciones en homelab personal

## raspberry pi
Orden de levantamiento de los contenedores docker

> ansible-playbook lab_playbook.yml

1. portainer
2. watchtower
3. coolify
4. traefik
5. monitoreo (Grafana + Prometheus)
6. gitea