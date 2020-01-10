#!/usr/bin/env sh

version=$(grep GO_VERSION= Dockerfile)

docker build -t dockercore/golang-cross .
docker tag dockercore/golang-cross dockercore/golang-cross:dev
docker tag dockercore/golang-cross dockercore/golang-cross:${version#*=}
