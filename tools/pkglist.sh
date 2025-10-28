#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
#### Copyright 2025 - till today
#### https://github.com/mainsail-crew/crowsnest
####
#### This File is distributed under GPLv3
####

# shellcheck enable=require-variable-braces

# Exit on errors
set -Ee

# Debug
# set -x

### Crowsnest Dependencies
# shellcheck disable=SC2034
PKGLIST="curl crudini python3 python3-venv"
# shellcheck disable=SC2034
PKGLIST_PI="python3-libcamera"
