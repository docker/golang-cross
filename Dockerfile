ARG GO_VERSION=1.12.14

# OS-X SDK parameters
# NOTE: when changing version here, make sure to also change OSX_CODENAME below to match
ARG OSX_SDK=MacOSX10.10.sdk
ARG OSX_SDK_SUM=631b4144c6bf75bf7a4d480d685a9b5bda10ee8d03dbf0db829391e2ef858789

# OSX-cross parameters. Go 1.11 requires OSX >= 10.10
ARG OSX_VERSION_MIN=10.10
ARG OSX_CROSS_COMMIT=a9317c18a3a457ca0a657f08cc4d0d43c6cf8953

# Libtool parameters
ARG LIBTOOL_VERSION=2.4.6
ARG OSX_CODENAME=yosemite

FROM golang:${GO_VERSION}-buster AS base
ARG APT_MIRROR
RUN sed -ri "s/(httpredir|deb).debian.org/${APT_MIRROR:-deb.debian.org}/g" /etc/apt/sources.list \
 && sed -ri "s/(security).debian.org/${APT_MIRROR:-security.debian.org}/g" /etc/apt/sources.list
ENV OSX_CROSS_PATH=/osxcross

FROM base AS osx-sdk
ARG OSX_SDK
ARG OSX_SDK_SUM
ADD https://s3.dockerproject.org/darwin/v2/${OSX_SDK}.tar.xz "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz"
RUN echo "${OSX_SDK_SUM}"  "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}.tar.xz" | sha256sum -c -

FROM base AS osx-cross-base
ARG DEBIAN_FRONTEND=noninteractive
# Dependencies for https://github.com/tpoechtrager/osxcross:
# TODO split these into "build-time" and "runtime" dependencies so that build-time deps do not end up in the final image
RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
    clang \
    file \
    llvm \
    patch \
    xz-utils \
 && rm -rf /var/lib/apt/lists/*

FROM osx-cross-base AS osx-cross
ARG OSX_CROSS_COMMIT
WORKDIR "${OSX_CROSS_PATH}"
RUN git clone https://github.com/tpoechtrager/osxcross.git . \
 && git checkout -q "${OSX_CROSS_COMMIT}" \
 && rm -rf ./.git
COPY --from=osx-sdk "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ARG OSX_VERSION_MIN
RUN UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh

FROM base AS libtool
ARG LIBTOOL_VERSION
ARG OSX_CODENAME
ARG OSX_SDK
RUN mkdir -p "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/"
RUN curl -fsSL "https://homebrew.bintray.com/bottles/libtool-${LIBTOOL_VERSION}.${OSX_CODENAME}.bottle.tar.gz" \
	| gzip -dc | tar xf - \
		-C "${OSX_CROSS_PATH}/target/SDK/${OSX_SDK}/usr/" \
		--strip-components=2 \
		"libtool/${LIBTOOL_VERSION}/include/" \
		"libtool/${LIBTOOL_VERSION}/lib/"

FROM osx-cross-base AS final
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -q --no-install-recommends \
    libltdl-dev \
    gcc-mingw-w64 \
    parallel \
 && rm -rf /var/lib/apt/lists/*

COPY --from=osx-cross "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
COPY --from=libtool   "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ENV PATH=${OSX_CROSS_PATH}/target/bin:$PATH
