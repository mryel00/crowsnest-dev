#!/usr/bin/env bash

# This script migrates crowsnest.conf to a newer format.
# It creates a backup, removes deprecated options, cleans up sections,
# and ensures modes are valid.

set -e

# --- Configuration ---
CONFIG_FILENAME="crowsnest.conf"

# --- Functions ---

log_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

log_warn() {
    echo -e "\e[33m[WARN]\e[0m $1"
}

log_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

find_config() {
    local config_path=""

    if systemctl cat crowsnest.service >/dev/null 2>&1; then
        local service_content
        service_content=$(systemctl cat crowsnest.service)

        local env_file_path
        env_file_path=$(echo "$service_content" | grep "^EnvironmentFile=" | cut -d= -f2)

        if [[ -n "${env_file_path}" && -f "${env_file_path}" ]]; then
            local args_line
            args_line=$(grep "^CROWSNEST_ARGS=" "${env_file_path}")

            if [[ -n "${args_line}" ]]; then
                local extracted_path
                if [[ $args_line =~ -c[[:space:]]+([^[:space:]\"]+) ]]; then
                     extracted_path="${BASH_REMATCH[1]}"
                fi

                if [[ -n "${extracted_path}" && -f "${extracted_path}" ]]; then
                    echo "${extracted_path}"
                    return 0
                fi
            fi
        fi
    fi

    local base_user
    if [[ -n "${SUDO_USER}" ]]; then
        base_user="${SUDO_USER}"
    else
        base_user="$(whoami)"
    fi
    local user_home
    user_home=$(eval echo "~${base_user}")

    local found_config
    found_config=$(find "${user_home}" -maxdepth 4 -type d -name "crowsnest" -prune -o -type f -name "${CONFIG_FILENAME}" -print | head -n 1)

    if [[ -n "${found_config}" ]]; then
        echo "${found_config}"
        return 0
    fi

    log_error "Could not find ${CONFIG_FILENAME} in ${user_home} or an installed crowsnest.service."
    log_error "Skipping crowsnest.conf backup."
    return 1
}

backup_config() {
    local extension
    local cfg="$1"
    extension="$(date +%Y-%m-%d-%H%M)"
    cp "${cfg}" "${cfg}.${extension}"
}

migrate_crudini() {
    local cfg="$1"
    local sections
    local val

    log_info "Using crudini for migration..."

    sections=$(crudini --get --list "${cfg}")

    for section in $sections; do
        if [[ "$section" != "crowsnest" ]] && [[ ! "$section" =~ ^cam\ .* ]]; then
            log_info "Removing unknown section: [${section}]"
            crudini --del "${cfg}" "${section}"
            continue
        fi

        if [[ "$section" == "crowsnest" ]]; then
            if crudini --get "${cfg}" "${section}" "log_path" >/dev/null 2>&1; then
                log_info "Removing log_path from [crowsnest]"
                crudini --del "${cfg}" "${section}" "log_path"
            fi
        fi

        if [[ "$section" =~ ^cam\ .* ]]; then
            if crudini --get "${cfg}" "${section}" "enable_rtsp" >/dev/null 2>&1; then
                log_info "Removing enable_rtsp from [${section}]"
                crudini --del "${cfg}" "${section}" "enable_rtsp"
            fi

            if crudini --get "${cfg}" "${section}" "rtsp_port" >/dev/null 2>&1; then
                log_info "Removing rtsp_port from [${section}]"
                crudini --del "${cfg}" "${section}" "rtsp_port"
            fi

            if val=$(crudini --get "${cfg}" "${section}" "mode" 2>/dev/null); then
                if [[ "$val" != "ustreamer" ]] && [[ "$val" != "camera-streamer" ]] && [[ "$val" != "spyglass" ]]; then
                    log_info "Updating invalid mode '$val' to 'ustreamer' in [${section}]"
                    crudini --set "${cfg}" "${section}" "mode" "ustreamer"
                fi
            fi
        fi
    done
}


if [[ "$1" == "--restore" ]]; then
    local base_user
    if [[ -n "${SUDO_USER}" ]]; then
        base_user="${SUDO_USER}"
    else
        base_user="$(whoami)"
    fi
    local user_home
    user_home=$(eval echo "~${base_user}")

    MIGRATED_BACKUP=$(find "${user_home}" -maxdepth 4 -type d -name "crowsnest" -prune -o -type f -name "${CONFIG_FILENAME}.v5" -print | head -n 1)

    if [[ -n "${MIGRATED_BACKUP}" ]]; then
        # Target is the original filename without .v5
        TARGET_CONFIG="${MIGRATED_BACKUP%.v5}"

        log_info "Restoring migrated config from ${MIGRATED_BACKUP} to ${TARGET_CONFIG}"
        cp "${MIGRATED_BACKUP}" "${TARGET_CONFIG}"
        rm "${MIGRATED_BACKUP}"
        log_info "Restore complete."
        exit 0
    else
        log_warn "No migrated config found to restore."
        exit 0
    fi
fi

CONFIG_PATH=$(find_config) || exit 1
MIGRATED_TEMP="${CONFIG_PATH}.v5"

if ! command -v crudini >/dev/null 2>&1; then
    log_error "crudini is required but not found. If it isn't installed, you most likely don't need to run this script."
    exit 1
fi

log_info "Found config at: ${CONFIG_PATH}"

backup_config "${CONFIG_PATH}"

migrate_crudini "${CONFIG_PATH}"

cp "${CONFIG_PATH}" "${MIGRATED_TEMP}"

log_info "Migration complete."
