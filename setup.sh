#!/bin/bash

# Load config
. config.sh

# first, go to your glorious home
cd ~

# Make home structure
mkdir apps workspace

# Update
sudo apt update
sudo apt upgrade -y

# Install essential packages
sudo apt install htop nano zsh wget python3-dev python3-pip screen

# Set some kernel params
sed -i 's/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=1/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=1/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.accept_source_route = 0/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.accept_source_route = 0/net.ipv6.conf.all.accept_source_route = 0/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.send_redirects = 0/net.ipv4.conf.all.send_redirects = 0/' /etc/sysctl.conf
sed -i 's/#net.ipv4.tcp_syncookies=1/net.ipv4.tcp_syncookies=1/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.log_martians = 1/net.ipv4.conf.all.log_martians = 1/' /etc/sysctl.conf
sed -i 's/#net.ipv4.conf.all.accept_redirects = 0/net.ipv4.conf.all.accept_redirects = 0/' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.accept_redirects = 0/net.ipv6.conf.all.accept_redirects = 0/' /etc/sysctl.conf
sysctl -p

# Install Oh My Zsh and apply my own theme
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/lunanyan/dragon-zsh-theme
mv ./dragon-zsh-theme/dragon.zsh-theme ~/.oh-my-zsh/custom/themes/dragon.zsh-theme
rm -rfv ./dragon-zsh-theme

# (Optional) Install Jupyter
if [ "$jupyter" = true ] ; then
	pip3 install jupyterlab -y
	jupyter notebook --generate-config
	sed "s/#c.NotebookApp.ip = 'localhost'/c.NotebookApp.ip = '*'/" ~/.jupyter/jupyter_notebook_config.py
	sed "s/#c.NotebookApp.allow_origin = ''/c.NotebookApp.allow_origin = '*'/" ~/.jupyter/jupyter_notebook_config.py
	sed "s/#c.NotebookApp.port = 8888/c.NotebookApp.port = 30000/" ~/.jupyter/jupyter_notebook_config.py
	echo "from notebook.auth import passwd; passwd()" | python3
fi

# (Optional) Set iptables rules
if [ "$iptables" = true ] ; then
	iptables -A INPUT -i lo -j ACCEPT
	iptables -A OUTPUT -o lo -j ACCEPT
	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
	iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
	iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate ESTABLISHED -j ACCEPT
	iptables -A INPUT -j LOG
	iptables -A FORWARD -j LOG
	ip6tables -A INPUT -j LOG
	ip6tables -A FORWARD -j LOG
	netfilter-persistent save
fi
