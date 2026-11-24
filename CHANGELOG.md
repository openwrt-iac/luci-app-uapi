# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project adheres to
[Semantic Versioning](https://semver.org/).

Versioning is independent of uapi: a release happens only when this app changes,
never because uapi was bumped. See README "Versioning".

## [Unreleased]

### Changed

- The Settings page adds a missing `logging` or `ratelimit` section when it
  loads, and the section is saved with the form. The `40_luci-uapi` uci-defaults
  script is removed: it ran only at install, so the page showed no option when
  the sections were deleted later.
- The backend reads the output of `uapi-token` through one pipe, and writes no
  temporary file to `/tmp`. An error shows only the message of `uapi-token`,
  without the ucode stack trace that followed it.
- The rpcd plugin is installed `0644` without a shebang: rpcd loads it and never
  runs it. The unused `force` argument of `create_token` and the unused
  `prefix_entries` field of `get_status` are removed.

### Fixed

- On OpenWrt main, a token name with a newline passed the name check of the app,
  and `uapi-token` then reported a token that it never wrote. ucode 8a8b4d12a8
  changed `^` and `$` to also match at a newline, so the app now refuses a
  newline itself. The check that finds the new bearer in the output of
  `uapi-token` works with the ucode of OpenWrt 25.12 and of main.
- The Copy button of the "Token created" dialog works over plain HTTP. Browsers
  give `navigator.clipboard` only to HTTPS and localhost pages, so the button did
  nothing there. It now selects the bearer, and it copies with the older copy
  command when the clipboard API is missing.
- A failed revoke call or a failed change of the insecure marker shows an error.
  Before, the revoke dialog stayed open with no message.
- The token list reads `expires_at`, `last_used_at`, `rate` and `burst` as uapi
  reads them: a value that is not a whole integer reads as unset.
- Sentences that wrapped a token name or an error are now one translatable string
  with a placeholder, so a translation can put the name or the error where its
  language needs it. Before, translators got fragments such as `? Any client using
  it will be denied immediately.`, and the template lost their edge spaces.
- Status badges use the theme's `label success` and `label warning` classes
  instead of fixed inline colors, so they follow the active theme and its dark
  mode. `label warning` is styled by all four themes that ship with LuCI.

## [1.1.1]

Compatible with uapi 2.x and 3.x. No change to the app itself.

### Fixed

- Ships the MIT license the package has always declared. `PKG_LICENSE:=MIT` was set
  with no `LICENSE` file in the repository, so the project read as unlicensed to
  anyone evaluating it, and `PKG_LICENSE_FILES` had nothing to point at.
- The package maintainer address is now `guy.godfroy@gugod.fr` rather than a work
  address, in every package index and SBOM that lists this app. It is set through
  `LUCI_MAINTAINER`: the LuCI build include assigns the package's maintainer field
  from that variable alone, so the `PKG_MAINTAINER` used before was dropped and the
  app shipped as "OpenWrt LuCI community". Conduct reports go to the org address in
  `CODE_OF_CONDUCT.md`; the package maintainer is a person.
- A moved tag no longer leaves its release unpublished. Deleting a tag reverts its
  GitHub release to a draft, and the release job could not tell a draft apart from a
  published release, so it attached the rebuilt package to a release nobody could
  see and the package feed kept serving the previous version.

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
