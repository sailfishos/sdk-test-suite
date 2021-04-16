*** Settings ***
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        Clean Up Device
Test Teardown     Clean Up Device
Force Tags        needs-device
Library           OperatingSystem
Library           ../SailfishSDK.py
Variables         ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
Method SDK
    [Tags]    interactive
    Package Should Not Be Installed On Device    foobar
    Package Should Not Be Installed On Device    foobar-debuginfo
    Package Should Not Be Installed On Device    foobar-debugsource
    # FIXME Configure device so that it does not ask
    Log To Console    \nPlease confirm installation on device!
    Run Sfdk    deploy    --sdk    cwd=foobar
    Package Should Be Installed On Device    foobar
    Package Should Not Be Installed On Device    foobar-debuginfo
    Package Should Not Be Installed On Device    foobar-debugsource

Method SDK, With Debug Info
    [Tags]    interactive
    Package Should Not Be Installed On Device    foobar
    Package Should Not Be Installed On Device    foobar-debuginfo
    Package Should Not Be Installed On Device    foobar-debugsource
    # FIXME Configure device so that it does not ask
    Log To Console    \nPlease confirm installation on device!
    Run Sfdk    deploy    --sdk    --debug    cwd=foobar
    Package Should Be Installed On Device    foobar
    Package Should Be Installed On Device    foobar-debuginfo
    Package Should Be Installed On Device    foobar-debugsource

Method SDK, Filtered
    [Tags]    interactive
    Package Should Not Be Installed On Device    foobar
    Package Should Not Be Installed On Device    foobar-debuginfo
    Package Should Not Be Installed On Device    foobar-debugsource
    # FIXME Configure device so that it does not ask
    Log To Console    \nPlease confirm installation on device!
    Run Sfdk    deploy    --sdk    --debug    --    +*-debugsource    -*-foobar    cwd=foobar
    Package Should Not Be Installed On Device    foobar
    Package Should Not Be Installed On Device    foobar-debuginfo
    Package Should Be Installed On Device    foobar-debugsource

Method Rsync
    Directory Should Not Exist On Device    /opt/sdk/foobar
    Run Sfdk    deploy    --rsync    cwd=foobar
    Directory Should Exist On Device    /opt/sdk/foobar

Method Manual
    Directory Should Not Exist On Device    /home/${DEVICE.user}/RPMS
    Run Sfdk    deploy    --manual    cwd=foobar
    Directory Should Exist On Device    /home/${DEVICE.user}/RPMS
    File Should Exist On Device    /home/${DEVICE.user}/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    File Should Not Exist On Device    /home/${DEVICE.user}/RPMS/foobar-debuginfo-0-1.${DEVICE.arch}.rpm
    File Should Not Exist On Device    /home/${DEVICE.user}/RPMS/foobar-debugsource-0-1.${DEVICE.arch}.rpm

Method Manual, With Debug Info
    Directory Should Not Exist On Device    /home/${DEVICE.user}/RPMS
    Run Sfdk    deploy    --manual    --debug    cwd=foobar
    Directory Should Exist On Device    /home/${DEVICE.user}/RPMS
    File Should Exist On Device    /home/${DEVICE.user}/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    File Should Exist On Device    /home/${DEVICE.user}/RPMS/foobar-debuginfo-0-1.${DEVICE.arch}.rpm
    File Should Exist On Device    /home/${DEVICE.user}/RPMS/foobar-debugsource-0-1.${DEVICE.arch}.rpm

Method Manual, Filtered
    Directory Should Not Exist On Device    /home/${DEVICE.user}/RPMS
    Run Sfdk    deploy    --manual    --debug    --    +*-debugsource    -*-foobar    cwd=foobar
    Directory Should Exist On Device    /home/${DEVICE.user}/RPMS
    File Should Not Exist On Device    /home/${DEVICE.user}/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    File Should Not Exist On Device    /home/${DEVICE.user}/RPMS/foobar-debuginfo-0-1.${DEVICE.arch}.rpm
    File Should Exist On Device    /home/${DEVICE.user}/RPMS/foobar-debugsource-0-1.${DEVICE.arch}.rpm

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    target\=${DEVICE.build_target}
    Run Sfdk    config    --global    device\=${DEVICE.name}
    Create Directory    foobar
    Run Sfdk    init    -t    qtquick    cwd=foobar
    Run Sfdk    build    --enable-debug    --    --noclean    cwd=foobar

Suite Teardown
    Vboxsf Safe Remove Directory    foobar    recursive=True
    Clear Configuration

Clean Up Device
    Remove Package From Device    foobar
    Remove Package From Device    foobar-debuginfo
    Remove Package From Device    foobar-debugsource
    Remove Directory From Device    /opt/sdk/foobar    recursive=True
    Remove Directory From Device    /home/${DEVICE.user}/RPMS    recursive=True
