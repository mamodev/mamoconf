#!/bin/bash
set -e

# This script install all config folders and files to the home directory
globals=( "nvim" "alacritty" "scripts")
macos=( "aerospace" )
linux=( )

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS='macos'
    configs=( "${globals[@]} ${macos[@]}" )
else 
    echo "curremtly not supported OS"
    exit 1
fi

error="no"
for config in ${configs[@]}; do
    # check if folder exists in ~/.config/
    if [ -d "$HOME/.config/$config" ]; then
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
            if [ -d "$HOME/.config/$config" ]; then
                echo "Deleting $config from ~/.config/"
                rm -rf "$HOME/.config/$config"
            fi
        done
    fi
fi


for config in ${configs[@]}; do
    echo "Linking $config to ~/.config/$config"
    ln -s "$PWD/$config" "$HOME/.config/$config"  
done

SCRIPT_SOURCING="#<<< START MAMOCONF INSTALL >>>"
# ADD source ~/.config/scripts/*.sshel
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
    if [ -f custom_path ]; then 
        echo "Using custom path for shell configs: $custom_path"
        if grep -q "#<<< START MAMOCONF INSTALL >>>" "$custom_path"; then
            echo "Removing existing mamoconf block from custom path"
            sed -i '' '/#<<< START MAMOCONF INSTALL >>>/,/#<<< END MAMOCONF INSTALL >>>/d' "$cutom_path"
        fi
        
        echo -e "$SCRIPT_SOURCING" >> "$custom_path"
    fi

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
