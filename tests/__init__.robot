*** Settings ***
Library           SSHLibrary
Library           DateTime

*** Variables ***
${SSH_KEYFILE}    %{HOME}/.ssh/id_ecdsa
${NODE_ADDR}      127.0.0.1
${MID}            mail0
${IMAGE_URL}      ghcr.io/nethserver/mail:latest

*** Keywords ***
Connect to the node
    Open Connection   ${NODE_ADDR}
    Login With Public Key    root    ${SSH_KEYFILE}

Wait until boot completes
    ${output} =    Execute Command    systemctl is-system-running  --wait
    Should Be True    '${output}' == 'running' or '${output}' == 'degraded'

Save the journal begin timestamp
    ${tsnow} =    Get Current Date    result_format=epoch
    Set Global Variable    ${JOURNAL_SINCE}    ${tsnow}

Collect the suite journal
    Execute Command    journalctl -S @${JOURNAL_SINCE} >journal-dump.log
    Get File    journal-dump.log    ${OUTPUT DIR}/journal-${SUITE NAME}.log

Disable offending units
    Execute Command    [ -x /etc/init.d/exim4 ] && /etc/init.d/exim4 stop
    ...    return_stdout=True
    ...    return_stderr=True
    ...    return_rc=True

*** Settings ***
Suite Setup       Run Keywords
                  ...    Connect to the Node
                  ...    Wait until boot completes
                  ...    Save the journal begin timestamp
                  ...    Disable offending units

Suite Teardown    Run Keywords
                  ...    Collect the suite journal
