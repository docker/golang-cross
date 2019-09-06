#!/usr/bin/env bash
#
# Install dependencies required to cross compile osx, then cleanup
#
# TODO: this should be a separate build stage when CI supports it


set -eu -o pipefail

# Based on the README at https://github.com/tpoechtrager/osxcross:
# https://github.com/tpoechtrager/osxcross/blob/d39ba022313f2d5a1f5d02caaa1efb23d07a559b/README.md
#
# ensure you have the following installed on your system:
#
# Clang 3.4+, cmake, git, patch, Python, libssl-devel (openssl)
# lzma-devel, libxml2-devel and the bash shell.
#
# You can run 'sudo tools/get_dependencies.sh' to get these (and the optional packages) automatically. (outdated)
#
# Optional:
# - llvm-devel: For Link Time Optimization support
# - llvm-devel: For ld64 -bitcode_bundle support
# - uuid-devel: For ld64 -random_uuid support
#
# TODO for testing, also added dependencies that were installed by the get_dependencies.sh script (but it's mentioned to be "outdated"
# https://github.com/tpoechtrager/osxcross/blob/d39ba022313f2d5a1f5d02caaa1efb23d07a559b/tools/get_dependencies.sh#L43-L47
time apt-get install -y -q --no-install-recommends \
   bzip2 \
   clang \
   cmake \
   cpio \
   file \
   gzip \
   libbz2-dev \
   liblzma-dev \
   libssl-dev \
   libxml2-dev \
   llvm \
   make \
   patch \
   sed \
   tar \
   xz-utils \
   zlib1g-dev \
   \
   llvm-dev \
   uuid-dev \
&& rm -rf /var/lib/apt/lists/*

# NOTE: when changing version here, make sure to
# also change OSX_CODENAME below to match
OSX_SDK=MacOSX10.10.sdk
SDK_SUM=631b4144c6bf75bf7a4d480d685a9b5bda10ee8d03dbf0db829391e2ef858789

OSX_CROSS_COMMIT=d39ba022313f2d5a1f5d02caaa1efb23d07a559b
OSXCROSS_PATH="/osxcross"

LIBTOOL_VERSION=2.4.6
OSX_CODENAME=el_capitan

echo "Cloning osxcross"
time git clone https://github.com/tpoechtrager/osxcross.git $OSXCROSS_PATH
cd $OSXCROSS_PATH
git checkout -q $OSX_CROSS_COMMIT

echo "Downloading OSX SDK"
time curl -sSL https://s3.dockerproject.org/darwin/v2/${OSX_SDK}.tar.xz \
    -o "${OSXCROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"

echo "$SDK_SUM  ${OSXCROSS_PATH}/tarballs/${OSX_SDK}.tar.xz" \
	| sha256sum -c -

echo "Building osxcross"
# Go 1.13 requires OSX >= 10.11
UNATTENDED=yes OSX_VERSION_MIN=10.11 ${OSXCROSS_PATH}/build.sh > /dev/null

echo "Installing libtool from brew"
curl -sSL https://homebrew.bintray.com/bottles/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz \
	| gzip -dc | tar xf - \
		-C ${OSXCROSS_PATH}/target/SDK/${OSX_SDK}/usr/ \
		--strip-components=2 \
		libtool/${LIBTOOL_VERSION}/include/ \
		libtool/${LIBTOOL_VERSION}/lib/
