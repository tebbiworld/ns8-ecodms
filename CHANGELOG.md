# Changelog

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
