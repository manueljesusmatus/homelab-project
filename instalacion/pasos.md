
### Actualizar el sistema
```bash
sudo apt update && sudo apt upgrade -y
```

---

### Instalar [CasaOS](https://wiki.casaos.io/en/get-started)
```bash
curl -fsSL https://get.casaos.io | sudo bash
```

---

### Instalar [pipx](https://github.com/pypa/pipx)
```bash
sudo apt install pipx -y
```

---

### Instalar [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pipx)
```bash
pipx install --include-deps ansible
export PATH=$PATH:/home/$USER/.local/bin
pipx inject ansible requests docker
ansible-galaxy collection install community.docker --force
```

---

### Configurar Repositorio de Plantillas

1. Crear carpetas para organización:
    ```bash
    mkdir -p /home/mmatush/docker /home/mmatush/host
    ```

2. Generar una clave SSH para autenticación (reemplaza el correo según tu preferencia):
    ```bash
    ssh-keygen -t rsa -b 4096 -C "server@mmatush.cl"
    ```

3. Clonar el repositorio de plantillas de configuración:
    ```bash
    git clone git@github.com:manueljesusmatus/homelab-project.git /home/mmatush/host/homelab-project
    ```

4. Subir archivo all.yml en ~/host/homelab-project/ansible/group_vars
---

### Ejecutar Playbooks de Ansible

- Para ejecutar solo la tarea de instalación de Docker:
    ```bash
    ansible-playbook ~/host/homelab-project/ansible/lab_playbook.yml --verbose --tags "install_docker"
    ```

- Para ejecutar el playbook completo, omitiendo las tareas `docker_compose_down` e `install_docker`:
    ```bash
    ansible-playbook ~/host/homelab-project/ansible/lab_playbook.yml --verbose --skip-tags "docker_compose_down,install_docker"
    ```

---
