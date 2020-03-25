*** Settings ***
Library           OperatingSystem
Library           Process
Variables         SailfishSDK.py
Library           SailfishSDK.py

*** Keywords ***
Clear Configuration
    Remove Directory    ${SDK CONFIG DIR}    recursive=True

File Should Exist Inside Build Engine
    [Arguments]    ${path}
    Run Sfdk    engine    exec    test    -f    ${path}

File Should Not Exist Inside Build Engine
    [Arguments]    ${path}
    Run Sfdk    engine    exec    test    !    -f    ${path}

Remove Package From Device
    [Arguments]    ${name}
    Run Sfdk    device    exec    bash    -c    ! rpm -q ${name} || sudo rpm -e ${name}

Package Should Be Installed On Device
    [Arguments]    ${name}
    Run Sfdk    device    exec    rpm    -q    ${name}

Package Should Not Be Installed On Device
    [Arguments]    ${name}
    Run Sfdk    device    exec    bash    -c    ! rpm -q ${name}

File Should Exist On Device
    [Arguments]    ${path}
    Run Sfdk    device    exec    test    -f    ${path}

File Should Not Exist On Device
    [Arguments]    ${path}
    Run Sfdk    device    exec    test    !    -f    ${path}

Directory Should Exist On Device
    [Arguments]    ${path}
    Run Sfdk    device    exec    test    -d    ${path}

Directory Should Not Exist On Device
    [Arguments]    ${path}
    Run Sfdk    device    exec    test    !    -d    ${path}
