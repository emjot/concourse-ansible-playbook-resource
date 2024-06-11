#!/bin/sh

# This script can be called inside the built container to get the latest available ansible version via pip.
# (See Dockerfile print_latest_ansible_version target.)

set -eu
versions=$(pip index versions ansible 2>/dev/null)
echo "$versions" | egrep -o '([0-9]+\.){2}[0-9]+' | head -n 1
