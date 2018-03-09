#!/usr/bin/env bash
# Global Variables
SYSTEMD_DIR="/usr/local/lib/systemd/system"
LAB_PATH="/root/labs/simple-lab-wizard"
ENVIRONMENT_VARS="${LAB_PATH}/setup/config.sh"
PRODUCT=$(dmidecode -s system-product-name)

# Create Required Directories
mkdir -p /root/{running,labs}

function env_vrs () {
    # Check if this is the template
    if [ "${PRODUCT}" == "VirtualBox" ]; then
       echo "Running in template, doing no further setup"
       exit 0
    fi
    # Export the configuration Variables
    . ${ENVIRONMENT_VARS}

}

#function checks () {
#    echo "Here we do all prelimiary checks for lab -- TODO: remove this line from final version"
#}

function labbootstrap_setup () {
    # Move Lab Bootstrap Service and Script into place
    cp ${LAB_PATH}/setup/labbootstrap.sh /root/running
    mkdir -p ${SYSTEMD_DIR}

    cat > ${SYSTEMD_DIR}/labbootstrap.service << EOF
[Unit]
Description=LabBootstrap service

[Service]
WorkingDirectory=/root/running/
ExecStart=/bin/bash /root/running/labbootstrap.sh
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    if [ -f "${SYSTEMD_DIR}/labbootstrap.service" ]; then
        systemctl daemon-reload
        systemctl enable labbootstrap.service && echo "labbootstrap.service enabled!"
        systemctl start labbootstrap.service && echo "labbootstrap.service started!"

    else
        echo "The service file is missing!"

    fi
}

function install_deps () {
    apt update
    apt install -y jq pwgen python3-pip

}

env_vrs
install_deps
#checks
labbootstrap_setup
