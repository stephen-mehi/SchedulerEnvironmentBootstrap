#sed -i 's/#   StrictHostKeyChecking ask/    StrictHostKeyChecking no/g' /etc/ssh/ssh_config

ssh-keygen -b 2048 -t rsa -f "/home/vagrant/.ssh/id_rsa" -q -N "" <<< ""$'\n'"y" 2>&1
sshpass -p vagrant ssh-copy-id -i /home/vagrant/.ssh/id_rsa vagrant@192.168.0.11

#ssh-copy-id -f -i /home/vagrant/.ssh/id_rsa vagrant@192.168.0.11 <<< ""$'\n'"vagrant" 2>&1
#sshpass -p vagrant ssh vagrant@192.168.0.11 'cat .ssh/id_rsa.pub' >> /home/vagrant/host-ids.pub

