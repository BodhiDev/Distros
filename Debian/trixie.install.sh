#!/bin/bash
#
# trixie.install.sh: 
#    This script installs Bodhi Linux 8.x on an existing Debian 13 install.
#    Review pkgs install in the sections
#        ## Optional Software
#        ## Optional Bodhi Packages
#    Below and remove anything you may not need or do not want
#
# Copyright 2025 ylee@bodhilinux.com
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

echo "This script will install Moksha on Debian 13 (trixie)."
echo

# Ensure user has sudo privileges
if ! sudo -v; then
  echo "This User does not have sudo privileges."
  echo "Install aborted!!"
  exit 1
fi

# Ensure supported CPU Architecture
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

# Test to see if trixie
if [ ! -f /etc/os-release ]; then
    echo "os-release file not found!"
    echo "Unsupported Distro."
    echo "Install aborted!!"
    exit 3
fi

# shellcheck disable=SC1091
. /etc/os-release

if [[ "$VERSION_CODENAME" != "trixie" ]]; then
  echo "Unsupported release: $NAME $VERSION_CODENAME"
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

# Ensure EFL is not already installed
if which elementary_config; then
  echo "Elementary a part of EFL is installed already."
  echo "Please uninstall all EFL libraries."
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
rm -rf "$HOME/.config/e"
sudo apt update
sudo  apt -y install wget

# the temp directory used to download deb files
TEMP_DIR=$(mktemp -d)

# check if tmp dir was created
if ! [[ "$TEMP_DIR" ]]; then
  echo "Could not create temp dir"
  echo "Install aborted!!"
  exit 1
fi

# deletes the temp directory
function cleanup {
  rm -rf "$TEMP_DIR"
  echo "Deleted temp working directory $TEMP_DIR"
}

# ensure cleanup function is called on EXIT
trap cleanup EXIT

# Install bodhi keyring, apt sources, and misc settings

pushd "$PWD"  &>/dev/null || exit
cd "$TEMP_DIR" || exit 1

wget http://packages.bodhilinux.com/bodhi/pool/b8debbie/b/bodhilinux-keyring/bodhilinux-keyring_2022.11.07_all.deb
wget http://packages.bodhilinux.com/bodhi/pool/b8debbie/d/debian-system-adjustments/debian-system-adjustments_2025.12.02_all.deb
wget http://packages.bodhilinux.com/bodhi/pool/b8debbie/b/bodhi-info-moksha/bodhi-info-moksha_0.0.1-1_all.deb
wget http://packages.bodhilinux.com/bodhi/pool/b8debbie/b/bodhi-apt-source/bodhi-apt-source_0.0.1-2_all.deb

sudo apt -y --no-install-recommends install ./*.deb

popd  &>/dev/null || exit

# Update
sudo apt update

# Install moksha, default themes and other needed pkgs
# Note: moksha-green theme is needed for now as it is the default moksha theme
sudo apt  -y --no-install-recommends  install arandr bodhi-bins-default bodhi-quickstart  bodhi-startup moksha-menu moksha bodhi-theme-moksha-green bodhi-theme-moksha-e17gtk
sudo apt  -y install gtk-recent pavucontrol xsel bc udisks2

# Install BL8 default theme
sudo apt  -y --no-install-recommends  install bodhi-theme-moksha-zenithal

## Optional Software
sudo apt -y install synaptic xdg-user-dirs  ephoto-bl lxpolkit
# sudo apt -y install terminology
# sudo apt -y install leafpad

## Optional Bodhi Packages
sudo apt -y install bodhi-appcenter bodhi-skel

# apturl is needed to support our online AppCenter
if which apturl; then
  echo "Ubuntu's apturl is installed."
  echo "Not installing Bodhi's"
else
  echo "Installing Bodhi's apturl"
  sudo apt -y install apturl-saf
fi

## With no DE installed initially on trixie
##     zutty (a terminal) is installed but can not launche
##     It is missing the below package
sudo apt install xfonts-base

## With no DE installed initially on trixie
##     You may wish to consider installing a DM
##      Uncomment below to install the DM and theme Bodhi uses

# sudo apt install bodhi-slick-theme

echo
echo "If there were no errors Moksha was succesfully installed"

