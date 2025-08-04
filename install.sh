#!/bin/bash
set -e

# Check if custom config path is passed as arg
CFG_PTH="$1"
if [ -z "$CFG_PTH" ]; then
    CFG_PTH="${XDG_CONFIG_HOME:-$HOME/.config}"
    echo "No custom config path provided. Using default: $CFG_PTH"
else
    echo "Using custom config path: $CFG_PTH"
    if [ ! -d "$CFG_PTH" ]; then
        echo "Custom config path does not exist. Creating it: $CFG_PTH"
        exit 0
    fi
fi

# This script install all config folders and files to the home directory
globals=( "nvim" "alacritty" "scripts")
macos=( "aerospace" )
linux=( )

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS='macos'
    configs=( "${globals[@]} ${macos[@]}" )
else 
    OS='unkown'
    configs=( "${globals[@]}" )
fi

error="no"
for config in ${configs[@]}; do
    # check if folder exists in ~/.config/
    if [ -d "$CFG_PTH/$config" ]; then
        echo "Config already exists for ${config}"
        error="yes"
    fi 
done

if [ "$error" == "yes" ]; then
    # ask user if he want to delete conflicting folders with rm -rf
    # Y/n
    read -p "Do you want to delete the conflicting folders? (Y/n): " answer
    if [[ "$answer" == "Y" || "$answer" == "y" || "$answer" == "" ]]; then
        for config in ${configs[@]}; do
            if [ -d "$CFG_PTH/$config" ]; then
                echo "Deleting $config from $CFG_PTH/"
                rm -rf "$CFG_PTH/$config"
            fi
        done
    fi
fi


for config in ${configs[@]}; do
    echo "Linking $config to $CFG_PTH/$config"
    ln -s "$PWD/$config" "$CFG_PTH/$config"

done

SCRIPT_SOURCING="#<<< START MAMOCONF INSTALL >>>"
# ADD source ~/.config/scripts/*.ssource
for script in "$HOME/.config/scripts"/*.ssource; do
    if [[ -f "$script" ]]; then
        SCRIPT_SOURCING+="\nsource $script"
    fi
done
SCRIPT_SOURCING+="\n#<<< END MAMOCONF INSTALL >>>"

#ask if user want to install shell configs to zsh
read -p "Install shell configs to system shells? (Y/n): " answer
if [[ "$answer" != "Y" && "$answer" != "y" && "$answer" != "" ]]; then
    read -p "Do you want a custom path for the shell configs? (Default: no) path: " custom_path
    echo "Using custom path for shell configs: $custom_path"

    if [ -f "$custom_path" ]; then 
        if grep -q "#<<< START MAMOCONF INSTALL >>>" "$custom_path"; then
            echo "Removing existing mamoconf block from custom path"
            sed -i '' '/#<<< START MAMOCONF INSTALL >>>/,/#<<< END MAMOCONF INSTALL >>>/d' "$cutom_path"
        fi
        
        echo -e "$SCRIPT_SOURCING" >> "$custom_path"
    else 
        echo "File not found: ${custom_path}"
    fi

    exit 0
fi

# Check if bashrc present
if [ -f "$HOME/.bashrc" ]; then
    # IF file contains a block with <<< ... >>> Delemiters remove the block from the file and reappend it
    if grep -q "#<<< START MAMOCONF INSTALL >>>" "$HOME/.bashrc"; then
        echo "Removing existing mamoconf block from .bashrc"
        sed -i '' '/#<<< START MAMOCONF INSTALL >>>/,/#<<< END MAMOCONF INSTALL >>>/d' "$HOME/.zshrc"
    fi

    echo -e "$SCRIPT_SOURCING" >> "$HOME/.bashrc"
fi

# Check for zshrc
if [ -f "$HOME/.zshrc" ]; then
    # IF file contains a block with <<< ... >>> Delemiters remove the block from the file and reappend it
    if grep -q "#<<< START MAMOCONF INSTALL >>>" "$HOME/.zshrc"; then
        echo "Removing existing mamoconf block from .zshrc"
        sed -i '' '/#<<< START MAMOCONF INSTALL >>>/,/#<<< END MAMOCONF INSTALL >>>/d' "$HOME/.zshrc"
    fi

    echo -e "$SCRIPT_SOURCING" >> "$HOME/.zshrc"
fi
