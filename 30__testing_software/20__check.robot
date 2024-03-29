*** Settings ***
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Library           OperatingSystem
Library           ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
Basic Packaging
    Run Sfdk    build    cwd=harbour-foobar
    Run Sfdk    check   -s    harbour    RPMS/harbour-foobar-0-1.${DEVICE.arch}.rpm    cwd=harbour-foobar

Sailjail Good
    Append To Line In File    harbour-foobar/harbour-foobar.desktop    Permissions=    Audio;Videos;Compatibility
    Run Sfdk    build    cwd=harbour-foobar
    Run Sfdk    check    -s    harbour    RPMS/harbour-foobar-0-1.${DEVICE.arch}.rpm    cwd=harbour-foobar

Sailjail Bad
    Append To Line In File    harbour-foobar/harbour-foobar.desktop    Permissions=    Audio;Videos;Phone;Compatibility
    Run Sfdk    build    cwd=harbour-foobar
    Run Sfdk    check    -s    harbour    RPMS/harbour-foobar-0-1.${DEVICE.arch}.rpm    cwd=harbour-foobar    expected_rc=1

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    target\=${DEVICE.build_target}
    Create Directory    harbour-foobar
    Run Sfdk    init    -t    qtquick2app    cwd=harbour-foobar

Suite Teardown
    Vboxsf Safe Remove Directory    harbour-foobar    recursive=True    
    Clear Configuration
