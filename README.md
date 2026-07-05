# ns8-ecodms

A [NethServer 8](https://github.com/NethServer/ns8-core) module that packages the
[**ecoDMS**](https://www.ecodms.de) document archive and management system
(ecoDMS 26.01 "burns") from the official `ecodms/ecodms` image.

## Installation

```
add-module ghcr.io/tebbiworld/ecodms:latest 1
```

Only **one instance per node** is supported, because the ecoDMS server uses the
fixed ports 17001–17004.

## Configuration

Open the module UI and set:

- **Host name (FQDN)** – where the ecoDMS **web client** is reachable, e.g.
  `ecodms.example.org` (must resolve to this server).
- **Interface language** – German or English.
- **Let's Encrypt** / **HTTP→HTTPS** – the HTTPS transport for the web client.

## How it is exposed (no dedicated IP)

ecoDMS offers HTTP services and its own non-HTTP protocol:

| Service | Container port | Exposed as |
| ------- | -------------- | ---------- |
| Web client | 8080 | Traefik HTTPS route on the host name (`https://<fqdn>/`) |
| REST API   | 8180 | Traefik route under `https://<fqdn>/api` |
| ecoDMS server / Connection Manager | 17001 | published on the node (`<fqdn>:17001`) |
| Database   | 17002 | published on the node |
| ecoDMS services | 17003, 17004 | published on the node |

Traefik only routes HTTP, so the ecoDMS server ports (17001–17004), used by the
**ecoDMS desktop client software / Connection Manager**, are published directly
on the node. They bind on the node's existing address — **no separate IP is
required for ecoDMS**. In the ecoDMS client, connect to the server
`<fqdn>` on port `17001`.

## Storage (isolated, no host paths)

Data lives in rootless named volumes, never bind-mounted host paths:

| Volume | Mount | Purpose |
| ------ | ----- | ------- |
| `ecodms-data` | `/srv/data` | the ecoDMS archive (permissions must not be changed) |
| `ecodms-backup` | `/srv/backup` | backups (kept separate from data) |
| `ecodms-restore` | `/srv/restore` | restores (kept separate from data) |
| `ecodms-scaninput` | `/srv/scaninput` | drop folder for scanned documents |

Documents dropped into **scaninput** are imported automatically by ecoDMS. This
folder is designed to be shared to users via **Samba** (see the ecoDMS manual,
ch. 4.2.1 / 4.2.6) instead of exposing a host path.

> **Samba share for scaninput:** an optional AD-joined SMB side share can expose
> the `ecodms-scaninput` volume to users. On a node that already runs the NS8
> Samba/AD file server (TCP 445 in use), the side share cannot bind 445; use the
> existing file server instead, or run ecoDMS on a node without a Samba service.

## Backups

The NS8 backup covers the named volumes. For ecoDMS' own backup/restore feature
use the `/srv/backup` and `/srv/restore` folders as described in the ecoDMS
manual; keep them on separate storage from the data.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
