#!/bin/bash

# This script generates an Ansible inventory file for WSL2

# Get the IP address of the Windows host
WIN_HOST_IP=$(ip route | grep default | awk '{print $3}')

# Get ansible user and password
read -p "Enter ansible_user: " ANSIBLE_USER
read -sp "Enter ansible_password: " ANSIBLE_PASSWORD

# Create the inventory file
cat > inventory <<EOF
[windows]
$WIN_HOST_IP

[windows:vars]
ansible_user=$ANSIBLE_USER
ansible_password=$ANSIBLE_PASSWORD
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
EOF
