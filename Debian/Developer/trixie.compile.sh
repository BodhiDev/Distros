#!/bin/bash
#
# trixie.compile.sh: 
#    This script installs Bodhi Linux 8.x on an existing Debian 13 install.
#    Moksha and EFL are compiled from source with debugging support.
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

##  Recommends CFLAGS for debugging (Adjust as necessary)
export CFLAGS="-g3 -O0 -fdiagnostics-color=always"

# just in case
rm -rf "$HOME/.config/e"

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

# Install needed commands
sudo apt update
sudo  apt -y install wget git

# Install compile tools
sudo  apt -y install build-essential check cmake meson pkg-config

# Install tools for debugging 
sudo apt -y install openssh-server gdb gdbserver xserver-xephyr valgrind

## With no DE installed initially on trixie
##     zutty (a terminal) is installed but can not launch
##     It is missing the below package
sudo apt -y install xfonts-base

# Install EFL dependencies
sudo apt -y install libavif-dev \
	 libblkid-dev \
	 libssl-dev \
	 libcurl4-openssl-dev \
	 libdbus-1-dev \
	 libfontconfig-dev \
	 libfreetype-dev \
	 libfribidi-dev \
	 libgbm-dev \
	 libgcrypt-dev \
	 libgif-dev \
	 libgles2-mesa-dev \
	 libglib2.0-dev \
	 libgstreamer-plugins-base1.0-dev \
	 libgstreamer1.0-dev \
	 libharfbuzz-dev \
	 libheif-dev \
	 libinput-dev \
	 libjxl-dev \
	 libjpeg-dev \
	 liblua5.2-dev \
	 liblua5.1-dev \
	 libluajit-5.1-dev \
	 liblz4-dev \
	 libmount-dev \
	 libopenjp2-7-dev \
	 libpixman-1-dev \
	 libpng-dev \
	 libpoppler-cpp-dev \
	 libpulse-dev \
	 libraw-dev \
	 librsvg2-dev \
	 libscim-dev \
	 libsndfile-dev \
	 libspectre-dev \
	 libsystemd-dev \
	 libtiff-dev \
	 libudev-dev \
	 libunibreak-dev \
	 libunwind-dev \
	 libvlc-dev \
	 libwayland-dev \
	 libwebp-dev \
	 libx11-dev \
	 libx11-xcb-dev \
	 libxcb-image0-dev \
	 libxcb-shm0-dev \
	 libxcb1-dev \
	 libxcomposite-dev \
	 libxcursor-dev \
	 libxdamage-dev \
	 libxext-dev \
	 libxi-dev \
	 libxinerama-dev \
	 libxkbcommon-x11-dev \
	 libxpm-dev \
	 libxpresent-dev \
	 libxrandr-dev \
	 libxrender-dev \
	 libxss-dev \
	 libxtst-dev \
	 lua5.2 \
	 mesa-common-dev \
	 systemd-dev \
	 wayland-protocols \
	 x11proto-xext-dev \
	 zlib1g-dev

mkdir Code/ || exit
cd Code/ || exit
git clone https://git.enlightenment.org/enlightenment/efl/
cd efl || exit

# Apply Bodhi's patch to eliminate a lot of EFL noise in stdout/stderr
wget https://raw.githubusercontent.com/BodhiDev/bodhi8packages/refs/heads/main/efl/trixie/debian/patches/50_silence_efl_bodhi.diff
patch -p1 < 50_silence_efl_bodhi.diff

# Build EFL
meson setup build --prefix=/usr -Dtslib=false \
		-Dembedded-lz4=false \
		-Dnetwork-backend=none \
		-Dwl=false \
		-Ddrm=false \
		-Dbuild-tests=false \
		-Dxpresent=true \
		-Ddocs=false \
		-Devas-loaders-disabler="['json']" \
		-Dopengl=full \
         -Dfb=true \
		-Delua=true -Dbindings="['lua', 'cxx']"

ninja -C build
sudo ninja -C build install
cd ..

# Compile Moksha
sudo  apt -y install libasound2-dev  libxext-dev libpam0g-dev libxcb-shape0-dev dbus-x11 libxcb-keysyms1-dev libudisks2-dev 
git clone https://github.com/JeffHoogland/moksha
cd moksha/ || exit
./autogen.sh --prefix=/usr
make
sudo make all install
cd ..

# Compile ephoto
git clone https://github.com/rbtylee/ephoto
cd ephoto || exit
meson setup build
ninja -C build
sudo ninja -C build install
cd ..

# Compile terminology

git clone https://git.enlightenment.org/enlightenment/terminology
cd terminology || exit
meson setup build
ninja -C build
sudo ninja -C build install
cd ..

# Compile some utilies

## set-background-bodhi
wget https://raw.githubusercontent.com/BodhiDev/bodhi8packages/refs/heads/main/bodhi/bodhi-bins-default/trixie/usr/bin/set-background-bodhi
chmod +x set-background-bodhi
sudo mv set-background-bodhi /usr/bin

## evas-image-dim
wget https://gist.githubusercontent.com/rbtylee/d8c156b97144dcc57fede8524864e692/raw/2de74f26e4e065d2caa8a8ea88e7e3372ca69732/evas-image-dim
mv evas-image-dim evas-image-dim.c
read -ra pkg_flags < <(pkg-config --libs --cflags evas ecore ecore-evas)
gcc -o evas-image-dim evas-image-dim.c "${pkg_flags[@]}"
sudo mv evas-image-dim /usr/bin
rm evas-image-dim.c

## elf-version
git clone https://github.com/BodhiDev/Moksha-dev
cd Moksha-dev/elf-version/ || exit
meson setup build
ninja -C build
sudo ninja -C build install
cd ../..
rm -rf Moksha-dev
# shellcheck disable=SC2103
cd ..

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

## To make debugging a bit easier (Optional but recommended)
sudo  apt -y install moksha-debug

# Install moksha, default themes and other needed pkgs
# Note: moksha-green theme is needed for now as it is the default moksha theme
sudo apt  -y --no-install-recommends  install arandr bodhi-quickstart  bodhi-startup moksha-menu bodhi-theme-moksha-green bodhi-theme-moksha-e17gtk
sudo apt  -y install gtk-recent pavucontrol xsel bc udisks2

# Install BL8 default theme
sudo apt  -y --no-install-recommends  install bodhi-theme-moksha-zenithal

## Optional Software
sudo apt -y install synaptic xdg-user-dirs lxpolkit mousepad chromium thunar
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
##     You may wish to consider installing a DM
##      Uncomment below to install the DM and theme Bodhi uses

# sudo  apt -y install bodhi-slick-theme

echo
echo "If there were no errors everything was succesfully installed"

