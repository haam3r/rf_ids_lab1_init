#!/usr/bin/env bash
# Global Variables
SYSTEMD_DIR="/usr/local/lib/systemd/system"
LAB_PATH="/root/labs/simple-lab-wizard"
ENVIRONMENT_VARS="${LAB_PATH}/setup/config.sh"

function env_vrs () {
    # Export the configuration Variables
    . ${ENVIRONMENT_VARS}

}

function checks () {
    # Check Which environment are we running in
    # TODO script to get vars from BIOS

    echo "Here we do all prelimiary checks for lab -- TODO: remove this line from final version"
}

function labbootstrap_setup () {
    # Create Required Directories
    mkdir -p /root/{running,labs}

    # Move Lab Bootstrap Service and Script into place
    cp ${LAB_PATH}/setup/labbootstrap.sh /root/running

    cat > ${SYSTEMD_DIR}/labbootstrap.service << EOF
[Unit]
Description=LabBootstrap service
After=routerapi.service

[Service]
Type=Simple
WorkingDirectory=/root/labs/
ExecStart=/root/running/labbootstrap.sh
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    if [ -f "${SYSTEMD_DIR}/labbootstrap.service" ]; then
        systemctl enable labbootstrap.service && echo "labbootstrap.service enabled!"
        systemctl start labbootstrap.service && echo "labbootstrap.service started!"

    else
        echo "The service file is missing!"

    fi
}

env_vrs
checks
labbootstrap_setup
