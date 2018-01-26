#!/usr/bin/env bash
# Global Variables
SYSTEMD_DIR="/usr/local/lib/systemd/system"

function checks () {
    # Check Which environment are we running in
    # TODO script to get vars from BIOS

    echo "Here we do all prelimiary checks for lab -- TODO: remove this line from final version"
}

function labbootstrap_setup () {
    # Create Required Directories
    mkdir -p /root/{running,labs}

    # Export the configuration Variables
    . /root/labs/simple-lab-wizard/setup/config.sh

    # Move Lab Bootstrap Service and Script into place
    cp /root/labs/simple-lab-wizard/setup/labbootstrap.sh /root/running

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


checks
labbootstrap_setup
