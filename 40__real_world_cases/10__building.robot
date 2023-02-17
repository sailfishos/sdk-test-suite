*** Settings ***
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Library           OperatingSystem
Library           Process
Library           ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
Build Passes
    [Template]    Build Package
    harbour-storeman     devel
    osmscout-sailfish    master

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    target\=${DEVICE.build_target}

Suite Teardown
    Clear Configuration

Build Package
    [Arguments]    ${name}    ${branch}
    Run Process    git    clone    --branch    ${branch}    --recurse-submodules    ${CURDIR}/packages/${name}    ${name}
    Run Sfdk    build    cwd=${name}
    [Teardown]    Remove Directory    ${name}    recursive=True
