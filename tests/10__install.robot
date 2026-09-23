*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Variables ***
${CONFIG}    {"host":"ecodms.ci.test","lets_encrypt":false,"http2https":true,"language":"en_US.UTF-8"}
# releases up to 1.0.1 cannot start with English on a fresh install: the update scenario starts in German
${CONFIG_DE}    {"host":"ecodms.ci.test","lets_encrypt":false,"http2https":true,"language":"de_DE.UTF-8"}

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
    IF    '${SCENARIO}' == 'update'
        Run task    module/${module_id}/configure-module    ${CONFIG_DE}    decode_json=${FALSE}
    ELSE
        Run task    module/${module_id}/configure-module    ${CONFIG}    decode_json=${FALSE}
    END

ecoDMS answers behind Traefik
    Wait Until Keyword Succeeds    120 times    10 seconds    Web client is served

Update to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}
    Run on node    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    Wait Until Keyword Succeeds    120 times    10 seconds    Web client is served
    Run task    module/${module_id}/configure-module    ${CONFIG}    decode_json=${FALSE}
    Wait Until Keyword Succeeds    120 times    10 seconds    Web client is served

Configuration reads back
    ${cfg} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${cfg['host']}    ecodms.ci.test
    Should Be Equal    ${cfg['language']}    en_US.UTF-8

English interface is active
    ${out} =    Run on node    runagent -m ${module_id} podman exec ecodms-app grep -c -E '^locale.language=en' /opt/ecodms/ecodmsserver/ecodms.properties
    Should Be Equal As Strings    ${out.strip()}    1

Both units are active
    ${out} =    Run on node    runagent -m ${module_id} systemctl --user is-active ecodms.service ecodms-app.service | sort -u
    Should Be Equal As Strings    ${out.strip()}    active

*** Keywords ***
Web client is served
    # A fresh ecoDMS has no web client yet (it is enabled from the ecoDMS settings once the
    # archive is licensed), so its Jetty answers 404 on "/". What the module has to deliver is
    # the path Traefik -> pod -> Jetty: accept any answer of the backend, reject Traefik's own
    # 404 ("404 page not found", no route) and 502/503 (backend down).
    ${out} =    Run on node    curl -sSkL -w '\nHTTP_CODE=\%{http_code}' -H 'Host: ecodms.ci.test' https://127.0.0.1/
    Should Match Regexp    ${out}    HTTP_CODE=(200|401|403|404)
    Should Not Contain    ${out}    404 page not found
    ${port} =    Run on node    runagent -m ${module_id} podman exec ecodms-app bash -c 'ss -ltn | grep -q ":17001 " && echo listening'
    Should Be Equal As Strings    ${port.strip()}    listening
