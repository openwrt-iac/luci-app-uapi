# Contributing to luci-app-uapi

## What this is

A LuCI interface for [uapi](https://github.com/openwrt-iac/uapi): status, settings and token management, written as LuCI client-side views under `htdocs/luci-static/`. It talks to uapi over HTTP like any other client, which means it can only do what the operator's token permits.

## Dev loop

There is no build step for the views. They are plain JavaScript loaded by LuCI, so the loop is: edit, copy onto a router that already runs uapi and LuCI, and reload the page.

```sh
sh scripts/lint.sh        # what CI gates on: JSON, JS and ucode syntax, house style
sh scripts/build-apk.sh   # builds the package against the OpenWrt SDK
```

## What kinds of changes are welcome

- Surfacing a uapi capability the app cannot yet reach.
- Error handling: uapi returns a structured envelope with a `code` and per-field errors, and an app that swallows those into "something went wrong" wastes the work uapi did to be specific.
- Anything that reduces how long a token sits in memory, or narrows the scopes the app asks for.

## Versioning

Independent of uapi. A release happens when this app changes, never because uapi was bumped. See the README.

## Commit and PR style

One-line subject in the imperative. Explain in the body why the change is needed rather than restating the diff. Every change lands via a pull request.
