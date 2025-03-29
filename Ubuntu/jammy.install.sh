#!/bin/bash
#
# jammy.install.sh: 
#    This script installs Bodhi Linux 7.x on an existing Ubuntu 22.04 install.
#    Review pkgs install in the sections
#        ## Optional Software
#        ## Optional Bodhi Packages
#    Below and remove anything you may not need or do not want
#
# Copyright 2023 ylee@bodhilinux.com
#
# This script is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3 of the License, or (at
# your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this script; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

echo "This script will install Moksha on Ubuntu 22.04 (Jammy)."
echo

# Ensure user has sudo privileges
if ! sudo -v; then
  echo "This User does not have sudo privileges."
  echo "Install aborted!!"
  exit 1
fi

# to do deal with cpu 32-bit or 64-bit
arch=$(uname -m)
case "$arch" in
    x86_64) arch=64 ;;
    * ) echo "Unsupported CPU Architecture"
        echo "Install aborted!!"
        exit 2;;
esac

# Ensure this is a Debian Distro
if [ ! -f /etc/debian_version ]; then
    echo "debian_version file not found!"
    echo "Unsupported Distro."
    echo "Install aborted!!"
    exit 3
fi

# Test lsb_release to see if Jammy
release=$(lsb_release -c | awk '{print $2}')
if [[ "$release" != "jammy" ]]; then
  echo "Unsupported release: $release"
  echo "Install aborted!!"
  exit 4
fi

# Ensure Moksha or Enlightenment is not already installed
if which enlightenment_remote; then
  echo "Moksha or enlightenment is installed."
  echo "Please uninstall whichever is installed."
  echo "Install aborted!!"
  exit 6
fi

echo
read -r -p "Continue (y/n)? " choice
echo
case "$choice" in
  y|Y ) echo "Installing moksha ...";;
  n|N ) echo "Install aborted!!"
        exit 1;;
  * ) exit 255;;
esac
echo

# just in case
rm -rf "$HOME/.e"
sudo apt update
sudo  apt -y install wget

# the temp directory used to download deb files
TEMP_DIR=$(mktemp -d)

# check if tmp dir was created
if [[ ! "$TEMP_DIR" || ! -d "$TEMP_DIR" ]]; then
  echo "Could not create temp dir"
  echo "Install aborted!!"
  exit 1
fi

# deletes the temp directory
# shellcheck disable=SC2317
function cleanup {
  rm -rf "$TEMP_DIR"
  echo "Deleted temp working directory $TEMP_DIR"
}

# ensure cleanup function is called on EXIT
trap cleanup EXIT

# Install bodhi keyring and bodhi-settings

pushd "$PWD"  &>/dev/null
cd "$TEMP_DIR" || exit 1

wget http://packages.bodhilinux.com/bodhi/pool/b7main/b/bodhilinux-keyring/bodhilinux-keyring_2022.11.07_all.deb
wget http://packages.bodhilinux.com/bodhi/pool/b7main/u/ubuntu-system-adjustments/ubuntu-system-adjustments_0.0.1-1_all.deb
wget http://packages.bodhilinux.com/bodhi/pool/b7main/b/bodhi-info-moksha/bodhi-info-moksha_0.0.1-1_all.deb
wget http://packages.bodhilinux.com/bodhi/pool/b7main/b/bodhi-settings/bodhi-settings_0.0.1-7_all.deb

sudo apt -y --no-install-recommends install ./*.deb

popd  &>/dev/null

sudo apt update

# Install moksha, default themes and other needed pkgs
sudo apt  -y --no-install-recommends  install arandr bodhi-bins-default bodhi-quickstart  elaptopcheck moksha-menu moksha bodhi-theme-moksha-green bodhi-theme-moksha-e17gtk
sudo apt  -y install gtk-recent pavucontrol xclip bc udisks2

## Optional Software
sudo apt -y install synaptic terminology ephoto-bl leafpad bodhi-chromium thunar-bl xdg-user-dirs policykit-1-gnome

## Optional Bodhi Packages
sudo apt -y install bodhi-appcenter bodhi-icons bodhi-skel

# bodhi-sankhara currently installs nothing
#  but its post install script is used to make changes to a few system files
#  That is its sole purpose.
sudo apt -y install bodhi-sankhara

# apturl is needed to support our online AppCenter
if which apturl; then
  echo "Ubuntu's apturl is installed."
  echo "Not installing Bodhi's"
else
  echo "Installing Bodhi's apturl"
  sudo apt -y install apturl-saf
fi

# Uncomment if you need it
# sudo apt -y install nvidia-ppa

exit 0
