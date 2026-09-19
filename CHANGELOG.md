# Changelog

## 1.1.0 — 2026-09-19

Alignment with the NethServer module conventions (NethServer/agents skills).

### Changed

- **Working restore.** New `restore-module` steps re-apply the settings on the restored instance (host name and route, language). Before, a restored instance had its volumes back but came up unconfigured.
- Service restarts list both units of the pod explicitly; `update-module` only restarts a running instance.
- Removed calls to the deprecated `agent.dump_env()`.

### Fixed

- **English interface.** The language was handed to the container as `LANG`, `LANGUAGE` and `LC_ALL=en_US.UTF-8`, a locale the ecoDMS image does not ship: English never took effect, and a fresh install set to English could not initialise its database (the service kept restarting, the web client answered 502). The container now gets `LANG=eng`, the value the upstream start script expects. Found by the new install test. Existing instances are converted by an `update-module.d` hook.

### Added

- Robot Framework tests (install, update from the previous release, backup and restore) run on real NS8 nodes through `stephdl/ns8-ci-actions`.

Secrets: nothing to move, this module stores no password in its environment.

### Platform integration

- **Clone and move.** New `clone-module` step (a link to the restore step): a cloned or moved instance gets its route and settings back instead of coming up unconfigured. The settings are read from the source instance, including those a new instance starts with a default for.
- `org.nethserver.max-per-node=1`: the module owns fixed ports on the node, a second instance on the same node is refused at install time instead of failing at start.
- `org.nethserver.volumes`: the bulk-data volume(s) `ecodms-data ecodms-backup` can be placed on an additional disk when the module is installed.
- Release notes are linked from the software centre (`relnotes_url`).

## 1.0.2 — 2026-09-14

### Fixed

- `update-module` now restarts the service, so a new upstream image (automatic releases) or a changed unit takes effect right after the update instead of at the next reboot.

## 1.0.1 — 2026-09-13

### Fixed

- **The NS8 backup did not include the ecoDMS archive.** Without a
  `state-include.conf` the core backs up `state/environment` only. The backup
  now includes the module state and the volumes `ecodms-data`, `ecodms-backup`,
  `ecodms-restore` and `ecodms-scaninput`.

## 1.0.0 — 2026-07-05

- Initial release.
