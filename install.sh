#!/bin/bash

echo "This script requires root privileges, you will be asked your sudo password"


# Setup PuppetLabs repository
DISTRO=$(grep DISTRIB_CODENAME /etc/lsb-release | awk -F= '{print $2}')
wget -q https://apt.puppetlabs.com/puppetlabs-release-$DISTRO.deb
sudo dpkg -i puppetlabs-release-$DISTRO.deb
sudo apt-get update -y -q

# Install puppet without the agent init script
sudo apt-get install puppet-common=3.8.6-1puppetlabs1 git sudo -y -q

# Get & run librarian-puppet
sudo gem install r10k
# Download uboxen code
cd /opt
[ ! -d /opt/ubuntu-boxen ] && sudo git clone --recursive https://github.com/damc-dev/ubuntu-boxen.git
cd /opt/ubuntu-boxen
sudo r10k puppetfile install
sudo puppet apply install.pp

# Finish
echo -e "\n\nInstallation ended successfully (I hope).\n\nEnjoy Ubuntu Boxen running 'uboxen' at your shell prompt"
