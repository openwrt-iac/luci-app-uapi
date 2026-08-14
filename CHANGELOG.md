# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project adheres to
[Semantic Versioning](https://semver.org/).

Versioning is independent of uapi: a release happens only when this app changes,
never because uapi was bumped. See README "Versioning".

## [Unreleased]

## [1.1.1]

Compatible with uapi 2.x and 3.x. No change to the app itself.

### Fixed

- Ships the MIT license the package has always declared. `PKG_LICENSE:=MIT` was set
  with no `LICENSE` file in the repository, so the project read as unlicensed to
  anyone evaluating it, and `PKG_LICENSE_FILES` had nothing to point at.
- The package maintainer address is now `openwrt-iac@gugod.fr`, matching the other
  projects in the org rather than carrying a personal work address into every
  package index and SBOM that lists this app.

### Added

- `CONTRIBUTING.md`, `SECURITY.md` and `CODE_OF_CONDUCT.md`. The security policy
  states the boundary that actually matters for a browser-side app holding a bearer
  token: where that token may go, and markup injection from uci values rendered
  into a page.

## [1.1.0]

Compatible with uapi 2.x and 3.x.

### Added

- Per-token rate limit on the token create form: optional `rate` and `burst`
  overrides of the global limit (uapi 3.0.0+), shown as a column in the token
  table. Left blank the flags are omitted, so the form still works against a
  uapi that predates them.

### Fixed

- Detect the mounted API major (`/api/v2`, `/api/v3`, later) instead of matching
  the v2 prefix literally, and show it on the Status page. uapi 3.0.0 moves the
  uhttpd mount to `/api/v3`, which made "Wired into uhttpd" report No on an
  otherwise correctly wired 3.x router.

## [1.0.0]

Initial release. Compatible with uapi 2.x.

- Status page: handler/version, uhttpd wiring, token count, TLS posture, and the
  `/etc/uapi.insecure` bypass marker (with toggle). All checks are local.
- Tokens page: list, create (scope picker, expiry, source-CIDR pinning, force)
  with one-time cleartext reveal, and revoke. Backed by the `uapi-token` CLI.
- Settings page: UCI form for logging (access/debug) and rate limiting
  (rate/burst) over `/etc/config/uapi`, leaving token sections untouched.
