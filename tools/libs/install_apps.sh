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

# Ustreamer repo
if [[ -z "${CROWSNEST_USTREAMER_REPO_SHIP}" ]]; then
    CROWSNEST_USTREAMER_REPO_SHIP="https://github.com/pikvm/ustreamer.git"
fi
if [[ -z "${CROWSNEST_USTREAMER_REPO_BRANCH}" ]]; then
    CROWSNEST_USTREAMER_REPO_BRANCH="master"
fi
USTREAMER_PATH="bin/ustreamer"

clone_ustreamer() {
    ## remove bin/ustreamer if exist
    if [[ -d bin/ustreamer ]]; then
        rm -rf bin/ustreamer
    fi
    sudo -u "${BASE_USER}" \
    git clone "${CROWSNEST_USTREAMER_REPO_SHIP}" \
    -b "${CROWSNEST_USTREAMER_REPO_BRANCH}" \
    --depth=1 --single-branch "${USTREAMER_PATH}"
}

get_avail_mem() {
    grep "MemTotal" /proc/meminfo | awk '{print $2}'
}

build_ustreamer() {
    ## Determine Ramsize and export MAKEFLAG
    if [[ "$(get_avail_mem)" -le 524288 ]]; then
        USE_PROCS=-j1
    elif [[ "$(get_avail_mem)" -le 1048576 ]]; then
        USE_PROCS=-j2
    else
        USE_PROCS=-j4
    fi

    if [[ ! -d "${USTREAMER_PATH}" ]]; then
        msg "'${USTREAMER_PATH}' does not exist! Build skipped ... [WARN]\n"
    else
        msg "Build '${USTREAMER_PATH##*/}' using ${USE_PROCS##-j} Cores ... \n"
        pushd "${USTREAMER_PATH}" &> /dev/null || exit 1
        make "${USE_PROCS}"
        popd &> /dev/null || exit 1
        msg "Build '${USTREAMER_PATH##*/}' ... [SUCCESS]\n"
    fi
}

install_apt_sources() {
    local id version_id

    id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2)
    version_id=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | cut -d'"' -f2)
    variant="generic"

    if [[ "$(is_raspios)" = "1" || "$(is_dietpi)" = "1" ]]; then
        variant="rpi"
        id="debian"
    fi

    if [[ "${id}" = "debian" ]] && [[ "${version_id}" = "11" ]]; then
        curl -s --compressed "https://apt.mainsail.xyz/mainsail.gpg.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/mainsail.gpg > /dev/null
        curl -s --compressed --fail -o /etc/apt/sources.list.d/mainsail.list "https://apt.mainsail.xyz/mainsail-${id}-${version_id}-${variant}.list"
        echo "1"
    else
        if curl -s --compressed --fail -o /etc/apt/sources.list.d/mainsail.sources "https://apt.mainsail.xyz/mainsail-${id}-${version_id}-${variant}.sources"; then
            curl -s --compressed "https://apt.mainsail.xyz/mainsail.gpg.key" | gpg --dearmor | sudo tee /usr/share/keyrings/mainsail.gpg > /dev/null
            echo "1"
        else
            echo "0"
        fi
    fi
}

install_apt_streamer() {
    local -a apps
    msg "Running apt-get update again ..."
    if run_apt_update; then
        status_msg "Running apt-get update again ..." "0"
    else
        status_msg "Running apt-get update again ..." "1"
    fi

    apps=("mainsail-ustreamer" "mainsail-spyglass")
    if [[ "$(is_raspios)" = "1" ]]; then
        apps+=("mainsail-camera-streamer-raspi")
    else
        apps+=("mainsail-camera-streamer-generic")
    fi

    for pkg in "${apps[@]}"; do
        if apt-get --yes --no-install-recommends install "${pkg}"; then
            echo "${pkg} installed successfully."
        else
            echo "${pkg} not found or failed to install."
        fi
    done
}

install_apps() {
    msg "Setup python venv ..."
    python3 -m venv --system-site-packages "${HOME}/crowsnest-env"

    msg "Setup Mainsail apt repository ..."
    if [[ "$(install_apt_sources)" = "0" ]]; then
        msg "We do not support your Distro with the Mainsail apt repository."
        msg "Trying to install ustreamer manually."
        msg "Cloning ustreamer repository ..."
        clone_ustreamer
        build_ustreamer
    else
        msg "Install streamer apps ..."
        install_apt_streamer
        msg "Note: camera-streamer and spyglass are supposed to fail on non Raspberry Pi OS systems"
    fi
}
