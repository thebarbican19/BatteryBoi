#!/bin/sh -ex

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

TOOL_PATH="$1"
INSTALL_PATH="$2"
INSTALL_DIR=`dirname "$INSTALL_PATH"`

mkdir -p "$INSTALL_DIR"
ln -sf "$TOOL_PATH" "$INSTALL_PATH"

printf "Hell Yeah Boi\n"
