#!/usr/bin/env bash
#
# Install dependencies required to cross compile osx, then cleanup
#
# TODO: this should be a separate build stage when CI supports it


set -eu -o pipefail

PKG_DEPS="patch xz-utils clang llvm file"

time apt-get install -y -q --no-install-recommends $PKG_DEPS

# NOTE: when changing version here, make sure to
# also change OSX_CODENAME below to match
OSX_SDK=MacOSX10.10.sdk
SDK_SUM=631b4144c6bf75bf7a4d480d685a9b5bda10ee8d03dbf0db829391e2ef858789

OSX_CROSS_COMMIT=a9317c18a3a457ca0a657f08cc4d0d43c6cf8953
OSXCROSS_PATH="/osxcross"

LIBTOOL_VERSION=2.4.6
OSX_CODENAME=yosemite

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
# Go 1.11 requires OSX >= 10.10
UNATTENDED=yes OSX_VERSION_MIN=10.10 ${OSXCROSS_PATH}/build.sh > /dev/null

echo "Installing libtool from brew"
curl -sSL https://homebrew.bintray.com/bottles/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz \
	| gzip -dc | tar xf - \
		-C ${OSXCROSS_PATH}/target/SDK/${OSX_SDK}/usr/ \
		--strip-components=2 \
		libtool/${LIBTOOL_VERSION}/include/ \
		libtool/${LIBTOOL_VERSION}/lib/
