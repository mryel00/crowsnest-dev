#!/usr/bin/env bash

#### crowsnest - A webcam Service for multiple Cams and Stream Services.
####
#### Written by Patrick Gehrsitz aka mryel00 <mryel00.github@gmail.com>
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

CROWSNEST_USTREAMER_REPO_COMMIT="81756811f3c925174f05300a9301bb722b9cbfb5"
CROWSNEST_CAMERA_STREAMER_REPO_COMMIT_MASTER="fe701b83da35598af4fc1d77c717c8a67cac9edd"
CROWSNEST_CAMERA_STREAMER_REPO_COMMIT_MAIN="bc231917d811e4a6661fc0b01b3e3750c6babd59"