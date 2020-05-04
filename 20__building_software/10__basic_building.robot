*** Settings ***
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Library           OperatingSystem
Library           ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
Basic Build
    [Setup]    In Tree Build Test Setup
    File Should Not Exist    foobar/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    Run Sfdk    build    cwd=foobar
    File Should Exist    foobar/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    [Teardown]    Test Teardown

Basic Build (Shadow)
    [Setup]    Shadow Build Test Setup
    File Should Not Exist    foobar/foobar-build/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    Run Sfdk    build    ../foobar    cwd=foobar/foobar-build
    File Should Exist    foobar/foobar-build/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    [Teardown]    Test Teardown

Separated Build Phases
    [Setup]    In Tree Build Test Setup
    File Should Not Exist    foobar/Makefile
    Run Sfdk    qmake    cwd=foobar
    File Should Exist    foobar/Makefile
    File Should Not Exist    foobar/foobar
    Run Sfdk    make    cwd=foobar
    File Should Exist    foobar/foobar
    File Should Not Exist Inside Build Engine    /home/deploy/installroot/usr/bin/foobar
    Run Sfdk    make-install    cwd=foobar
    File Should Exist Inside Build Engine    /home/deploy/installroot/usr/bin/foobar
    File Should Not Exist    foobar/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    Run Sfdk    package    cwd=foobar
    File Should Exist    foobar/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    [Teardown]    Test Teardown

Separated Build Phases (Shadow)
    [Setup]    Shadow Build Test Setup
    File Should Not Exist    foobar/foobar-build/Makefile
    Run Sfdk    qmake    ../foobar    cwd=foobar/foobar-build
    File Should Exist    foobar/foobar-build/Makefile
    File Should Not Exist    foobar/foobar-build/foobar
    Run Sfdk    make    cwd=foobar/foobar-build
    File Should Exist    foobar/foobar-build/foobar
    File Should Not Exist Inside Build Engine    /home/deploy/installroot/usr/bin/foobar
    Run Sfdk    make-install    cwd=foobar/foobar-build
    File Should Exist Inside Build Engine    /home/deploy/installroot/usr/bin/foobar
    File Should Not Exist    foobar/foobar-build/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    Run Sfdk    package    cwd=foobar/foobar-build
    File Should Exist    foobar/foobar-build/RPMS/foobar-0-1.${DEVICE.arch}.rpm
    [Teardown]    Test Teardown

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    target\=${DEVICE.build_target}

Suite Teardown
    Clear Configuration

In Tree Build Test Setup
    Create Directory    foobar
    Run Sfdk    init    -t    qtquick    cwd=foobar
    Clear RPM Install Directory Inside Build Engine

Shadow Build Test Setup
    Create Directory    foobar/foobar
    Create Directory    foobar/foobar-build
    Run Sfdk    init    -t    qtquick    cwd=foobar/foobar
    Clear RPM Install Directory Inside Build Engine

Test Teardown
    Vboxsf Safe Remove Directory    foobar    recursive=True

Clear RPM Install Directory Inside Build Engine
    Run Sfdk    engine    exec    rm    -rf    /home/deploy/installroot
