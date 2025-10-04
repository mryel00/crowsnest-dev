#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021 - 2023
#### Co-authored by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2023 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit on errors
set -Ee

# Debug
# set -x

. "${SRC_DIR}/libs/helper_fn.sh"

install_apt_sources() {
    local id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2)
    local version_id=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2)
    local rpi=""

    if [[ "$(is_raspios)" = "1" || "$(is_dietpi)" = "1" ]]; then
        rpi="-rpi"
    fi

    if [[ "$(id)" = "debian" ]] && [[ "$(version_id)" = "11" ]]; then
        curl -s --compressed "https://apt.mainsail.xyz/mainsail.gpg.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/mainsail.gpg > /dev/null
        curl -s --compressed --fail -o /etc/apt/sources.list.d/mainsail.list "https://apt.mainsail.xyz/mainsail-$id-$version_id$rpi.list"
        echo "1"
    else
        curl -s --compressed --fail -o /etc/apt/sources.list.d/mainsail.sources "https://apt.mainsail.xyz/mainsail-$id-$version_id$rpi.sources"
        if [[ $? -eq 0 ]]; then
            curl -s --compressed "https://apt.mainsail.xyz/mainsail.gpg.key" | gpg --dearmor | sudo tee /usr/share/keyrings/mainsail.gpg > /dev/null
            echo "1"
        else
            echo "0"
        fi
    fi
}

install_apt_streamer() {
    local -a apps
    msg "Installing Mainsail apt repository ..."
    if install_apt_sources; then
        status_msg "Installing Mainsail apt repository ..." "0"
    else
        status_msg "Installing Mainsail apt repository ..." "1"
    fi

    msg "Running apt-get update again ..."
    if run_apt_update; then
        status_msg "Running apt-get update again ..." "0"
    else
        status_msg "Running apt-get update again ..." "1"
    fi

    apps=("mainsail-ustreamer" "mainsail-spyglass" "mainsail-camera-streamer")
    for pkg in "${apps[@]}"; do
        if apt-get --yes --no-install-recommends install "$pkg"; then
            echo "$pkg installed successfully."
        else
            echo "$pkg not found or failed to install."
        fi
    done
}

install_apps() {
    msg "Setup python venv ..."
    python3 -m venv --system-site-packages "${SRC_DIR}/../.venv"

    msg "Setup Mainsail apt repository ..."
    if [[ "$(install_apt_sources)" = "0" ]]; then
        msg "We do not support your Distro with the Mainsail apt repository."
        msg "Trying to install ustreamer manually."
    else
        msg "Install streamer apps ..."
        install_apt_streamer
        msg "Note: camera-streamer and spyglass are supposed to fail on non Raspberry Pi OS systems"
    fi
}
