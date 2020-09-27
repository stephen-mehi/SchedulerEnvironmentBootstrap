brew cask install virtualbox
brew cask install vagrant
tee -a ~/.bash_profile <<EOF

# VAGRANT FEATURE GATE
export VAGRANT_EXPERIMENTAL=disks
EOF
export VAGRANT_EXPERIMENTAL=disks
vagrant plugin install vagrant-disksize
vagrant --version

