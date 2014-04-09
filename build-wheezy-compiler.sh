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

mirror="http://ftp.us.debian.org/debian/pool/main"
wget_dl="wget -c --no-verbose ${mirror}"

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

	echo "build-dep: installing for binutils/gcc-4.6"
	sudo apt-get build-dep -y --no-install-recommends binutils gcc-4.6
}

check_foreign_architectures () {
	foreign=$(dpkg --print-foreign-architectures || true)
	if [ "x${foreign}" = "x" ] ; then
		echo "DPKG: adding ${build_arch}"
		sudo dpkg --add-architecture ${build_arch}
		sudo apt-get update
	fi
}

dpkg_cross () {
dpkg_cross_options="-A -M -X gcc-4.3-base -X gcc-4.4-base -X debconf -X debconf-2.0 -X gcc-4.5-base -X gcc-4.6-base -X gcc-4.7-base -X multiarch-support"
	if [ ! -f ${pre}-${build_arch}-cross_${post}_all.deb ] ; then
		sudo dpkg-cross ${dpkg_cross_options} --arch armhf -b ${pre}_${post}_${build_arch}.deb
		if [ ! -f ${pre}-${build_arch}-cross_${post}_all.deb ] ; then
			exit
		else
			sudo dpkg --force-depends -i ${pre}-${build_arch}-cross_${post}_all.deb
		fi
	fi
}

dpkg_cross_all () {
dpkg_cross_options="-A -M -X gcc-4.3-base -X gcc-4.4-base -X debconf -X debconf-2.0 -X gcc-4.5-base -X gcc-4.6-base -X gcc-4.7-base -X multiarch-support"
	if [ ! -f ${pre}-${build_arch}-cross_${post}_all.deb ] ; then
		sudo dpkg-cross ${dpkg_cross_options} --arch armhf -b ${pre}_${post}_all.deb
		if [ ! -f ${pre}-${build_arch}-cross_${post}_all.deb ] ; then
			exit
		else
			sudo dpkg --force-depends -i ${pre}-${build_arch}-cross_${post}_all.deb
		fi
	fi
}

dpkg_cross_pkgs () {
	mkdir -p "${DIR}/dl/cross"
	cd "${DIR}/dl/cross"

	#http://git.emdebian.org/?p=debian/buildcross;a=blob;f=functions;h=7d4c2b96e7760dd3a4e55f87df7f1a213407f747;hb=HEAD#l640
	pre="linux-libc-dev"
	post="3.2.54-2"
	${wget_dl}/l/linux/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="gcc-4.7-base"
	post="4.7.2-5"
	${wget_dl}/g/gcc-4.7/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libgcc1"
	post="4.7.2-5"
	${wget_dl}/g/gcc-4.7/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="tzdata"
	post="2013i-0wheezy1"
	${wget_dl}/t/tzdata/${pre}_${post}_all.deb
	dpkg_cross_all

	pre="libc6"
	post="2.13-38+deb7u1"
	${wget_dl}/e/eglibc/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libc6-dev"
	post="2.13-38+deb7u1"
	${wget_dl}/e/eglibc/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libc-bin"
	post="2.13-38+deb7u1"
	${wget_dl}/e/eglibc/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libc-dev-bin"
	post="2.13-38+deb7u1"
	${wget_dl}/e/eglibc/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="zlib1g"
	post="1.2.7.dfsg-13"
	${wget_dl}/z/zlib/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="zlib1g-dev"
	post="1.2.7.dfsg-13"
	${wget_dl}/z/zlib/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libgmp10"
	post="5.0.5+dfsg-2"
	${wget_dl}/g/gmp/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libgmpxx4ldbl"
	post="5.0.5+dfsg-2"
	${wget_dl}/g/gmp/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libgmp-dev"
	post="5.0.5+dfsg-2"
	${wget_dl}/g/gmp/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libgmp3-dev"
	post="5.0.5+dfsg-2"
	${wget_dl}/g/gmp/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libmpfr4"
	post="3.1.0-5"
	${wget_dl}/m/mpfr4/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libmpfr-dev"
	post="3.1.0-5"
	${wget_dl}/m/mpfr4/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libstdc++6"
	post="4.7.2-5"
	${wget_dl}/g/gcc-4.7/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	pre="libgomp1"
	post="4.7.2-5"
	${wget_dl}/g/gcc-4.7/${pre}_${post}_${build_arch}.deb
	dpkg_cross

	cd "${DIR}/"
}

build_binutils () {
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
	cd "${DIR}/dl/"

	if [ -d "${DIR}/dl/gcc-4.6-${wheezy_gcc}/" ] ; then
		sudo rm -rf gcc-4.6* || true
	fi

	echo "binutils: downloading source"
	apt-get source gcc-4.6

	cd "${DIR}/dl/gcc-4.6-${wheezy_gcc}/"

	DEB_TARGET_ARCH=${build_arch} DEB_CROSS_NO_BIARCH=yes with_deps_on_target_arch_pkgs=yes dpkg-buildpackage -d -T control
	#dpkg-checkbuilddeps
	WITH_SYSROOT=/ DEB_TARGET_ARCH=${build_arch} TARGET=${build_arch} dpkg-buildpackage -b

	if [ ! -f "${DIR}/dl/gcc-4.6-arm-linux-gnueabihf_${wheezy_gcc_pkg}_${host_arch}.deb" ] ; then
		exit
	else
		cd "${DIR}/dl/"
		cp -v *.deb "${DIR}/deploy/"
		cd "${DIR}/deploy/"
		sudo dpkg -i *.deb
	fi

	cd "${DIR}/"
}


check_dependencies
check_foreign_architectures
dpkg_cross_pkgs
build_binutils
build_gcc
#
