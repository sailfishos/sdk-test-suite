#!/bin/bash
[[ $# -eq 0 ]] || { echo "Unexpected argument: '$1'"; exit 1; }
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
mkdir sdk-test-suite.out && cd sdk-test-suite.out
../sdk-test-suite/configure ../SailfishSDK-installer.run
xvfb-run --server-args="-screen 0 1024x768x24" robot --exclude interactive ../sdk-test-suite
# clean up
[[ -f ~/SailfishOS/SDKMaintenanceTool ]] && ~/SailfishOS/SDKMaintenanceTool --verbose non-interactive=1 --platform minimal
rm -Rf ~/SailfishOS
rm -Rf ~/.config/SailfishSDK
