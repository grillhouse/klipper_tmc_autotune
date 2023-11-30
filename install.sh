#!/bin/bash

KLIPPER_PATH="${HOME}/klipper"
AUTOTUNETMC_PATH="${HOME}/klipper_tmc_autotune"

set -eu
export LC_ALL=C

function preflight_checks {
    if [ "$EUID" -eq 0 ]; then
        echo "[PRE-CHECK] This script must not be run as root!"
        exit -1
    fi

    # Check for klipper.service or klipper-*.service
    klipper_services=$(sudo systemctl list-units --full -all -t service --no-legend | grep -E 'klipper.service|klipper-.*\.service' | awk '{print $1}')
    if [ -z "$klipper_services" ]; then
        echo "[ERROR] Klipper service not found, please install Klipper first!"
        exit -1
    fi
    echo "[PRE-CHECK] Klipper service(s) found! Continuing..."
}

function check_download {
    local autotunedirname autotunebasename
    autotunedirname="$(dirname ${AUTOTUNETMC_PATH})"
    autotunebasename="$(basename ${AUTOTUNETMC_PATH})"

    if [ ! -d "${AUTOTUNETMC_PATH}" ]; then
        echo "[DOWNLOAD] Downloading Autotune TMC repository..."
        if git -C $autotunedirname clone https://github.com/andrewmcgr/klipper_tmc_autotune.git $autotunebasename; then
            chmod +x ${AUTOTUNETMC_PATH}/install.sh
            echo "[DOWNLOAD] Download complete!"
        else
            echo "[ERROR] Download of Autotune TMC git repository failed!"
            exit -1
        fi
    else
        echo "[DOWNLOAD] Autotune TMC repository already found locally. Continuing..."
    fi
}

function link_extension {
    echo "[INSTALL] Linking extension to Klipper..."
    ln -srfn "${AUTOTUNETMC_PATH}/autotune_tmc.py" "${KLIPPER_PATH}/klippy/extras/autotune_tmc.py"
    ln -srfn "${AUTOTUNETMC_PATH}/motor_constants.py" "${KLIPPER_PATH}/klippy/extras/motor_constants.py"
    ln -srfn "${AUTOTUNETMC_PATH}/motor_database.cfg" "${KLIPPER_PATH}/klippy/extras/motor_database.cfg"
}

function restart_klipper {
    echo "[POST-INSTALL] Restarting Klipper services..."
    for service in $klipper_services; do
        sudo systemctl restart "$service"
        echo "Restarted $service"
    done
}

printf "\n======================================\n"
echo "- Autotune TMC install script -"
printf "======================================\n\n"

# Run steps
preflight_checks
check_download
link_extension
restart_klipper
