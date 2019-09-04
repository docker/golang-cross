FROM    golang:1.13.0

# allow replacing httpredir or deb mirror
ARG     APT_MIRROR=deb.debian.org
RUN     sed -ri "s/(httpredir|deb).debian.org/$APT_MIRROR/g" /etc/apt/sources.list

RUN     apt-get update -qq && apt-get install -y -q --no-install-recommends \
            libltdl-dev \
            gcc-mingw-w64 \
            parallel \
            ;

COPY    osx-cross.sh /tmp/
RUN     /tmp/osx-cross.sh
ENV     PATH /osxcross/target/bin:$PATH
