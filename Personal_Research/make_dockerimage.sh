#!/usr/bin/env bash

set -euo pipefail

cd ~/ardupilot

docker build --no-cache -t ardupilot-customrov .
