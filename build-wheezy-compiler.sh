#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

DIR=$PWD

build_arch="armhf"
host_arch=$(dpkg --print-architecture)
wheezy_binutils="2.22"
wheezy_binutils_pkg="2.22-8"
wheezy_gcc="4.6.3"
wheezy_gcc_pkg="4.6.3-14"

if [ ! -d "${DIR}/dl/" ] ; then
	mkdir -p "${DIR}/dl/" || true
fi

if [ ! -d "${DIR}/deploy/" ] ; then
	mkdir -p "${DIR}/deploy/" || true
fi

check_dpkg () {
	LC_ALL=C dpkg --list | awk '{print $2}' | grep "^${pkg}$" >/dev/null || deb_pkgs="${deb_pkgs}${pkg} "
}

check_dependencies () {
	unset deb_pkgs
	pkg="build-essential"
	check_dpkg
	pkg="binutils-multiarch"
	check_dpkg
	pkg="dpkg-cross"
	check_dpkg

	if [ "${deb_pkgs}" ] ; then
		echo "Installing: ${deb_pkgs}"
		sudo apt-get update
		sudo apt-get -y install ${deb_pkgs}
		sudo apt-get clean
	fi
}

check_foreign_architectures () {
	foreign=$(dpkg --print-foreign-architectures || true)
	if [ "x${foreign}" = "x" ] ; then
		echo "DPKG: adding ${build_arch}"
		sudo dpkg --add-architecture ${build_arch}
		sudo apt-get update
	fi
}

dpkg_cross_pkgs () {
	mkdir -p "${DIR}/dl/cross"
	cd "${DIR}/dl/cross"

	
	#dpkg-cross -i -a arm

	wget -c http://ftp.us.debian.org/debian/pool/main/l/linux/linux-libc-dev_3.2.54-2_armhf.deb
	if [ ! -f linux-libc-dev-armhf-cross_3.2.54-2_all.deb ] ; then
		sudo dpkg-cross --arch armhf -M -b linux-libc-dev_3.2.54-2_armhf.deb
	fi
	wget -c http://ftp.us.debian.org/debian/pool/main/e/eglibc/libc-dev-bin_2.13-38+deb7u1_armhf.deb
	if [ ! -f libc-dev-bin-armhf-cross_2.13-38+deb7u1_all.deb ] ; then
		sudo dpkg-cross --arch armhf -A -M -b libc-dev-bin_2.13-38+deb7u1_armhf.deb
	fi
	wget -c http://ftp.us.debian.org/debian/pool/main/e/eglibc/libc6-dev_2.13-38+deb7u1_armhf.deb
	if [ ! -f libc6-dev-armhf-cross_2.13-38+deb7u1_all.deb ] ; then
		sudo dpkg-cross --arch armhf -M -b libc6-dev_2.13-38+deb7u1_armhf.deb
	fi
	sudo dpkg -i *all
	exit
}

build_binutils () {
	echo "binutils: checking build-dep"
	sudo apt-get build-dep -y --no-install-recommends binutils
	cd "${DIR}/dl/"

	if [ -d "${DIR}/dl/binutils-${wheezy_binutils}/" ] ; then
		sudo rm -rf binutils* || true
	fi

	echo "binutils: downloading source"
	apt-get source binutils

	cd "${DIR}/dl/binutils-${wheezy_binutils}/"

	DEB_TARGET_ARCH=${build_arch} TARGET=${build_arch} dpkg-buildpackage -d -T control-stamp || true
	#dpkg-checkbuilddeps
	WITH_SYSROOT=/ DEB_TARGET_ARCH=${build_arch} TARGET=${build_arch} dpkg-buildpackage -b

	if [ ! -f "${DIR}/dl/binutils-arm-linux-gnueabihf_${wheezy_binutils_pkg}_${host_arch}.deb" ] ; then
		echo "binutils: build failure"
		exit
	else
		cp -v "${DIR}/dl/binutils-arm-linux-gnueabihf_${wheezy_binutils_pkg}_${host_arch}.deb" "${DIR}/deploy/"
		sudo dpkg -i "${DIR}/deploy/binutils-arm-linux-gnueabihf_${wheezy_binutils_pkg}_${host_arch}.deb"
	fi

	cd "${DIR}/"
}

build_gcc () {
	echo "gcc: checking build-dep"
	sudo apt-get build-dep -y --no-install-recommends gcc-4.6
	cd "${DIR}/dl/"

	if [ -d "${DIR}/dl/gcc-4.6-${wheezy_gcc}/" ] ; then
		sudo rm -rf gcc-4.6* || true
	fi

	echo "binutils: downloading source"
	apt-get source gcc-4.6

	cd "${DIR}/dl/gcc-4.6-${wheezy_gcc}/"

	DEB_TARGET_ARCH=${build_arch} DEB_CROSS_NO_BIARCH=yes with_deps_on_target_arch_pkgs=yes dpkg-buildpackage -d -T control
	dpkg-checkbuilddeps
	#WITH_SYSROOT=/ DEB_TARGET_ARCH=${build_arch} TARGET=${build_arch} dpkg-buildpackage -b

	#if [ ! -f "${DIR}/dl/binutils-arm-linux-gnueabihf_${wheezy_binutils_pkg}_${host_arch}.deb" ] ; then
	#	exit
	#else
	#	cp -v "${DIR}/dl/binutils-arm-linux-gnueabihf_${wheezy_binutils_pkg}_${host_arch}.deb" "${DIR}/deploy/"
	#	sudo dpkg -i "${DIR}/deploy/binutils-arm-linux-gnueabihf_${wheezy_binutils_pkg}_${host_arch}.deb"
	#fi

	cd "${DIR}/"
}


check_dependencies
check_foreign_architectures
dpkg_cross_pkgs
#build_binutils
build_gcc
#
