#!/usr/bin/env bash

# Quick-Shot Installation Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Quick-Shot installation...${NC}"

# Check for dependencies
DEPENDENCIES=("jq" "grim" "slurp" "wl-copy" "notify-send")
MISSING_DEPS=()

for dep in "${DEPENDENCIES[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${RED}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo "Please install them using your package manager."
    echo "Arch Linux: sudo pacman -S jq grim slurp wl-clipboard libnotify"
    echo "Fedora: sudo dnf install jq grim slurp wl-clipboard libnotify"
    echo "Ubuntu/Debian: sudo apt install jq grim slurp wl-clipboard libnotify"
    exit 1
fi

echo -e "${GREEN}All dependencies met.${NC}"

# Install scripts
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "Installing scripts to $INSTALL_DIR..."
cp bin/takeshot "$INSTALL_DIR/"
cp bin/hyprshot "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/takeshot"
chmod +x "$INSTALL_DIR/hyprshot"

# Ensure PATH is configured
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${RED}Warning: $INSTALL_DIR is not in your PATH.${NC}"
    echo "Please add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your ~/.bashrc or ~/.zshrc."
fi

echo -e "${GREEN}Quick-Shot successfully installed!${NC}"
echo "You can now bind 'takeshot output', 'takeshot window', and 'takeshot region' in your Hyprland config."
echo -e "${BLUE}Remember to use 'bindr' (or '{ release = true }' in Lua) for 'takeshot window' and 'takeshot region' to avoid slurp conflicts!${NC}"
