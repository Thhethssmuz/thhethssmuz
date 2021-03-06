#!/bin/bash
# shellcheck disable=SC2086
set -exuo pipefail

# don't automatically re-execute if something goes wrong
rm -rf /root/.profile

# disable autologin
systemctl disable getty\@tty1.service.d
rm -rf /etc/systemd/system/getty\@tty1.service.d

dhcpcd && sleep 10

# localectl
pacman -S --noconfirm libxkbcommon-x11
localectl set-locale LANG=en_GB.UTF-8
localectl set-x11-keymap dvorak pc104 "no(dvorak)"
localectl set-keymap --no-convert dvorak

# include multilib
sed -i 's/^#\[multilib\]/[multilib]\nInclude = \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf
pacman -Syy
pacman -Syu

# install sudo and add wheel group to sudoers
pacman -S --noconfirm  sudo
sed -i '/^# %wheel ALL=(ALL) ALL$/ s/^# //' /etc/sudoers
visudo -cf /etc/sudoers

# set password for root and new user
yes "$PASSWORD" | passwd || :
useradd -m -g users -G audio,games,rfkill,uucp,video,wheel -s /bin/bash $USERNAME
yes "$PASSWORD" | passwd $USERNAME || :

# install git
pacman -S --noconfirm git

# clone dotfiles
su $USERNAME -l << EOF

  cd ~
  git init
  git remote add origin https://github.com/Thhethssmuz/dotfiles.git
  git clean -f
  git pull origin master

EOF

# run provision
cd ~$USERNAME/.install
make install

# TODO: kill dhcpcd
poweroff
