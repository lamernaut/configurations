#!/usr/bin/env bash

# Function executes a given command, detects the execution result and stops installation if error is occurred.
# param $1 - command description label
# param $2 - command with arguments
function run_command () {
	# Display a command description
	echo -n "$1... "
	# Execute a command
	$2 >/dev/null 2>/dev/null
	# Check a command execution result
	if [ $? = 0 ]; then
		# Command execution is successfully
		echo "OK"
	else
		# Error detected, repeat command for display an error message
		echo "FAILED"
		$2
		echo ""
		# Stop a script execution
		exit 1
	fi
}

clear

# Function installs a package with a given name
# param $1 - a package name
function pkg_install () {
	run_command "Install package $1" "$PACKAGE_INSTALL $1"
}

# Function executes a command without output
# param $1 - a command to execute
function execute () {
	$1 >/dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "FAILED"
		$1
		exit 1
	fi
}

YUM="sudo -E yum -y"
PACKAGE_INSTALL="$YUM install"
BUILD_DIR=/tmp/GNUstep.build

sudo -E rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

echo -n "Update packages repositories..."
$YUM check-update >/dev/null 2>/dev/null
echo "OK"

pkg_install make
pkg_install cmake
pkg_install subversion
pkg_install clang

export CC=clang
export CXX=clang++

pkg_install ninja-build
pkg_install libffi-devel
pkg_install libxml2-devel
pkg_install gnutls-devel
pkg_install libicu-devel
pkg_install wget
pkg_install git

echo -n "Install libblocksruntime... "
cd $BUILD_DIR
execute "git clone https://github.com/mackyle/blocksruntime.git"
cd blocksruntime
export CFLAGS=-fPIC
execute "./buildlib"
execute "sudo -E ./installlib"
sudo -E cp BlocksRuntime/Block_private.h /usr/local/include/
echo "OK"
export CFLAGS=

echo -n "Install libkqueue... "
cd $BUILD_DIR
execute "git clone https://github.com/mheily/libkqueue.git"
cd libkqueue
mkdir build; cd build
execute "cmake .."
execute "gmake"
execute "sudo -E gmake install"
echo "OK"

echo -n "Install libpwq... "
cd $BUILD_DIR
execute "git clone https://github.com/mheily/libpwq.git"
cd libpwq
mkdir build; cd build
execute "cmake .."
execute "gmake"
execute "sudo -E gmake install"
echo "OK"

pkg_install autoconf
pkg_install libtool
pkg_install libjpeg-devel
pkg_install libtiff-devel
pkg_install cairo-devel
pkg_install libXt-devel
pkg_install libXft-devel
pkg_install llvm-devel
pkg_install llvm-static

echo -n "Install libdispatch... "
cd $BUILD_DIR
execute "git clone https://github.com/nickhutchinson/libdispatch.git"
cd libdispatch
mkdir build; cd build
execute "cmake .."
execute "gmake"
execute "sudo -E gmake install"
echo "OK"

pkg_install patch
pkg_install libxslt-devel

cd $BUILD_DIR

# Download sources
run_command "Download libobjc2"		"wget https://github.com/gnustep/libobjc2/archive/v1.8.1.tar.gz"
run_command "Download gnustep-make"	"wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-make-2.6.8.tar.gz"
run_command "Download gnustep-base"	"wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-base-1.24.9.tar.gz"
run_command "Download gnustep-gui"	"wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-gui-0.25.0.tar.gz"
run_command "Download gnustep-back"	"wget ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-back-0.25.0.tar.gz"

run_command "Unpack libobjc2"		"tar -xvzf v1.8.1.tar.gz"
run_command "Unpack gnustep-make"	"tar -xvzf gnustep-make-2.6.8.tar.gz"
run_command "Unpack gnustep-base"	"tar -xvzf gnustep-base-1.24.9.tar.gz"
run_command "Unpack gnustep-gui"	"tar -xvzf gnustep-gui-0.25.0.tar.gz"
run_command "Unpack gnustep-back"	"tar -xvzf gnustep-back-0.25.0.tar.gz"

cd $BUILD_DIR/gnustep-make-2.6.8
run_command "Configure gnustep-make"	"./configure --enable-debug-by-default --with-layout=gnustep --enable-objc-nonfragile-abi --enable-objc-arc"
run_command "Install gnustep-make"	"sudo -E gmake install"
export LIBRARY_PATH=/usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64
export LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64
. /usr/GNUstep/System/Library/Makefiles/GNUstep.sh

cd $BUILD_DIR/libobjc2-1.8.1
rm -Rf build
mkdir build && cd build
run_command "Make libobjc2"	"cmake ../ -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang -DCMAKE_ASM_COMPILER=clang -DTESTS=OFF"
run_command "Build libobjc2"	"cmake --build ."
run_command "Install libobjc2"	"sudo -E gmake install"
sudo ldconfig
export LDFLAGS=-ldispatch
OBJCFLAGS="-fblocks -fobjc-runtime=gnustep-1.8.1"

cd $BUILD_DIR/gnustep-make-2.6.8
run_command "Reconfigure gnustep-make"	"./configure --enable-debug-by-default --with-layout=gnustep --enable-objc-nonfragile-abi --enable-objc-arc"
run_command "Reinstall gnustep-make"	"sudo -E gmake install"

cd $BUILD_DIR/gnustep-base-1.24.9
run_command "Configure gnustep-base"	"./configure"
run_command "Build gnustep-base"	"gmake -j8"
run_command "Iinstall gnustep-base"	"sudo -E gmake install"

cd $BUILD_DIR/gnustep-gui-0.25.0
run_command "Configure gnustep-gui"	"./configure"
run_command "Build gnustep-gui"		"gmake -j8"
run_command "Iinstall gnustep-gui"	"sudo -E gmake install"

cd $BUILD_DIR/gnustep-back-0.25.0
run_command "Configure gnustep-back"	"./configure"
run_command "Build gnustep-back"	"gmake -j8"
run_command "Iinstall gnustep-back"	"sudo -E gmake install"

rm -rf $BUILD_DIR

# GNUstep was successfully installed
echo "GNUstep was successfully installed"
echo ""
echo "For sh or bash add into the /etc/profile or ~/.profile the following strings:"
echo "export LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64"
echo "export CC=clang"
echo "export CXX=clang++"
echo ". /usr/GNUstep/System/Library/Makefiles/GNUstep.sh"
echo ""
echo "For csh add into the /etc/csh.login or ~/.login the following strings:"
echo "setenv LD_LIBRARY_PATH /usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64"
echo "setenv CC clang"
echo "setenv CXX=clang++"
echo "source /usr/GNUstep/System/Library/Makefiles/GNUstep.csh"
echo ""
