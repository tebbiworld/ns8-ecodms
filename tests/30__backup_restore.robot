*** Settings ***
Library     SSHLibrary
Resource    api.resource

*** Test Cases ***
Seed a probe file
    Run on node    runagent -m ${module_id} podman run --rm --volume ecodms-scaninput:/v:z docker.io/library/alpine:3.20 sh -c 'echo pre-backup > /v/ci_probe.txt'

Back up the module
    ${repo}    ${path} =    Back up the module to the cluster repository    ${module_id}
    Set Global Variable    ${BACKUP_REPO}    ${repo}
    Set Global Variable    ${BACKUP_PATH}    ${path}

Remove the original instance
    # org.nethserver.max-per-node=1: a second instance is refused while the first exists.
    # After the removal wait out logind's user stop delay: on Rocky 9 (systemd 252) a
    # module re-created within seconds gets the same UID back, the user manager for that
    # UID is not started again and the agent of the new instance never comes up.
    Run on node    remove-module --no-preserve ${module_id}
    Sleep    45s

Restore into a new instance
    ${rid} =    Restore the module from the cluster repository    ${BACKUP_REPO}    ${BACKUP_PATH}
    Set Global Variable    ${restored_id}    ${rid}
    Set Global Variable    ${module_id}    ${rid}

The restored instance has data and settings
    ${cfg} =    Run task    module/${restored_id}/get-configuration    {}
    Should Be Equal    ${cfg['host']}    ecodms.ci.test
    Should Be Equal    ${cfg['language']}    en_US.UTF-8
    ${out} =    Run on node    runagent -m ${restored_id} podman run --rm --volume ecodms-scaninput:/v:z docker.io/library/alpine:3.20 cat /v/ci_probe.txt
    Should Contain    ${out}    pre-backup
