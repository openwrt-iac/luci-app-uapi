# luci-app-uapi

LuCI web interface for [uapi](https://github.com/openwrt-iac/uapi), the native
REST API for OpenWrt. It is a local config manager: every page reads and writes
state on the router (uci, the `uapi-token` CLI, marker files) through ubus/rpcd.
It is not an HTTP API client and makes no network calls; uapi runs inside uhttpd
and there is no login flow.

## Pages

Under **Services -> uAPI**:

- **Status** -- handler installed, contract version (read from the shipped
  `/usr/share/uapi/openapi.json`), whether the `/api/v2` prefix is wired into
  uhttpd, active token count, the HTTPS-listener and insecure-bypass posture,
  plus a button to create/remove the `/etc/uapi.insecure` marker.
- **Tokens** -- list tokens (scopes, expiry, allowed CIDRs, last use), create a
  token (name, scope picker, expiry, source-CIDR pinning, force), and revoke.
  Token creation shells out to `uapi-token`; the cleartext bearer is shown once.
- **Settings** -- UCI form over `/etc/config/uapi`: logging (access/debug) and
  rate limiting (rate/burst). Token sections in the same file are left untouched.

## Architecture

- `htdocs/luci-static/resources/view/uapi/*.js` -- client-side views.
- `root/usr/share/rpcd/ucode/uapi.uc` -- backend (`luci.uapi`): reads local
  state, shells out to the `uapi-token` CLI, toggles the insecure marker.
- `root/usr/share/rpcd/acl.d/luci-app-uapi.json` -- ACLs for the above.
- `root/usr/share/luci/menu.d/luci-app-uapi.json` -- menu entries.
- `root/etc/uci-defaults/40_luci-uapi` -- ensures the optional `logging` and
  `ratelimit` sections exist so the Settings form has something to render.

## Build

The Makefile does `include ../../luci.mk`, so the package must live inside the
luci feed tree. To build a one-off apk against a pinned SDK without a full
checkout, use the helper (downloads + verifies the SDK, injects the package,
compiles):

```sh
SDK_URL=https://downloads.openwrt.org/releases/25.12.4/targets/x86/64/openwrt-sdk-25.12.4-x86-64_gcc-14.3.0_musl.Linux-x86_64.tar.zst \
SDK_SHA256=28e004c1be4d215d19c1f12a6aa4c8d8f80689549eb707d0ff5a71f16fa8d05f \
sh scripts/build-apk.sh
```

Or, inside an existing SDK with feeds set up:

```sh
cp -r . feeds/luci/applications/luci-app-uapi
./scripts/feeds update -i && ./scripts/feeds install -p luci luci-app-uapi
make package/luci-app-uapi/compile V=s
```

Depends on `luci-base` and `uapi`. Version is sourced from `VERSION`.

## CI / release

- `.github/workflows/ci.yml`:
  - **lint**: `scripts/lint.sh` (JSON validity, JS `node --check`, ucode syntax,
    no-em-dash house style, VERSION sanity). Runs on every push/PR.
  - **build**: builds the apk against the pinned SDK and uploads it as an
    artifact.
  - **release** (on a `v*` tag): verifies the tag is signed by a key in
    `.github/release-signers.asc`, checks the tag matches `VERSION`, rebuilds the
    apk, and attaches it to the GitHub Release. The signed apk feed at
    `openwrt-iac.github.io/feed/` picks the asset up on its next aggregator run.

Releasing: bump `VERSION`, add a `## [x.y.z]` section to `CHANGELOG.md`, then
push a signed tag `vx.y.z`.

## Versioning

luci-app-uapi is versioned **independently of uapi**, on its own semver line. A
release happens only when *this app* changes; a new uapi release never forces a
version bump here.

- **MAJOR**: breaking app change (e.g. dropping support for an older uapi, or a
  redesign that changes ACLs/menus).
- **MINOR**: backwards-compatible app features (new pages, fields, options).
- **PATCH**: app bug fixes.

The app is a thin local manager, so its compatibility with uapi is broad and is
expressed by the `+uapi` dependency, not by the version number. It currently
works with uapi 2.x (the `/api/v2` prefix it checks, the v2 scope tree it
suggests, and the `uapi-token` CLI / `/etc/config/uapi` schema it drives). If a
future uapi makes a breaking change to that local surface, the app that handles
it ships as a normal release and, if enforcement is needed, gains a
version-constrained dependency (`+uapi (>= x.y.z)`, which OpenWrt supports).

`VERSION` is the single source of truth; `PKG_RELEASE` (in the Makefile) bumps
only for packaging-only rebuilds against an unchanged `VERSION`.
