# Security policy

## Reporting a vulnerability

Use GitHub's private vulnerability reporting: **[Report a vulnerability](https://github.com/openwrt-iac/luci-app-uapi/security/advisories/new)**.

Expect a first response within a week. That is a rough figure rather than an SLA.

## What counts as a vulnerability here

This app is browser-side JavaScript served by LuCI. It holds a uapi bearer token in order to call the API, so the interesting boundary is that token and what the pages render.

- The token reaching anywhere it should not: written to a log, put in a URL, sent to an origin other than the router, or left readable by another LuCI user with fewer privileges.
- Markup injection: a uci value rendered into a page without escaping, so a hostile value stored on the router executes as script for the next operator who opens the page.
- Any call that escalates what the operator can do beyond the scopes their token carries.

## Out of scope

- What uapi itself accepts or refuses. Report that to [uapi](https://github.com/openwrt-iac/uapi/security/advisories/new); this app is a client.
- LuCI's own session handling and authentication.
- An operator with root on the router doing something destructive through the UI on purpose.

## Supported versions

The current release only. Fixes ship as a new version rather than as backports.
