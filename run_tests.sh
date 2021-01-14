#!/bin/bash
SDK_BUILD=$1
BUILDDATE=$(ls ~/installers/repository*|sed -e 's/.*[-]\([0-9]*\).*/\1/')
7z x ~/installers/repository-$BUILDDATE.7z
ln -sfT ~/targets targets
ln -sfT ~/emulators emulators
mkdir -p $WORKSPACE_TMP
installer=$HOME/installers/SailfishSDK-linux-64-offline-$BUILDDATE.run
repo=$WORKSPACE/repository-$BUILDDATE
chmod +x $installer
cat > SailfishSDK-installer.run << EOF
#!/bin/bash
export TMPDIR=$WORKSPACE_TMP
exec "$installer" --verbose non-interactive=1 accept-licenses=1 --platform minimal --addRepository "file://$repo/common/,file://$repo/linux-64" "\$@"
EOF
chmod +x SailfishSDK-installer.run
sed -i "s/SDK_VERSION = .*/SDK_VERSION = \"$SDK_BUILD\"/g" sdk-test-suite/config.py
LATEST_SFOS=$(ls -tr ~/emulators/|tail -n 1|sed 's/.*[-]\([0-9.]*\)[-].*/\1/')
echo LATEST_SFOS=$LATEST_SFOS
sed -i "s/^OS_VERSION = .*/OS_VERSION = {\"ea\": \"$LATEST_SFOS\",/g" sdk-test-suite/config.py
sed -i "s/\"latest\": .*/\"latest\": \"$LATEST_SFOS\",/g" sdk-test-suite/config.py
mkdir sdk-test-suite.out && cd sdk-test-suite.out
xvfb-run --server-args="-screen 0 1024x768x24" robot ../sdk-test-suite
# clean up
[[ -f ~/SailfishOS/SDKMaintenanceTool ]] && ~/SailfishOS/SDKMaintenanceTool --verbose non-interactive=1 --platform minimal
rm -Rf ~/SailfishOS
rm -Rf ~/.config/SailfishSDK
