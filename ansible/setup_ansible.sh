# MIT License
# Copyright (c) 2025 Nikolay Dachev

#!/bin/bash

# DEFAULTS
ver="1.0.0"
py="python3"
pip="pip3"
vaultpwd='1q2w3e'
localansible=".local"
venv="$localansible/venv"
venv_file="$localansible/requirements.venv"
msg_prefix="SETUP ANSIBLE:"

# Check for python3 venv module and pip
"$py" -m venv -h &> /dev/null
if [ $? -ne 0 ]; then
    echo "$msg_prefix Error: The Python 3 venv module is missing. Please install it manually."
    exit 1
fi
"$pip" -h &> /dev/null
if [ $? -ne 0 ]; then
    echo "$msg_prefix Error: The Python 3 pip package is missing. Please install it manually."
    exit 1
fi

init_env() {
    echo "$msg_prefix --- INIT ---"
    for i in inventory/group_vars/all \
             inventory/host_vars \
             playbooks \
             collections/ansible_collections/ \
             files \
             .local/.ansible/tmp
    do
        if [ ! -d "$PWD/$i" ]; then
            echo "$msg_prefix create folder: $PWD/$i"
            mkdir -p "$PWD/$i"
        fi
    done
    
    if [ ! -f "$PWD/inventory/inventory.yml" ]; then
        echo "$msg_prefix create $PWD/inventory/inventory.yml"
        touch "$PWD/inventory/inventory.yml"
    fi

    if [ ! -f "$PWD/ansible.cfg" ]; then
       echo "$msg_prefix create $PWD/ansible.cfg"
       cat > "$PWD/ansible.cfg" << EOF
[defaults]
inventory  =            ./inventory
collections_paths =     ./collections
remote_tmp =            \$HOME/.ansible/tmp
local_tmp  =            $localansible/.ansible/tmp
vault_password_file =   $localansible/.vaultpwd
become =                True
host_key_checking =     False
deprecation_warnings =  True
ansible_network_os =    linux
stdout_callback =       yaml
display_skipped_hosts = true

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF
    fi
    
    if [ ! -f "$PWD/.gitignore" ]; then
       echo "$msg_prefix create $PWD/.gitignore"
       cat > "$PWD/.gitignore" << EOF
$localansible/*
!$venv_file*
EOF
    fi
    
    if [ ! -f "$localansible/.vaultpwd" ]; then
        echo "$msg_prefix create $PWD/$localansible/.vaultpwd"
        echo "$vaultpwd" > "$PWD/$localansible/.vaultpwd"
        chmod 400 "$PWD/$localansible/.vaultpwd"
        echo ""
        echo "$msg_prefix: Please check $localansible/.vaultpwd for the default vault password."
    fi
    
    echo ""
    echo "$msg_prefix: Ansible environment initialization complete!"
}

new_venv() {
    echo "$msg_prefix --- NEW VENV ---"
    if [ -d "$venv" ]; then
        echo "$msg_prefix ERROR: '$venv' exists. Please delete it first!"
        exit 1
    fi
    
    echo "$msg_prefix create $venv"
    "$py" -m venv "$venv" #--system-site-packages
    
    echo "$msg_prefix source $venv/bin/activate"
    source "$venv/bin/activate"
    
    echo "$msg_prefix update pip"
    "$pip" install --upgrade pip
    "$pip" install --upgrade wheel
    
    if [ -f "$venv_file" ]; then
        echo "$msg_prefix $pip install -r $venv_file"
        "$pip" install -r "$venv_file"
    else
        echo "$msg_prefix $venv_file not found!"
        echo "$msg_prefix install ansible"
        "$pip" install ansible
        ansible --version
        echo "$msg_prefix create $venv_file"
        pip freeze > "$venv_file"
    fi
    
    echo ""
    echo "$msg_prefix: Virtual environment '$venv' has been created."
    echo "$msg_prefix: To activate the virtual environment, run: source $venv/bin/activate"
    echo "$msg_prefix: To deactivate the virtual environment, run: deactivate"
}

update_venv_req() {
    echo "$msg_prefix --- UPDATE $venv_file ---"
    if [ ! -d "$venv" ]; then
        echo "$msg_prefix ERROR: '$venv' does not exist!"
        echo "$msg_prefix Please create a new '$venv' using: ./setup_ansible.sh new"
        exit 1
    fi

    if [ -f "$venv_file" ]; then
      echo "$msg_prefix create $venv_file.bck"
      cp "$venv_file" "$venv_file.bck"
    fi

    echo "$msg_prefix source $venv/bin/activate"
    source "$venv/bin/activate"
    
    echo "$msg_prefix update $venv_file"
    pip freeze > "$venv_file"
    
    echo ""
    echo "$msg_prefix $venv_file is updated"
    echo "$msg_prefix please push $venv_file in git"
}

case $1 in
    init_ansible)
        init_env
    ;;
    init_venv)
        new_venv
        echo ""
        update_venv_req
    ;;
    update_venv)
        update_venv_req
    ;;
    *)
        cat << EOF
$msg_prefix v$ver
Usage:
    init_ansible : Initialize Ansible files and folders.
    init_venv    : Initialize Python virtual environment.
    update_venv  : Update '$venv_file'.
EOF
    ;;
esac
