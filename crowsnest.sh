#!/bin/bash

#### Webcamd Core Application.

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Stephan Wendel aka KwadFan <me@stephanwe.de>
#### Copyright 2021
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit upon Errors
set -Ee

# Base Path
BASE_CN_PATH="$(dirname "$(readlink -f "${0}")")"

function missing_args_msg {
    echo -e "crowsnest: Missing Arguments!"
    echo -e "\n\tTry: crowsnest -h\n"
}

function wrong_args_msg {
    echo -e "crowsnest: Wrong Arguments!"
    echo -e "\n\tTry: crowsnest -h\n"
}

function help_msg {
    echo -e "crowsnest - webcam deamon\nUsage:"
    echo -e "\t crowsnest [Options]"
    echo -e "\n\t\t-h Prints this help."
    echo -e "\n\t\t-v Prints Version of crowsnest."
    echo -e "\n\t\t-c </path/to/configfile>\n\t\t\tPath to your crowsnest.conf"
    echo -e "\n\t\t-e </path/to/python_env>\n\t\t\tPath to your Python environment"
    echo -e "\n\t\t-s <sleep_seconds>\n\t\t\tDelay start \(in seconds\) after boot\n"
}

function check_cfg {
    if [ ! -r "${1}" ]; then
        echo "ERROR: No Configuration File found. Exiting!" >"$2"
        exit 1
    else
        return 0
    fi
}

#### MAIN
## Args given?
if [ "$#" -eq 0 ]; then
    missing_args_msg
    exit 1
fi

## Parse Args
while getopts ":vhc:e:s:d" arg; do
    case "${arg}" in
        v )
            echo -e "\ncrowsnest Version: $(self_version)\n"
            exit 0
        ;;
        h )
            help_msg
            exit 0
        ;;
        c )
            check_cfg "${OPTARG}"
            CROWSNEST_CFG="${OPTARG}"
        ;;
        e )
            CROWSNEST_ENV_PATH="${OPTARG}"
        ;;
        s )
            if [[ "$(awk '{print $1}' /proc/uptime | cut -d '.' -f 1)" -lt "120" ]]; then
                if [[ "${OPTARG}" ]]; then
                    sleep "${OPTARG}"
                else
                    sleep 5
                fi
            fi
        ;;
        d )
            set -x
        ;;
        \?)
            wrong_args_msg
            exit 1
        ;;
    esac
done

function set_log_path {
    #Workaround sed ~ to BASH VAR $HOME
    CROWSNEST_LOG_PATH=$(get_param "crowsnest" log_path | sed "s#^~#${HOME}#gi")
    declare -g CROWSNEST_LOG_PATH
    #Workaround: Make Dir if not exist
    if [ ! -d "$(dirname "${CROWSNEST_LOG_PATH}")" ]; then
        mkdir -p "$(dirname "${CROWSNEST_LOG_PATH}")"
    fi
}

function get_param {
    local cfg section param
    cfg="${CROWSNEST_CFG}"
    section="${1}"
    param="${2}"
    crudini --get "${cfg}" "${section}" "${param}" 2> /dev/null | \
    sed 's/\#.*//;s/[[:space:]]*$//'
    return
}

set_log_path
"${CROWSNEST_ENV_PATH}/bin/python3" "${BASE_CN_PATH}/crowsnest.py" -c "${CROWSNEST_CFG}" -l "${CROWSNEST_LOG_PATH}"
