#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ARCH=$(uname -m)

apt update
apt install -y libltdl7 libnss3

ARCH=$(uname -m)
BUILD_DIR=${DIR}/../build/files/python
docker ps -a -q --filter ancestor=python:syncloud --format="{{.ID}}" | xargs docker stop | xargs docker rm || true
docker rmi python:syncloud || true
docker build -t python:syncloud .
docker run --rm python:syncloud python --help
docker run --rm python:syncloud uwsgi --help
docker create --name=python python:syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export python -o python.tar
tar xf python.tar
rm -rf python.tar
docker rm python
docker rmi python:syncloud
cp ${DIR}/bin/* ${BUILD_DIR}/bin
rm -rf ${BUILD_DIR}/usr/src
