# homelab-project
Diferentes archivos de configuración para instalar aplicaciones en homelab personal

## raspberry pi
Orden de levantamiento de los contenedores docker

> sudo ansible-playbook ansible/lab_playbook.yml --verbose --skip-tags "docker_compose_down"
