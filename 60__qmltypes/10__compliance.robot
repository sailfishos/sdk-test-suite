*** Settings ***
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Force Tags        needs-device
Library           OperatingSystem
Library           Process
Library           ../SailfishSDK.py
Variables         ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
QML Type Info Matches The Latest API
    ${PROJECTS_DIR} =    Normalize Path   ~/prj
    Run Sfdk    qmltypes    --batch    --csv     ${CURDIR}/qmltypes.csv    ${PROJECTS_DIR}    cwd=qmltypes.tmp
    ${result} =     Run Sfdk    qmltypes    --batch    --csv     ${CURDIR}/qmltypes.csv    ${PROJECTS_DIR}
    ...                         --status    cwd=qmltypes.tmp
    Should Not Match Regexp    ${result.stdout}    ^(TODO|PROG|FAIL)    flags=MULTILINE
    Should Not Contain    ${result.stdout}    diff --git

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    target\=${DEVICE.build_target}
    Run Sfdk    config    --global    device\=${DEVICE.name}
    Run Sfdk    engine    exec    sudo    zypper    in    -y    python3-pip
    Run Sfdk    engine    exec    pip3    install    --user    git-url-parse
    # Getting the known_hosts file populated is the main objective here
    Run Sfdk    engine    exec    cp    -a   /host_home/.ssh    /home/mersdk/
    # Workaround for bug in git https://bugs.launchpad.net/ubuntu/+source/git/+bug/1993586
    Run Sfdk    engine    exec    git    config    --global    protocol.file.allow    always
    Create Directory    qmltypes.tmp
    # sfdk-qmltypes would not dare to proceed if the emulator happened to be running
    Run Sfdk    emulator    stop

Suite Teardown
    Remove Directory    qmltypes.tmp    recursive=True
    Clear Configuration
