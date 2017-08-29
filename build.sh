#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

NAME=files

if [[ -z "$2" ]]; then
    echo "usage $0 version installer"
    exit 1
fi

ARCH=$(uname -m)
VERSION=$1
INSTALLER=$2

BUILD_DIR=${DIR}/build/${NAME}
rm -rf build
mkdir -p ${BUILD_DIR}

DOWNLOAD_URL=http://artifact.syncloud.org/3rdparty
coin --to ${BUILD_DIR} raw ${DOWNLOAD_URL}/nginx-${ARCH}.tar.gz
coin --to ${BUILD_DIR} raw ${DOWNLOAD_URL}/uwsgi-${ARCH}.tar.gz
coin --to ${BUILD_DIR} raw ${DOWNLOAD_URL}/python-${ARCH}.tar.gz

${BUILD_DIR}/python/bin/pip install -r ${DIR}/requirements.txt

cd src
echo ${VERSION} > version
${BUILD_DIR}/python/bin/python setup.py install
cd ..

cp -r ${DIR}/bin ${BUILD_DIR}
cp -r ${DIR}/hooks ${BUILD_DIR}
cp -r ${DIR}/config ${BUILD_DIR}/config.templates
cp -r ${DIR}/www ${BUILD_DIR}

mkdir ${BUILD_DIR}/META
echo ${NAME} > ${BUILD_DIR}/META/app
echo ${VERSION} > ${BUILD_DIR}/META/version

if [ $INSTALLER == "sam" ]; then

    echo "zipping"
    rm -rf ${NAME}*.tar.gz
    tar cpzf ${DIR}/${NAME}-${VERSION}-${ARCH}.tar.gz -C ${DIR}/build/ ${NAME}

else

    echo "snapping"
    ARCH=$(dpkg-architecture -q DEB_HOST_ARCH)
    rm -rf ${DIR}/*.snap
    mkdir ${SNAP_DIR}
    cp -r ${BUILD_DIR}/* ${SNAP_DIR}/
    cp -r ${DIR}/snap/meta ${SNAP_DIR}/
    cp ${DIR}/snap/snap.yaml ${SNAP_DIR}/meta/snap.yaml
    echo "version: $VERSION" >> ${SNAP_DIR}/meta/snap.yaml
    echo "architectures:" >> ${SNAP_DIR}/meta/snap.yaml
    echo "- ${ARCH}" >> ${SNAP_DIR}/meta/snap.yaml

    mksquashfs ${SNAP_DIR} ${DIR}/${NAME}_${VERSION}_${ARCH}.snap -noappend -comp xz -no-xattrs -all-root

fi