# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project adheres to
[Semantic Versioning](https://semver.org/).

Versioning is independent of uapi: a release happens only when this app changes,
never because uapi was bumped. See README "Versioning".

## [Unreleased]

## [1.0.0]

Initial release. Compatible with uapi 2.x.

- Status page: handler/version, uhttpd wiring, token count, TLS posture, and the
  `/etc/uapi.insecure` bypass marker (with toggle). All checks are local.
- Tokens page: list, create (scope picker, expiry, source-CIDR pinning, force)
  with one-time cleartext reveal, and revoke. Backed by the `uapi-token` CLI.
- Settings page: UCI form for logging (access/debug) and rate limiting
  (rate/burst) over `/etc/config/uapi`, leaving token sections untouched.
