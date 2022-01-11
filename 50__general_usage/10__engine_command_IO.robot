*** Settings ***
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Library           Collections
Library           OperatingSystem
Library           ../SailfishSDK.py
Resource          ../SailfishSDK.robot

*** Test Cases ***
Pseudo-Terminal Allocation For Engine Shell
    [Template]    Run Engine Shell And Check Pseudo-Terminal Allocation
    False    ${EMPTY}    False
    False    -t          False
    False    -tt         True
    True     ${EMPTY}    True
    True     -t          True
    True     -tt         True

Pseudo-Terminal Allocation For Engine Command
    [Template]    Run Engine Command And Check Pseudo-Terminal Allocation
    False    ${EMPTY}    False
    False    -t          False
    False    -tt         True
    True     ${EMPTY}    False
    True     -t          True
    True     -tt         True

Pseudo-Terminal Allocation For Engine Command With Redirection Under TTY
    [Template]    Run Engine Command With Redirection Under TTY And Check Pseudo-Terminal Allocation
    </dev/null      ${EMPTY}  False
    </dev/null      -t        False
    </dev/null      -tt       True
    >/dev/null      ${EMPTY}  False
    >/dev/null      -t        False
    >/dev/null      -tt       True
    2>/dev/null     ${EMPTY}  False
    2>/dev/null     -t        False
    2>/dev/null     -tt       True

Pseudo-Terminal Allocation For Built-In Engine Command
    [Template]     Run Built-In Engine Command And Check Pseudo-Terminal Allocation
    False    False
    True     True
    
Pseudo-Terminal Allocation For Built-In Engine Command With Redirection Under TTY
    [Template]     Run Built-In Engine Command With Redirection Under TTY And Check Pseudo-Terminal Allocation
    </dev/null      False
    >/dev/null      False
    2>/dev/null     False

Input Redirection For Engine Command
    ${result} =    Run Sfdk    engine    exec    bash    -c    tr a-z A-Z
    ...                        tty=True    redirection=<<<xx-input    input=xx-user-input\n
    Should Not Contain    ${result.stdout}    XX-USER-INPUT
    Should Contain    ${result.stdout}    XX-INPUT

Output Redirection For Engine Command
    ${result} =    Run Sfdk    engine    exec    bash    -c    echo xx-out |tr a-z A-Z; echo xx-err |tr a-z A-Z >&2
    ...                        tty=True    redirection=>/dev/null
    Should Not Contain    ${result.stdout}    XX-OUT
    Should Contain    ${result.stdout}    XX-ERR

Input Redirection For Built-In Engine Command
    ${result} =    Run Sfdk    build-shell    bash    -c    tr a-z A-Z
    ...                        tty=True    redirection=<<<xx-input    input=xx-user-input\n
    Should Not Contain    ${result.stdout}    XX-USER-INPUT
    Should Contain    ${result.stdout}    XX-INPUT

Output Redirection For Built-In Engine Command
    ${result} =    Run Sfdk    build-shell    bash    -c    echo xx-out |tr a-z A-Z; echo xx-err |tr a-z A-Z >&2
    ...                        tty=True    redirection=>/dev/null
    Should Not Contain    ${result.stdout}    XX-OUT
    Should Contain    ${result.stdout}    XX-ERR

Piping Binary Data Through Engine Command
    ${input} =    Evaluate    bytes(range(256))
    ${result} =    Run Sfdk    engine    exec    bash    -c    cat    input=${input}    merged_output=False
    ${output} =    Get Binary File    ${result.stdout_path}
    Should Be Equal    ${input}    ${output}
    
Piping Binary Data Through Built-In Engine Command
    ${input} =    Evaluate    bytes(range(256))
    ${result} =    Run Sfdk    build-shell    bash    -c    cat    input=${input}    merged_output=False
    ${output} =    Get Binary File    ${result.stdout_path}
    Should Be Equal    ${input}    ${output}
    
*** Keywords ***
Run Engine Shell And Check Pseudo-Terminal Allocation
    [Arguments]    ${local_tty}    ${t_option}    ${pty_expected}
    @{options} =    Run Keyword If    '${t_option}'    Create List    ${t_option}
    ${expected_rc} =    Set Variable If    ${pty_expected}    0    1
    Run Keyword    Run Sfdk    engine    exec    @{options}    input=tty\nexit\n    tty=${local_tty}    expected_rc=${expected_rc}

Run Engine Command And Check Pseudo-Terminal Allocation
    [Arguments]    ${local_tty}    ${t_option}    ${pty_expected}
    @{options} =    Run Keyword If    '${t_option}'    Create List    ${t_option}
    ${expected_rc} =    Set Variable If    ${pty_expected}    0    1
    Run Keyword    Run Sfdk    engine    exec    @{options}    tty    tty=${local_tty}    expected_rc=${expected_rc}

Run Engine Command With Redirection Under TTY And Check Pseudo-Terminal Allocation
    [Arguments]    ${redirection}    ${t_option}    ${pty_expected}
    @{options} =    Run Keyword If    '${t_option}'    Create List    ${t_option}
    ${expected_rc} =    Set Variable If    ${pty_expected}    0    1
    Run Keyword    Run Sfdk    engine    exec    @{options}    tty    tty=True    redirection=${redirection}    expected_rc=${expected_rc}

Run Built-In Engine Command And Check Pseudo-Terminal Allocation
    [Arguments]    ${local_tty}    ${pty_expected}
    ${expected_rc} =    Set Variable If    ${pty_expected}    0    1
    Run Keyword    Run Sfdk    build-shell    tty    tty=${local_tty}    expected_rc=${expected_rc}

Run Built-In Engine Command With Redirection Under TTY And Check Pseudo-Terminal Allocation
    [Arguments]    ${redirection}    ${pty_expected}
    ${expected_rc} =    Set Variable If    ${pty_expected}    0    1
    Run Keyword    Run Sfdk    build-shell    tty    tty=True    redirection=${redirection}    expected_rc=${expected_rc}

*** Keywords ***
Suite Setup
    Clear Configuration
    Run Sfdk    config    --global    target\=${DEVICE.build_target}
    Run Sfdk    build-init

Suite Teardown
    Clear Configuration
