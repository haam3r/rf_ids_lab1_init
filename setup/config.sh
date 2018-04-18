#!/usr/bin/env bash
datafile="/root/running/lab_data.ini"
touch ${datafile}
export CLIENTIP="192.168.0.100/24"
export SERVERIPS="192.168.0.200/24 192.168.0.201/24"
export ROUTERIP="192.168.0.254"

# Lab name cannot contain any spaces
export LAB_NAME="RFIDS-LAB1"

counter=10

apt-get install -y nginx

while [ ${counter} -gt 0  ]; do

curl -H "accept: application/json" -X POST "$(dmidecode -s system-product-name)/labinfo?uuid=$(dmidecode -s system-version)" > ${datafile}

        if [ $? -eq 0 ]; then
                break
        fi
        sleep 2
	$((counter--))
done


# export LAB_NAME=$(cat /tmp/lab_data | jq -r '.lab.name')
export LAB_USERNAME=$(cat ${datafile} | jq -r '.user.username')
export TA_KEY=$(cat ${datafile} | jq -r '.lab.lab_token')
export VIRTUALTA_HOSTNAME=$(cat ${datafile} | jq -r '.assistant.uri')
export USER_FULLNAME=$(cat ${datafile} | jq -r '.user.name')
export USER_KEY=$(cat ${datafile} | jq -r '.user.user_key')
export LAB_ID=$(cat ${datafile} | jq -r '.lab.lab_hash')

cat > /root/running/lab.ini << EOF
[LAB]
ta_key = $TA_KEY
virtualta_hostname = $VIRTUALTA_HOSTNAME
lab_id = $LAB_ID
uid = $USER_KEY
EOF

# Get labinit.sh from VTA repository
curl -H "accept: application/json" -X POST "${VIRTUALTA_HOSTNAME}/file/${LAB_ID}/${TA_KEY}/labinit.sh" > /root/running/labinit.sh


mkdir -p /var/www/clipboard
cat > /etc/nginx/sites-enabled/clipboard <<EOF
server {
        listen 192.168.0.254:80;
        root   /var/www/clipboard;
        index index.php index.html;
}
EOF

systemctl restart nginx

clipboard_link="${VIRTUALTA_HOSTNAME}/clipboard/${LAB_ID}/${USER_KEY}"
echo $clipboard_link >> /root/running/setup.log

cat > /var/www/clipboard/index.html <<EOF 
<html><head><meta http-equiv="refresh" content="1; url=$clipboard_link" /></head></html>
EOF
chown www-data.www-data /var/www/clipboard/index.html && chmod 0644 /var/www/clipboard/index.html
