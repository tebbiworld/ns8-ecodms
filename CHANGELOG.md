# Changelog

## 1.1.0 — 2026-09-19

Alignment with the NethServer module conventions (NethServer/agents skills).

### Changed

- **Working restore.** New `restore-module` steps re-apply the settings on the restored instance (host name and route, language). Before, a restored instance had its volumes back but came up unconfigured.
- Service restarts list both units of the pod explicitly; `update-module` only restarts a running instance.
- Removed calls to the deprecated `agent.dump_env()`.

### Added

- Robot Framework tests (install, update from the previous release, backup and restore) run on real NS8 nodes through `stephdl/ns8-ci-actions`.

Secrets: nothing to move, this module stores no password in its environment.

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
