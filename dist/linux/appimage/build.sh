#!/bin/bash
set -e

cd $(dirname $0)
REVISION_NO=`git rev-list --count HEAD`

# check preconditions
if [ -z "${JAVA_HOME}" ]; then echo "JAVA_HOME not set. Run using JAVA_HOME=/path/to/jdk ./build.sh"; exit 1; fi
command -v mvn >/dev/null 2>&1 || { echo >&2 "mvn not found."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "curl not found."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip not found."; exit 1; }

VERSION=$(mvn -f ../../../pom.xml help:evaluate -Dexpression=project.version -q -DforceStdout)
SEMVER_STR=${VERSION}
CPU_ARCH=$(uname -p)

if [[ ! "${CPU_ARCH}" =~ x86_64|aarch64 ]]; then echo "Platform ${CPU_ARCH} not supported"; exit 1; fi

mvn -f ../../../pom.xml versions:set -DnewVersion=${SEMVER_STR}

# compile
mvn -f ../../../pom.xml clean package -Plinux -DskipTests -Djavafx.platform=linux
cp ../../../LICENSE.txt ../../../target
cp ../../../target/cryptomator-*.jar ../../../target/mods

JAVAFX_VERSION=23
JAVAFX_ARCH="x64"
JAVAFX_JMODS_SHA256='72a2390a117e024d1a897cbe216c7c99cb464519f488ae3701186cef5ab5a116'
if [ "${CPU_ARCH}" = "aarch64" ]; then
    JAVAFX_ARCH="aarch64"
    JAVAFX_JMODS_SHA256='dda2719d7dcac1ac3e33d853974e7baf5b55b7d5ea2a37a0162d25b8b32d0e36'
fi

# download javaFX jmods
JAVAFX_JMODS_URL="https://download2.gluonhq.com/openjfx/${JAVAFX_VERSION}/openjfx-${JAVAFX_VERSION}_linux-${JAVAFX_ARCH}_bin-jmods.zip"


curl -L ${JAVAFX_JMODS_URL} -o openjfx-jmods.zip
echo "${JAVAFX_JMODS_SHA256}  openjfx-jmods.zip" | shasum -a256 --check
mkdir -p openjfx-jmods
unzip -o -j openjfx-jmods.zip \*/javafx.base.jmod \*/javafx.controls.jmod \*/javafx.fxml.jmod \*/javafx.graphics.jmod -d openjfx-jmods
JMOD_VERSION=$(jmod describe ./openjfx-jmods/javafx.base.jmod | head -1)
JMOD_VERSION=${JMOD_VERSION#*@}
JMOD_VERSION=${JMOD_VERSION%%.*}
POM_JFX_VERSION=$(mvn help:evaluate "-Dexpression=javafx.version" -q -DforceStdout -B -f ../../../pom.xml)
POM_JFX_VERSION=${POM_JFX_VERSION#*@}
POM_JFX_VERSION=${POM_JFX_VERSION%%.*}
if [ $POM_JFX_VERSION -ne $JMOD_VERSION ]; then
	>&2 echo "Major JavaFX version in pom.xml (${POM_JFX_VERSION}) != amd64 jmod version (${JMOD_VERSION})"
	exit 1
fi


# add runtime
${JAVA_HOME}/bin/jlink \
    --verbose \
    --output runtime \
    --module-path "${JAVA_HOME}/jmods:openjfx-jmods" \
    --add-modules java.base,java.desktop,java.instrument,java.logging,java.naming,java.net.http,java.scripting,java.sql,java.xml,javafx.base,javafx.graphics,javafx.controls,javafx.fxml,jdk.unsupported,jdk.security.auth,jdk.accessibility,jdk.management.jfr,jdk.net,java.compiler \
    --strip-native-commands \
    --no-header-files \
    --no-man-pages \
    --strip-debug \
    --compress zip-0

# create app dir
${JAVA_HOME}/bin/jpackage \
    --verbose \
    --type app-image \
    --runtime-image runtime \
    --input ../../../target/libs \
    --module-path ../../../target/mods \
    --module org.cryptomator.desktop/org.cryptomator.launcher.Cryptomator \
    --dest appdir \
    --name Cryptomator-crack \
    --vendor "SuGotLand" \
    --java-options "--enable-preview" \
    --java-options "--enable-native-access=org.cryptomator.jfuse.linux.amd64,org.cryptomator.jfuse.linux.aarch64,org.purejava.appindicator" \
    --copyright "(C) SuGotLand sugotland@outlook.com" \
    --java-options "-Xss5m" \
    --java-options "-Xmx256m" \
    --app-version "${VERSION}.${REVISION_NO}" \
    --java-options "-Dfile.encoding=\"utf-8\"" \
    --java-options "-Djava.net.useSystemProxies=true" \
    --java-options "-Dcryptomator.logDir=\"@{userhome}/.local/share/Cryptomator-crack/logs\"" \
    --java-options "-Dcryptomator.pluginDir=\"@{userhome}/.local/share/Cryptomator-crack/plugins\"" \
    --java-options "-Dcryptomator.settingsPath=\"@{userhome}/.config/Cryptomator-crack/settings.json:@{userhome}/.Cryptomator-crack/settings.json\"" \
    --java-options "-Dcryptomator.p12Path=\"@{userhome}/.config/Cryptomator-crack/key.p12\"" \
    --java-options "-Dcryptomator.ipcSocketPath=\"@{userhome}/.config/Cryptomator-crack/ipc.socket\"" \
    --java-options "-Dcryptomator.mountPointsDir=\"@{userhome}/.local/share/Cryptomator-crack/mnt\"" \
    --java-options "-Dcryptomator.showTrayIcon=true" \
    --java-options "-Dcryptomator.integrationsLinux.trayIconsDir=\"@{appdir}/usr/share/icons/hicolor/symbolic/apps\"" \
    --java-options "-Dcryptomator.buildNumber=\"appimage-${REVISION_NO}\"" \
    --resource-dir ../resources

# transform AppDir
mv appdir/Cryptomator-crack Cryptomator-crack.AppDir
cp -r resources/AppDir/* Cryptomator-crack.AppDir/
envsubst '${REVISION_NO}' < resources/AppDir/bin/cryptomator-crack.sh > Cryptomator-crack.AppDir/bin/cryptomator-crack.sh
cp ../common/org.cryptomator.Cryptomator-crack256.png Cryptomator-crack.AppDir/usr/share/icons/hicolor/256x256/apps/org.cryptomator.Cryptomator-crack.png
cp ../common/org.cryptomator.Cryptomator-crack512.png Cryptomator-crack.AppDir/usr/share/icons/hicolor/512x512/apps/org.cryptomator.Cryptomator-crack.png
cp ../common/org.cryptomator.Cryptomator-crack.svg Cryptomator-crack.AppDir/usr/share/icons/hicolor/scalable/apps/org.cryptomator.Cryptomator-crack.svg
cp ../common/org.cryptomator.Cryptomator-crack.tray.svg Cryptomator-crack.AppDir/usr/share/icons/hicolor/scalable/apps/org.cryptomator.Cryptomator-crack.tray.svg
cp ../common/org.cryptomator.Cryptomator-crack.tray-unlocked.svg Cryptomator-crack.AppDir/usr/share/icons/hicolor/scalable/apps/org.cryptomator.Cryptomator-crack.tray-unlocked.svg
cp ../common/org.cryptomator.Cryptomator-crack.tray.svg Cryptomator-crack.AppDir/usr/share/icons/hicolor/symbolic/apps/org.cryptomator.Cryptomator-crack.tray-symbolic.svg
cp ../common/org.cryptomator.Cryptomator-crack.tray-unlocked.svg Cryptomator-crack.AppDir/usr/share/icons/hicolor/symbolic/apps/org.cryptomator.Cryptomator-crack.tray-unlocked-symbolic.svg
cp ../common/org.cryptomator.Cryptomator-crack.desktop Cryptomator-crack.AppDir/usr/share/applications/org.cryptomator.Cryptomator-crack.desktop
cp ../common/org.cryptomator.Cryptomator-crack.metainfo.xml Cryptomator-crack.AppDir/usr/share/metainfo/org.cryptomator.Cryptomator-crack.metainfo.xml
cp ../common/application-vnd.cryptomator-crack.vault.xml Cryptomator-crack.AppDir/usr/share/mime/packages/application-vnd.cryptomator-crack.vault.xml
ln -s usr/share/icons/hicolor/scalable/apps/org.cryptomator.Cryptomator-crack.svg Cryptomator-crack.AppDir/org.cryptomator.Cryptomator-crack.svg
ln -s usr/share/icons/hicolor/scalable/apps/org.cryptomator.Cryptomator-crack.svg Cryptomator-crack.AppDir/Cryptomator-crack.svg
ln -s usr/share/icons/hicolor/scalable/apps/org.cryptomator.Cryptomator-crack.svg Cryptomator-crack.AppDir/.DirIcon
ln -s usr/share/applications/org.cryptomator.Cryptomator-crack.desktop Cryptomator-crack.AppDir/Cryptomator-crack.desktop
ln -s bin/cryptomator-crack.sh Cryptomator-crack.AppDir/AppRun

# load AppImageTool
curl -L https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-${CPU_ARCH}.AppImage -o /tmp/appimagetool.AppImage
chmod +x /tmp/appimagetool.AppImage

# create AppImage
/tmp/appimagetool.AppImage \
    Cryptomator-crack.AppDir \
    cryptomator-crack-${SEMVER_STR}-${CPU_ARCH}.AppImage  \
    -u 'gh-releases-zsync|SuGotLand|Cryptomator-crack|latest|cryptomator-crack-*-${CPU_ARCH}.AppImage.zsync'

echo ""
echo "Done. AppImage successfully created: cryptomator-crack-${SEMVER_STR}-${CPU_ARCH}.AppImage"
echo ""
echo >&2 "To clean up, run: rm -rf Cryptomator-crack.AppDir appdir runtime squashfs-root openjfx-jmods; rm /tmp/appimagetool.AppImage openjfx-jmods.zip"
echo ""
