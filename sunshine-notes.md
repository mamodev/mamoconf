
# Installation on Arch

yay -S sunshine-bin

echo 'KERNEL=="uinput", MODE="0660", GROUP="input"' | sudo tee /etc/udev/rules.d/85-sunshine-input.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG input mamo


systemctl --user enable --now sunshine
