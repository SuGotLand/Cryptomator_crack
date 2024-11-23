#!/bin/bash
set -e

cd $(dirname $0)

if [ -z "${JAVA_HOME}" ]; then echo "JAVA_HOME not set. Run using JAVA_HOME=/path/to/jdk ./build.sh"; exit 1; fi
command -v mvn >/dev/null 2>&1 || { echo >&2 "mvn not found."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip not found."; exit 1; }

: <<COMMENT
echo "请输入版本号(e.g. 1.7.0-beta1, 1.5.1-release): "
read SEM_VER_STR
echo "版本为${SEM_VER_STR}"
COMMENT
SEM_VER_NUM=`mvn -f ../../pom.xml -Dexec.executable='echo' -Dexec.args='${project.version}' --non-recursive exec:exec -q`
SEM_VER_STR=`echo ${SEM_VER_NUM}-release`
REVCOUNT=`git rev-list --count HEAD`
cd ../..
mvn clean package -Plinux -Djavafx.platform=linux -DskipTests

#OPENJFX_JMODS_AMD64="https://download2.gluonhq.com/openjfx/23/openjfx-23_linux-x64_bin-jmods.zip"
#OPENJFX_JMODS_AMD64_HASH='72a2390a117e024d1a897cbe216c7c99cb464519f488ae3701186cef5ab5a116'
#OPENJFX_JMODS_AARCH64="https://download2.gluonhq.com/openjfx/23/openjfx-23_linux-aarch64_bin-jmods.zip"
#OPENJFX_JMODS_AARCH64_HASH='dda2719d7dcac1ac3e33d853974e7baf5b55b7d5ea2a37a0162d25b8b32d0e36'

OPENJFX_JMODS_AMD64='https://download2.gluonhq.com/openjfx/22.0.2/openjfx-22.0.2_linux-x64_bin-jmods.zip'
OPENJFX_JMODS_AMD64_HASH='d44bff3b94d5668fdee18a938d7b1269026d663d44765f02d29a9bdfd3fa1eb0'
OPENJFX_JMODS_AARCH64='https://download2.gluonhq.com/openjfx/22.0.2/openjfx-22.0.2_linux-aarch64_bin-jmods.zip'
OPENJFX_JMODS_AARCH64_HASH='3d5457136690c4f5bb9522d38b45218e045bdac13c24aa4c808c7c8d17d039c7'


curl -L $OPENJFX_JMODS_AMD64 -o openjfx-amd64.zip
echo "${OPENJFX_JMODS_AMD64_HASH}  openjfx-amd64.zip" | shasum -a256 --check
mkdir -p jmods/amd64
unzip -o -j openjfx-amd64.zip \*/javafx.base.jmod \*/javafx.controls.jmod \*/javafx.fxml.jmod \*/javafx.graphics.jmod -d jmods/amd64
curl -L $OPENJFX_JMODS_AARCH64 -o openjfx-aarch64.zip
echo "${OPENJFX_JMODS_AARCH64_HASH}  openjfx-aarch64.zip" | shasum -a256 --check
mkdir -p jmods/aarch64
unzip -o -j openjfx-aarch64.zip \*/javafx.base.jmod \*/javafx.controls.jmod \*/javafx.fxml.jmod \*/javafx.graphics.jmod -d jmods/aarch64

JMOD_VERSION_AMD64=$(jmod describe jmods/amd64/javafx.base.jmod | head -1)
JMOD_VERSION_AMD64=${JMOD_VERSION_AMD64#*@}
JMOD_VERSION_AMD64=${JMOD_VERSION_AMD64%%.*}
JMOD_VERSION_AARCH64=$(jmod describe jmods/aarch64/javafx.base.jmod | head -1)
JMOD_VERSION_AARCH64=${JMOD_VERSION_AARCH64#*@}
JMOD_VERSION_AARCH64=${JMOD_VERSION_AARCH64%%.*}

POM_JFX_VERSION=$(mvn help:evaluate "-Dexpression=javafx.version" -q -DforceStdout)
POM_JFX_VERSION=${POM_JFX_VERSION#*@}
POM_JFX_VERSION=${POM_JFX_VERSION%%.*}

if [ $POM_JFX_VERSION -ne $JMOD_VERSION_AMD64 ]; then
  >&2 echo "Major JavaFX version in pom.xml (${POM_JFX_VERSION}) != amd64 jmod version (${JMOD_VERSION_AMD64})"
  exit 1
fi

if [ $POM_JFX_VERSION -ne $JMOD_VERSION_AARCH64 ]; then
  >&2 echo "Major JavaFX version in pom.xml (${POM_JFX_VERSION}) != aarch64 jmod version (${JMOD_VERSION_AARCH64})"
  exit 1
fi
rm -rf cryptomator_*
mkdir pkgdir
cp -r target/libs pkgdir
cp -r target/mods pkgdir
cp -r jmods pkgdir
cp -r dist/linux/common/ pkgdir
cp target/cryptomator-*.jar pkgdir/mods
PPA=${SEM_VER_NUM}
tar -cJf cryptomator-crack_${PPA}.orig.tar.xz -C pkgdir .
echo "cryptomator-crack_${PPA}.orig.tar.xz 成功生成"

cp -r dist/linux/debian/ pkgdir
export RFC2822_TIMESTAMP=`date --rfc-2822`
export DISABLE_UPDATE_CHECK=0
export PPA_VERSION=`echo $PPA`
echo $PPA_VERSION
envsubst '${SEMVER_STR} ${VERSION_NUM} ${REVISION_NUM} ${DISABLE_UPDATE_CHECK}' < dist/linux/debian/rules > pkgdir/debian/rules
envsubst '${PPA_VERSION} ${RFC2822_TIMESTAMP}' < dist/linux/debian/changelog > pkgdir/debian/changelog
find . -name "*.jar" >> pkgdir/debian/source/include-binaries
mv pkgdir cryptomator-crack_${PPA}

cd cryptomator-crack_${PPA}
debuild -S -sa -d
debuild -b -sa -d

