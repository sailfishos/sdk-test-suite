*** Settings ***
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Library           OperatingSystem
Library           ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
Basic Build
    [Template]    Basic Build Template
    qtquick2app    qmake    ${DEVICE.arch}
    qtquick2app    cmake    ${DEVICE.arch}
    qtquick2app-qmlonly    qmake    noarch

Basic Build (Shadow)
    [Template]    Basic Build (Shadow) Template
    qtquick2app    qmake    ${DEVICE.arch}
    qtquick2app    cmake    ${DEVICE.arch}
    qtquick2app-qmlonly    qmake    noarch

Separated Build Phases
    [Template]    Separated Build Phases Template
    qtquick2app    qmake    ${DEVICE.arch}    ${True}
    qtquick2app    cmake    ${DEVICE.arch}    ${True}
    qtquick2app-qmlonly    qmake    noarch    ${False}

Separated Build Phases (Shadow)
    [Template]    Separated Build Phases (Shadow) Template
    qtquick2app    qmake    ${DEVICE.arch}    ${True}
    qtquick2app    cmake    ${DEVICE.arch}    ${True}
    qtquick2app-qmlonly    qmake    noarch    ${False}

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    target\=${DEVICE.build_target}

Suite Teardown
    Clear Configuration

In Tree Build Test Setup
    Create Directory    foobar
    Clear RPM Install Directory Inside Build Engine

Shadow Build Test Setup
    Create Directory    foobar/foobar
    Create Directory    foobar/foobar-build
    Clear RPM Install Directory Inside Build Engine

Basic Build Template
    [Arguments]    ${type}    ${builder}    ${expected_arch}
    In Tree Build Test Setup
    Run Sfdk    init    -t    ${type}    -b    ${builder}    cwd=foobar
    File Should Not Exist    foobar/RPMS/foobar-0-1.${expected_arch}.rpm
    Run Sfdk    build    cwd=foobar
    File Should Exist    foobar/RPMS/foobar-0-1.${expected_arch}.rpm
    [Teardown]    Test Teardown

Basic Build (Shadow) Template
    [Arguments]    ${type}    ${builder}    ${expected_arch}
    Shadow Build Test Setup
    Run Sfdk    init    -t    ${type}    -b    ${builder}    cwd=foobar/foobar
    File Should Not Exist    foobar/foobar-build/RPMS/foobar-0-1.${expected_arch}.rpm
    Run Sfdk    build    ../foobar    cwd=foobar/foobar-build
    File Should Exist    foobar/foobar-build/RPMS/foobar-0-1.${expected_arch}.rpm
    [Teardown]    Test Teardown

Separated Build Phases Template
    [Arguments]    ${type}    ${builder}    ${expected_arch}    ${creates_binary}
    In Tree Build Test Setup
    Run Sfdk    init    -t    ${type}    -b    ${builder}    cwd=foobar
    File Should Not Exist    foobar/Makefile
    Run Sfdk    ${builder}    cwd=foobar
    File Should Exist    foobar/Makefile
    File Should Not Exist    foobar/foobar
    Run Sfdk    make    cwd=foobar
    IF    ${creates_binary}
        File Should Exist    foobar/foobar
    END
    File Should Not Exist Inside Build Engine    /home/deploy/installroot/usr/bin/foobar
    Run Sfdk    make-install    cwd=foobar
    IF    ${creates_binary}
        File Should Exist Inside Build Engine    /home/deploy/installroot/usr/bin/foobar
    END
    File Should Not Exist    foobar/RPMS/foobar-0-1.${expected_arch}.rpm
    Run Sfdk    package    cwd=foobar
    File Should Exist    foobar/RPMS/foobar-0-1.${expected_arch}.rpm
    [Teardown]    Test Teardown

Separated Build Phases (Shadow) Template
    [Arguments]    ${type}    ${builder}    ${expected_arch}    ${creates_binary}
    Shadow Build Test Setup
    Run Sfdk    init    -t    ${type}    -b    ${builder}    cwd=foobar/foobar
    File Should Not Exist    foobar/foobar-build/Makefile
    Run Sfdk    ${builder}    ../foobar    cwd=foobar/foobar-build
    File Should Exist    foobar/foobar-build/Makefile
    File Should Not Exist    foobar/foobar-build/foobar
    Run Sfdk    make    cwd=foobar/foobar-build
    IF    ${creates_binary}
        File Should Exist    foobar/foobar-build/foobar
    END
    File Should Not Exist Inside Build Engine    /home/deploy/installroot/usr/bin/foobar
    Run Sfdk    make-install    cwd=foobar/foobar-build
    IF    ${creates_binary}
        File Should Exist Inside Build Engine    /home/deploy/installroot/usr/bin/foobar
    END
    File Should Not Exist    foobar/foobar-build/RPMS/foobar-0-1.${expected_arch}.rpm
    Run Sfdk    package    cwd=foobar/foobar-build
    File Should Exist    foobar/foobar-build/RPMS/foobar-0-1.${expected_arch}.rpm
    [Teardown]    Test Teardown

Test Teardown
    Vboxsf Safe Remove Directory    foobar    recursive=True

Clear RPM Install Directory Inside Build Engine
    Run Sfdk    engine    exec    rm    -rf    /home/deploy/installroot
