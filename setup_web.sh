#!/bin/bash

attacker="pwdsink.deeppacketcorp.lab"
attackerip=$(head -n 1 /root/labs/RF_IDS_Lab1_Scripts/scripts/red_ips.txt) 
host="portal.deeppacketcorp.lab"
hostip="10.10.10.2"

# Check for helloworld lab
helloworld () {
    cat /root/running/failover | grep helloworld > /dev/null
    ret=$?
    echo "${ret}"
    return ${ret};
}

main () {
while :
do
	ping -c 1 ${hostip} && break
	sleep 1
done

while :
do
	ssh root@${hostip} uname && break
	sleep 1
done

# Replace application URI in the portal config

sed -i "s|http://tiia.rangeforce.com:8888/cyberUK/portal/|http://${host}|g" /root/labs/ci-modular-target/application/config/config.php
sed -i "s|'index.php'|''|g" /root/labs/ci-modular-target/application/config/config.php

# Setup MySQL database
ssh root@${hostip} apt-get update && apt-get install -y nginx debconf-utils 
PASS=$(jq '.DBpass' /root/labs/simple-lab-wizard/nw.json | cut -d '"' -f 2)

ssh root@${hostip} debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASS"
ssh root@${hostip} debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASS"
ssh root@${hostip} apt-get install -y mysql-server

# Remove old instances

ssh root@${hostip} rm -r /var/www/${host}/*
ssh root@${hostip} mkdir -p /var/www/${host}

# Copy new instance

scp -rq /root/labs/ci-modular-target/* root@${hostip}:/var/www/${host}/
ssh root@${hostip} chown www-data:www-data /var/www/ -R

# Copy certificate and key

#scp -q /root/labs/ms-capstone-labpersonalize/${host}.crt root@${hostip}:/etc/ssl/certs/
#scp -q /root/labs/ms-capstone-labpersonalize/${host}.key root@${hostip}:/etc/ssl/private/

# Remove default

ssh root@${hostip} rm /etc/nginx/sites-enabled/default

# Add configuration to the host
ssh root@${hostip} "cat > /etc/nginx/sites-available/${host}" << EOF

server {
        listen 80;

        root   /var/www/${host};

        index index.php index.html;

        location / {
		try_files \$uri \$uri/ /index.php;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }
}
EOF

# Enable site
ssh root@${hostip} ln -s /etc/nginx/sites-available/${host} /etc/nginx/sites-enabled/

# Restart nginx
ssh root@${hostip} systemctl restart nginx.service

# Execute setup.php
curl -s http://${hostip}/setup.php?filename=northwind.json

# Remove setup.php and data folder
ssh root@${hostip} rm -r /var/www/${host}/setup.php /var/www/${host}/data/


echo "Lab personalize setup has finished";
}

pwdsink () {
# Set Up Password Sink
while :
do
	ssh -o StrictHostKeyChecking=no root@${attackerip} uname && break
	sleep 1
done

# Remove old instances
ssh root@${attackerip} rm -r /var/www/${attacker}/*
ssh root@${attackerip} mkdir -p /var/www/${attacker}

# Copy new instance

scp -rq /root/labs/pwdsink/* root@${attackerip}:/var/www/${attacker}/
ssh root@${attackerip} chown www-data:www-data /var/www/ -R

# TODO cleanup if no certs required
# Copy certificate and key
#scp -q /root/labs/ms-capstone-labpersonalize/${host}.com.crt root@${attackerip}:/etc/ssl/certs/${attacker}.com.crt
#scp -q /root/labs/ms-capstone-labpersonalize/${host}.com.key root@${attackerip}:/etc/ssl/private/${attacker}.com.key

# Remove default

ssh root@${attackerip} rm /etc/nginx/sites-enabled/default

# Add configuration to the host
ssh root@${attackerip} "cat > /etc/nginx/sites-available/${attacker}" << EOF

server {
        listen 80;

        root   /var/www/${attacker};

        index index.php index.html;

        location / {
		try_files \$uri \$uri/ /index.php;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }
}

#server {
#        listen 443;
#
#        ssl on;
#        ssl_certificate /etc/ssl/certs/${attacker}.crt;
#        ssl_certificate_key /etc/ssl/private/${attacker}.key;
#	ssl_protocols   TLSv1 TLSv1.1 TLSv1.2;
#	ssl_ciphers     HIGH:!aNULL:!MD5;
#
#	access_log /var/log/nginx/nginx.server.access.log;
#	error_log /var/log/nginx/nginx.server.error.log;
#	root   /var/www/${attacker};
#	index  index.html index.php;
#
#	location / {
#        	try_files \$uri \$uri/ /index.php;
#	}
#
#	location ~ \.php$ {
#        	include snippets/fastcgi-php.conf;
#        	fastcgi_pass unix:/run/php/php7.0-fpm.sock;
#	}
#
#	location ~ /\.ht {
#	deny all;
#    	}
#}
EOF

# Enable site
ssh root@${attackerip} ln -s /etc/nginx/sites-available/${attacker} /etc/nginx/sites-enabled/

# Restart nginx
ssh root@${attackerip} systemctl restart nginx.service

# Remove git folder
ssh root@${attackerip} rm -r /var/www/${attacker}/.git

# Now shuffle our tracks in the history file

ssh root@${attackerip} 'cat /dev/null > ~/.bash_history && history -c && exit'
ssh root@${attackerip} 'cat /dev/null > ~student/.bash_history && history -c && exit'
ssh root@${attackerip} "usermod -L student"

# Move JS deface in place
scp /root/labs/ci-modular-target-checks/attacks/deface.js root@${attackerip}:/var/www/${attacker}/ #
ssh root@${attackerip} chown www-data.www-data /var/www/

echo "Password sink is set up";
}

helloworld
if [ "${ret}" -eq 0 ]; then
    echo "Running the MVP Hello World instance, no need to continue and hold up time!"
else
    echo "Game on!"
    sleep 5
    main
    pwdsink
fi

# RED | WHITE networking
########################

#declare -A interfaces
#interfaces=( ["rf_red"]="enp0s9" ["rf_white"]="enp0s8" ["ex_red"]="enp0s10f2" ["ex_white"]="enp0s10f1" )
#
#check=`hostnamectl | grep Virtualization | cut -d: -f2`
#if [ "${check}" == "microsoft" ]; then
#	int_red=${interfaces["ex_red"]}
#	int_white=${interfaces["ex_white"]}
#else
#	int_red=${interfaces["rf_red"]}
#    int_white=${interfaces["rf_white"]}
#fi
#
## Kali interface: enp0s9 (RF); enp0s10f2
## router interfaece for white IPs: enp0s8 (RF); enp0s10f1
#
## Set up Red IP addresses 
#RED_IPS=$(cat /root/labs/ms-capstone-labpersonalize/ips_red.txt)
#for i in ${RED_IPS}; do
#	/sbin/ip address add ${i}/30 dev ${int_red}
#done
#
## Set up White IP addresses
#WHITE_IPS=$(cat /root/labs/ms-capstone-labpersonalize/ips_white.txt)
#for j in ${WHITE_IPS}; do
#    /sbin/ip address add ${j}/32 dev ${int_white}
#done

##########################
##### Networking done #####


# Set up website for communication
##################################
#mkdir /var/www/comms
#
#cat > /var/www/comms/index.html << EOF
#-----------------------$(date '+%Y-%m-%d')-----------------------
#[$(date '+%Y-%m-%d %H:%M:%S')] <span style="color: red"><b>&lt;HackerMan3000&gt;</b></span> - Hey guys, have you heard of Northwind Traders? I found a few holes in their system. Me and hackergirl are gonna try to see if we can use any of them...
#[$(date '+%Y-%m-%d %H:%M:%S')] <span style="color: darkred"><b>&lt;Hacker6url3000&gt;</b></span> - I'm ready to go!
#EOF
#
#cp -r /root/labs/ms-capstone-labpersonalize/chatbot/* /var/www/comms/
#
#cat > /etc/nginx/sites-enabled/comms.conf << EOF
#server {
#    listen 23.105.70.77:8080;
#	listen 95.215.62.189:8080;
#	listen 111.253.79.93:8080;
#	listen 118.89.40.157:8080;
#
#    root   /var/www/comms;
#    index index.php index.html;
#    location / {
#        try_files \$uri \$uri/ /index.php;
#    }
#    location ~ \.php$ {
#        include snippets/fastcgi-php.conf;
#        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
#    }
#}
#EOF
#
ssh root@${hostip} systemctl restart nginx.service
