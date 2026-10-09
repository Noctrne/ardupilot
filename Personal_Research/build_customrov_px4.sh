#!/usr/bin/env bash

set -euo pipefail

cd ~/ardupilot

echo "=== Building ArduSub for Pixhawk 4 ==="

docker run --rm -it \
    -v "$PWD:/ardupilot" \
    -w /ardupilot \
    -u "$(id -u):$(id -g)" \
    ardupilot-customrov \
    bash -lc '
        ./waf configure --board Pixhawk4 &&
        ./waf sub
    '

echo
echo "=== Build finished ==="

cd ~/ardupilot/build/Pixhawk4/bin/

echo "=== Firmware files ==="
ls -lh ardusub*
