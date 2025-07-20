

# Make sure your terminal windows is large enough
# Generate a key with gpg (gnupg)
gpg --gen-key
# Follow the prompts ...

# Create a storage key in pass from the previously generated public (pub) key
pass init <pubkey>



sudo apt install xdg-utils

# https://wslutiliti.es/wslu/install.html
sudo add-apt-repository ppa:wslutilities/wslu
sudo apt update
sudo apt install wslu


https://github.com/microsoft/WSL/issues/10205

https://github.com/microsoft/WSL/issues/11261



sudo systemctl restart user@1000
sudo systemctl restart user@1000

loginctl enable-linger 1000


# https://forum.snapcraft.io/t/wsl-wslg-and-systemd-hacks/24022/4
# /etc/systemd/system/user-runtime-dir@.service.d/override.conf
[Service]
ExecStart = sh -c "ln -fs /mnt/wslg/runtime-dir/* /run/user/"%i
