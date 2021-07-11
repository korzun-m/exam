build:
 hosts:
   ${build_ip}
 vars:
   ansible_ssh_user: ubuntu
   ansible_ssh_private_key_file: ${ssh_keyfile}

prod:
 hosts:
   ${prod_ip}
 vars:
   ansible_ssh_user: ubuntu
   ansible_ssh_private_key_file: ${ssh_keyfile}