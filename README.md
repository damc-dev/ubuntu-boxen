=======
ubuntu-boxen
============

My notebook setup using Puppet and basic idea from GitHub Boxen

Look at [the original Boxen](http://boxen.github.com/) to understand what it is and how to use it.

Setup
-----
    wget -O- -q https://raw.githubusercontent.com/damc-dev/ubuntu-boxen/master/install.sh | /bin/bash

Manage your own hosts
---------------------

    remove my hosts submodule and add your own, hiera will lookup in the path ``data/hosts`


