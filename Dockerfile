FROM ubuntu
MAINTAINER Lorenzo Salvadorini <lorello@openweb.it>

RUN apt-get install wget -y -q

# Add some repos
#RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN wget --no-check-certificate https://apt.puppetlabs.com/puppetlabs-release-precise.deb
RUN dpkg -i puppetlabs-release-precise.deb

# Update & upgrades
RUN apt-get update -y -q

# Install puppet & r10k without the agent init script
RUN apt-get install puppet-common=3.8.6-1puppetlabs1 git sudo -y -q
RUN gem install r10k
#RUN puppet module install zack/r10k
#RUN puppet apply -e "class { 'r10k': version => '1.3.2' }"

# Install the app
ARG CACHE_DATE=2016-02-17
RUN cd /opt && git clone https://github.com/damc-dev/ubuntu-boxen.git
RUN ln -s /opt/ubuntu-boxen/uboxen /usr/local/bin/uboxen
RUN puppet apply /opt/ubuntu-boxen/install.pp
RUN /opt/ubuntu-boxen/uboxen
