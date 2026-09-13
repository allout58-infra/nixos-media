# AGENTS.md

Notes for working in `nixos-media`, gathered during the 2026-09-12/13 upgrade
pass (Immich 2.7.5 → 3.2.0, Jellyfin 10.11.11 → 12.0) and the outage that
followed it. Read this before touching this repo or the host.

See also the repo-set-wide `../AGENTS.md` for `nixos-common` / `nixos-hosts`
conventions; the style rules there apply here too.

## The host is live and load-bearing

`nixos-media` is a single physical machine serving a household: Jellyfin,
Immich, ErsatzTV, Booklore, Audiobookshelf, ImmichFrame, Ollama, plus two
hand-run Docker stacks. There is no staging. Breakage is immediately visible
to other people, so prefer `nh os build .` and `nh os test .` over `switch`
when uncertain, and stage risky work one service at a time.

- LAN: `192.168.2.52` — tailnet: `nixos-media.buffalo-catfish.ts.net`
- NAS: `192.168.2.20`, exports `/mnt/tank/media` and `/mnt/tank/data`
  (both restricted to `192.168.0.0/16`) and `/mnt/tank/backup` (open to `*`)
- `system.stateVersion = "24.05"` — this is why
  `virtualisation.oci-containers.backend` defaults to **podman**, which is
  what actually enables podman on this host. Nothing imports a containers
  module; the `podman-*` units exist because of that default.

### Hardware constraint that shapes everything

**7.5 GiB RAM and no swap.** At idle after boot it sits around 5.5 GiB used.
Jellyfin alone is ~950 MB, Booklore's JVM ~800 MB, ErsatzTV ~490 MB, Immich
~560 MB, and Ollama is enabled. Before adding a service or enabling anything
memory-hungry, check headroom — this host has almost none. See "The 19-hour
freeze" below for what happens when it runs out.

## Deploying

Deploys run **on the host**, from `~/nixos-media`:

```
nh os build .     # evaluate + build, no activation
nh os switch .    # activate and set boot default
```

- The trailing `.` matters. `programs.nh.flake` is set to
  `github:allout58-infra/nixos-media`, so a bare `nh os switch` ignores the
  local tree and deploys **the last pushed commit**.
- `nh os switch` can exit **non-zero after activating but before setting the
  boot default** — a transient podman healthcheck is enough to do it. Always
  confirm `/run/current-system` equals
  `/nix/var/nix/profiles/system` afterwards, and re-run if it doesn't. This
  happened for real: 3.2.0 was running while generation 80 (3.1.0) was still
  the boot default.
- Always read `nh`'s `DIFF` line before switching. A negative multi-GiB diff
  means you are about to *downgrade*.

### Never blindly sync `flake.lock` between laptop and host

A `tar` sync of the working tree overwrote the host's updated `flake.lock`
with a stale laptop copy and silently built **Immich 2.7.5 against an
already-migrated 3.1.0 database**. It was caught only by reading the `DIFF`
line. Treat the laptop repo as the source of truth: run `nix flake update`
there, commit, push, and pull on the host.

## Cross-repo coupling

Same rule as `nixos-hosts`: `nixos-common` is consumed as a **remote GitHub
flake input**, so edits there do nothing until committed, pushed, and
re-locked here. To test local edits without pushing:

```
nix eval '.#nixosConfigurations.nixos-media.config.system.build.toplevel.drvPath' \
  --override-input nixos-common ../nixos-common
```

(The installable must come **before** `--override-input`, or the two-argument
flag swallows it.)

**This host's agenix key is the `nix-media` attribute**, not `nixos-media` —
the attribute name in `nixos-common/secrets/secret-inputs.nix` does not match
the hostname. `secrets-export.nix` is an **explicit list with no directory
scanning**, so adding a `.age` file alone does nothing.

## NFS and the two mount-related outages

`media-mnt.nix` holds a shared `nfsOptions` binding — reuse it for any new
export rather than writing a fresh option list.

- **Boot race (cost 16 days).** `nofail` keeps a dead NAS from hanging boot,
  but on its own it lets boot continue with the mount silently missing. The
  2026-08-27 reboot hit systemd's default 90 s mount timeout, `/mnt/data`
  never mounted, and `immich-server` crash-looped **153,914 times**. Fixed
  with `retry=5` + `x-systemd.mount-timeout=10min`, plus
  `RequiresMountsFor` and a start limit on the unit.
- **`retry=` never appears in `/proc/mounts`** — it is consumed by
  `mount.nfs` itself. Don't conclude it wasn't applied.
- **`intr` is a no-op** on modern kernels (dead since 2.6.25). It is still in
  the option list; it buys nothing.
- The mounts are **`hard`** (no `soft` is set, and `hard` is the default), so
  a client-side NFS stall blocks processes forever and unkillably.
- **Any unit that writes to `/mnt/*` needs `unitConfig.RequiresMountsFor`.**
  Without it a missing NAS means writing into the *empty local mountpoint* —
  silent misplacement, which is worse than a failure. `immich-server` and
  `libation-pull` have it; check any new unit does too.

## `/tmp` is cleared on boot

Podman bind-mount *sources* under `/tmp` vanish on every boot and the
container then fails with `statfs ...: no such file or directory`, burns its
restart budget, and stays dead until someone recreates the directory by hand.
Booklore's `/tmp/booklore/bookdrop` had never survived a reboot for this
reason. Declare every such path in `systemd.tmpfiles.settings`.

## Service-specific gotchas

- **Jellyfin 12 renamed its database to `jellyfin.db`.** `library.db`,
  `library.db.old`, and `library.db.bak1` in `/var/lib/jellyfin/data/` are
  dead leftovers from the 10.10→10.11 migration. Check the right file.
- **`sqlite3 <path> "PRAGMA integrity_check"` on a nonexistent path silently
  creates an empty database and prints `ok`.** Verify the file exists first,
  or you will "prove" a database is healthy when you never opened it.
- **Jellyfin plugin `targetAbi` is a minimum, not an exact match.** The
  question for a major upgrade is whether a build for the new major exists at
  all, not whether the plugin is official.
- **Immich:** the pgvecto.rs `vectors` extension was removed from nixpkgs.
  A dangling `CREATE EXTENSION vectors` in `pg_dump` output made **all 14**
  pre-existing auto-backups unrestorable. The extension has been dropped; if
  you see it again, backups are silently broken.
- **Postgres collation:** `template1` had a stale collation version
  (glibc 2.39 → 2.42) which made `CREATE DATABASE` fail and would have
  blocked any restore. Fixed with `ALTER DATABASE template1 REFRESH
  COLLATION VERSION`. Restore as the `postgres` superuser without
  `--role=immich`, or extension creation fails.
- **`DynamicUser` services** (`ersatztv`, `seerr`, `ollama`) have
  `/var/lib/<name>` as a **symlink into `/var/lib/private/`**. Back up the
  real paths — `tar` needs `-h`, and restic archives the symlink rather than
  following it.
- **Two undeclared Docker stacks** — Karakeep and Dawarich — are hand-run
  compose, invisible to the flake. They exist on the host and hold state.

## The 19-hour freeze (2026-09-12)

Worth understanding before diagnosing any future unresponsiveness.

The box wedged at `18:38:19` and stayed wedged until a power cut ~19 hours
later. Symptoms: ICMP fine, TCP handshakes completing on **every** listening
port, and **zero** application bytes from any daemon — sshd, nginx, Jellyfin,
Immich, Booklore alike.

That combination is diagnostic. Open sockets mean the processes still exist
(a dead process gives connection *refused*), so this is not a crash; the
kernel is accepting connections that no application ever picks up. The last
line written to the journal was postgres failing to *start* an autovacuum
worker. There were no OOM kills, no hung-task warnings, no NFS errors and no
I/O errors — the cause was memory exhaustion on a swapless box thrashing on
page-cache eviction, which never triggers the OOM killer.

**`kernel.sysrq` was `16`** — a bitmask meaning *sync only*. `W` (blocked
tasks), `M` (memory), `F` (OOM kill), `U` (remount-ro) and `B` (reboot) were
all disabled, so there was no way to recover or even capture evidence.
Everything survived the hard power cut: postgres crash-recovered cleanly and
`jellyfin.db` passed `integrity_check`.

Useful remote triage when the host won't answer SSH: probe several TCP ports
plus one known-closed port (`5432` is localhost-only and gives a clean
refusal) to distinguish "kernel alive, userspace wedged" from a network
problem, and run `showmount -e 192.168.2.20` to check the NAS independently.

## Style

- Formatter is `alejandra`; run it manually.
- `with pkgs;` only for lists longer than 3 items.
- Prefer typed options over `extraConfig`. **This repo currently has zero
  `extraConfig` uses** — worth preserving. nginx's `client_max_body_size` has
  no first-class option and is a legitimate exception, but comment it.
- Follow the existing idiom in `reverse-proxy.nix`: `let`-bound attrsets
  (`acmeSSL`, `tailscaleSsl`, ...) merged with `//`.
- Note the pre-existing typo `cloudflare_dns_chalenge` — keep it consistent
  or fix all uses in one go.

## Deliberate decisions — don't re-litigate without asking

- **Immich's port 2283 stays open** and `host = "0.0.0.0"` stays. Remote
  access runs over Tailscale on the raw port, and there is only one tailnet
  hostname, already bound to Jellyfin by the existing vhost. Closing 2283
  needs a design decision, not a config tweak.
- **`karakeep.tgz`** (21.8 MB, gitignored) was **never committed** — verified
  with `git log --all -- karakeep.tgz` and `git rev-list --objects --all`. No
  history rewrite is needed. It contains live Tailscale node state and a TLS
  private key. Deleting it is irreversible; ask first.
- **Booklore's DB passwords are still plaintext in the repo and in git
  history.** The linuxserver MariaDB image only honours
  `MYSQL_ROOT_PASSWORD` on *first* initialisation, so the committed root
  password no longer matches the database. Recovering it and moving both to
  agenix is planned work — rotating them is a separate exercise.
