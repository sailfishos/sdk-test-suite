*** Settings ***
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Library           Collections
Library           OperatingSystem
Library           ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
Pseudo-Terminal Allocation For Device Shell
    [Template]    Run Device Shell And Check Pseudo-Terminal Allocation
    False    ${EMPTY}    False
    False    -t          False
    False    -tt         True
    True     ${EMPTY}    True
    True     -t          True
    True     -tt         True

Pseudo-Terminal Allocation For Device Command
    [Template]    Run Device Command And Check Pseudo-Terminal Allocation
    False    ${EMPTY}    False
    False    -t          False
    False    -tt         True
    True     ${EMPTY}    False
    True     -t          True
    True     -tt         True

Pseudo-Terminal Allocation For Device Command With Redirection Under TTY
    [Template]    Run Device Command With Redirection Under TTY And Check Pseudo-Terminal Allocation
    </dev/null      ${EMPTY}  False
    </dev/null      -t        False
    </dev/null      -tt       True
    >/dev/null      ${EMPTY}  False
    >/dev/null      -t        False
    >/dev/null      -tt       True
    2>/dev/null     ${EMPTY}  False
    2>/dev/null     -t        False
    2>/dev/null     -tt       True

Input Redirection For Device Command
    ${result} =    Run Sfdk    device    exec    bash    -c    tr a-z A-Z
    ...                        tty=True    redirection=<<<xx-input    input=xx-user-input\n
    Should Not Contain    ${result.stdout}    XX-USER-INPUT
    Should Contain    ${result.stdout}    XX-INPUT

Output Redirection For Device Command
    ${result} =    Run Sfdk    device    exec    bash    -c    echo xx-out |tr a-z A-Z; echo xx-err |tr a-z A-Z >&2
    ...                        tty=True    redirection=>/dev/null
    Should Not Contain    ${result.stdout}    XX-OUT
    Should Contain    ${result.stdout}    XX-ERR

Pipe Binary Data Through Device Command
    ${input} =    Evaluate    bytes(range(256))
    ${result} =    Run Sfdk    device    exec    bash    -c    cat    input=${input}    merged_output=False
    ${output} =    Get Binary File    ${result.stdout_path}
    Should Be Equal    ${input}    ${output}

*** Keywords ***
Run Device Shell And Check Pseudo-Terminal Allocation
    [Arguments]    ${local_tty}    ${t_option}    ${pty_expected}
    @{options} =    Run Keyword If    '${t_option}'    Create List    ${t_option}
    ${expected_rc} =    Set Variable If    ${pty_expected}    0    1
    Run Keyword    Run Sfdk    device    exec    @{options}    input=tty\nexit\n    tty=${local_tty}    expected_rc=${expected_rc}

Run Device Command And Check Pseudo-Terminal Allocation
    [Arguments]    ${local_tty}    ${t_option}    ${pty_expected}
    @{options} =    Run Keyword If    '${t_option}'    Create List    ${t_option}
    ${expected_rc} =    Set Variable If    ${pty_expected}    0    1
    Run Keyword    Run Sfdk    device    exec    @{options}    tty    tty=${local_tty}    expected_rc=${expected_rc}

Run Device Command With Redirection Under TTY And Check Pseudo-Terminal Allocation
    [Arguments]    ${redirection}    ${t_option}    ${pty_expected}
    @{options} =    Run Keyword If    '${t_option}'    Create List    ${t_option}
    ${expected_rc} =    Set Variable If    ${pty_expected}    0    1
    Run Keyword    Run Sfdk    device    exec    @{options}    tty    tty=True    redirection=${redirection}    expected_rc=${expected_rc}

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    device\=${DEVICE.name}

Suite Teardown
    Clear Configuration
