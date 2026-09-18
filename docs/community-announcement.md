<!--
First community post for the NS8 ecoDMS module, written in the style
of https://community.nethserver.org/t/ns8-forgejo-testing/28554 (first post).
Paste into a new topic on community.nethserver.org, category "App", tag "ns8".
Fill in the wiki link once the page is published.
-->

# NS8 ecoDMS (testing)

Hi all,

I've built an NS8 module for [ecoDMS](https://www.ecodms.de) — the document archive and management system (DMS) for scanning, importing, classifying and full-text searching documents with revision-safe archiving.

It's in my community repository. To try it, add the repo once:

```
api-cli run add-repository --data '{"name":"tebbiworld","url":"https://raw.githubusercontent.com/tebbiworld/ns8-repo/main/ns8/updates/","status":true,"testing":false}'
```

then install **ecoDMS** from the Software Center. (Or straight from the image: `add-module ghcr.io/tebbiworld/ecodms:latest 1`.)

What it does:

* Packages the official `ecodms/ecodms` server image for NethServer 8 as a single rootless container
* Serves the **web client** and the **REST API** on one host name behind Traefik with Let's Encrypt
* Publishes the ecoDMS server ports 17001–17004 on the node so the **desktop client / Connection Manager** can connect — no dedicated IP address required
* A **scan input folder** volume: documents dropped there are imported into the archive automatically
* Interface language German or English
* NS8 backup covers the module state and all four named volumes (archive, scan input, backup and restore folders)

A few things to know:

* **Only one instance per node**, because the ecoDMS server uses the fixed ports 17001–17004.
* ecoDMS is proprietary software from ecoDMS GmbH — the module ships no ecoDMS code, the node pulls the official image at install time, and licensing (free for private use, per-user business licences) is handled inside ecoDMS as the vendor documents.
* The scan input folder isn't exposed as a network share yet: on a node that also runs the NS8 file server, port 445 is already taken. For a guaranteed-consistent database copy, run ecoDMS' own backup into `/srv/backup` first — that volume is part of the NS8 backup too.

This is still testing, so I'd love feedback from anyone who tries it — particularly around the desktop-client connection and backups.

Docs: NethServer wiki (tebbiworld repository) · Source: [github.com/tebbiworld/ns8-ecodms](https://github.com/tebbiworld/ns8-ecodms)

Thanks!

*Category: App · Tags: ns8*
