#!/bin/bash -x

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
NAME="files"

if [[ -z "$1" || -z "$2" ]]; then
    echo "usage $0 app_arch app_version"
    exit 1
fi

ARCH=$1
VERSION=$2

ARCH_DEB="unknown"
if [ "${ARCH}" == 'x86_64' ]; then
    ARCH_DEB="amd64"
fi
if [ "${ARCH}" == 'armv7l' ]; then
    ARCH_DEB="armhf"
fi

rm -f src/version
echo ${VERSION} >> src/version

cd src
python setup.py sdist
cd ..

./coin_lib.sh ${ARCH}
coin  --to ${DIR}/lib py ${DIR}/src/dist/syncloud-files-${VERSION}.tar.gz

BUILD_DIR=${DIR}/build/${NAME}
rm -rf build
mkdir -p ${BUILD_DIR}

DOWNLOAD_URL=http://build.syncloud.org:8111/guestAuth/repository/download
coin --to ${BUILD_DIR} raw ${DOWNLOAD_URL}/thirdparty_nginx_${ARCH}/lastSuccessful/nginx-${ARCH}.tar.gz
coin --to ${BUILD_DIR} raw ${DOWNLOAD_URL}/thirdparty_uwsgi_${ARCH}/lastSuccessful/uwsgi-${ARCH}.tar.gz
coin --to ${BUILD_DIR} raw ${DOWNLOAD_URL}/thirdparty_python_${ARCH}/lastSuccessful/python-${ARCH}.tar.gz

cp -r ${DIR}/bin ${BUILD_DIR}
cp -r ${DIR}/templates ${BUILD_DIR}
cp -r ${DIR}/config ${BUILD_DIR}
cp -r ${DIR}/www ${BUILD_DIR}
cp -r ${DIR}/lib ${BUILD_DIR}

path_file=${BUILD_DIR}/python/lib/python2.7/site-packages/path.pth
ls ${BUILD_DIR}/lib/  > ${path_file}
sed -i 's#^#../../../../lib/#g' ${path_file}

mkdir ${BUILD_DIR}/META
echo ${NAME} >> ${BUILD_DIR}/META/app
echo ${VERSION} >> ${BUILD_DIR}/META/version

echo "zipping"
rm -rf ${NAME}*.tar.gz
tar cpzf ${DIR}/${NAME}-${VERSION}-${ARCH}.tar.gz -C ${DIR}/build/ ${NAME}