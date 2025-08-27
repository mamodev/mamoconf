
set -e

if [[ "$OSTYPE" != "linux"* ]]; then
	echo "installation of nvim only supported for linux!"
fi

mkdir -p .install 

[ -e nvim-linux-x86_64.tar.gz ] && rm nvim-linux-x86_64.tar.gz
[ -e nvim-linux-x86_64 ] &&  rm -rf nvim-linux-x86_64

if [ -d ".install/nvim-linux-x86_64" ]; then 
	echo "Nvim already installed in folder .install"
	read -p "Do you want to clean install it? (y/N): " answer
	if [[ "$answer" == "Y" ||  "$answer" == "y" ]]; then
		rm -rf ".install/nvim-linux-x86_64"
	fi
fi


if [ ! -d ".install/nvim-linux-x86_64" ]; then 
	wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
	tar -xf nvim-linux-x86_64.tar.gz
	rm nvim-linux-x86_64.tar.gz
	mv nvim-linux-x86_64 .install/
fi


echo "export PATH=\"\$MAMOCFG/.install/nvim-linux-x86_64/bin:\$PATH\"" > scripts/nvim.install.ssource

echo "Rinstall config with install.sh to make changes take effect"
