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
    harbour-storeman     90fcf9a
    osmscout-sailfish    7b5d03a

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    target\=${DEVICE.build_target}

Suite Teardown
    Clear Configuration

Build Package
    [Arguments]    ${name}    ${commit}
    Run Process    git    clone    ${CURDIR}/packages/${name}    ${name}
    Run Process    git    -C    ${name}    checkout    ${commit}
    Run Process    git    -C    ${name}    submodule    update    --init    --recursive
    Run Sfdk    build    cwd=${name}
    [Teardown]    Remove Directory    ${name}    recursive=True
