*** Settings ***
Suite Setup       Maybe Install SDK
Suite Teardown    Maybe Uninstall SDK
Variables         ../SailfishSDK.py
Library           ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
Remove And Re-add Latest Build Targets
    [Template]    Remove And Re-add Build Target
    ${OS VARIANT.nospace}-${OS VERSION.latest}-armv7hl
    ${OS VARIANT.nospace}-${OS VERSION.latest}-i486

Add And Remove Other Build Targets
    [Template]    Add And Remove Build Target
    ${OS VARIANT.nospace}-${OS VERSION.ea}EA-armv7hl
    ${OS VARIANT.nospace}-${OS VERSION.ea}EA-i486
    ${OS VARIANT.nospace}-${OS VERSION.oldest}-armv7hl
    ${OS VARIANT.nospace}-${OS VERSION.oldest}-i486

Remove And Re-add Latest Emulator
    [Template]    Remove And Re-add Emulator
    ${OS VARIANT.nospace}-${OS VERSION.latest}

Add And Remove Other Emulators
    [Template]    Add And Remove Emulator
    ${OS VARIANT.nospace}-${OS VERSION.oldest}

*** Keywords ***
Should Have Build Target Available
    [Arguments]    ${name}
    ${result} =    Run Sfdk    tools    target    list    --available
    Should Match Regexp    ${result.stdout}    ${name} +

Should Have Build Target Installed
    [Arguments]    ${name}
    ${result} =    Run Sfdk    tools    target    list    --available
    Should Match Regexp    ${result.stdout}    ${name} +installed

Should Not Have Build Target Installed
    [Arguments]    ${name}
    ${result} =    Run Sfdk    tools    target    list    --available
    Should Not Match Regexp    ${result.stdout}    ${name} +installed

Should Have Emulator Available
    [Arguments]    ${name}
    ${result} =    Run Sfdk    emulator    list    --available
    Should Match Regexp    ${result.stdout}    ${name} +

Should Have Emulator Installed
    [Arguments]    ${name}
    ${result} =    Run Sfdk    emulator    list    --available
    Should Match Regexp    ${result.stdout}    ${name} +installed

Should Not Have Emulator Installed
    [Arguments]    ${name}
    ${result} =    Run Sfdk    emulator    list    --available
    Should Not Match Regexp    ${result.stdout}    ${name} +installed

Remove And Re-add Build Target
    [Arguments]    ${name}
    Should Have Build Target Installed    ${name}
    Run Sfdk    tools    target    remove    ${name}
    Should Not Have Build Target Installed    ${name}
    Run Sfdk    tools    target    install    ${name}
    Should Have Build Target Installed    ${name}

Add And Remove Build Target
    [Arguments]    ${name}
    Should Have Build Target Available    ${name}
    Should Not Have Build Target Installed    ${name}
    Run Sfdk    tools    target    install    ${name}
    Should Have Build Target Installed    ${name}
    Run Sfdk    tools    target    remove    ${name}
    Should Not Have Build Target Installed    ${name}

Remove And Re-add Emulator
    [Arguments]    ${name}
    Should Have Emulator Installed    ${name}
    Run Sfdk    emulator    remove    ${name}
    Should Not Have Emulator Installed    ${name}
    Run Sfdk    emulator    install    ${name}
    Should Have Emulator Installed    ${name}

Add And Remove Emulator
    [Arguments]    ${name}
    Should Have Emulator Available    ${name}
    Should Not Have Emulator Installed    ${name}
    Run Sfdk    emulator    install    ${name}
    Should Have Emulator Installed    ${name}
    Run Sfdk    emulator    remove    ${name}
    Should Not Have Emulator Installed    ${name}
