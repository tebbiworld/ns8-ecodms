*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Variables ***
${CONFIG}    {"host":"ecodms.ci.test","lets_encrypt":false,"http2https":true,"language":"en_US.UTF-8"}

*** Test Cases ***
Install the module
    IF    '${SCENARIO}' == 'update'
        ${output}  ${rc} =    Execute Command    add-module ${UPDATE_FROM} 1    return_rc=True
    ELSE
        ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1    return_rc=True
    END
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Configure the module
    Run task    module/${module_id}/configure-module    ${CONFIG}    decode_json=${FALSE}

ecoDMS answers behind Traefik
    Wait Until Keyword Succeeds    120 times    10 seconds    Web client is served

Update to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}
    Run on node    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    Wait Until Keyword Succeeds    120 times    10 seconds    Web client is served

Configuration reads back
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${cfg['host']}    ecodms.ci.test
    Should Be Equal    ${cfg['language']}    en_US.UTF-8

Both units are active
    ${out} =    Run on node    runagent -m ${module_id} systemctl --user is-active ecodms.service ecodms-app.service | sort -u
    Should Be Equal As Strings    ${out.strip()}    active

*** Keywords ***
Web client is served
    ${code} =    Run on node    curl -sSkL -o /dev/null -w '\%{http_code}' -H 'Host: ecodms.ci.test' https://127.0.0.1/
    Should Be Equal As Strings    ${code.strip()}    200
