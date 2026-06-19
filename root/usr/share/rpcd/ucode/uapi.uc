#!/usr/bin/env ucode

'use strict';

import { popen, stat, readfile, writefile, unlink } from 'fs';
import { cursor } from 'uci';

const TOKEN_CLI = '/usr/bin/uapi-token';
const HANDLER = '/usr/share/uapi/main.uc';
const OPENAPI = '/usr/share/uapi/openapi.json';
const INSECURE_MARKER = '/etc/uapi.insecure';
const PREFIX_ENTRY = '/api/v2=/usr/share/uapi/main.uc';
const NAME_RE = /^[A-Za-z0-9_]+$/;

function shellquote(s) {
	return "'" + replace(`${s}`, "'", "'\\''") + "'";
}

function as_list(v) {
	if (v == null) return [];
	if (type(v) == 'array') return v;
	return [ v ];
}

// uhttpd forwards a hard-coded header allowlist to mod-ucode handlers, so we
// cannot read the running version over HTTP without a token. The shipped spec
// is the authoritative local copy of the contract version.
function read_version() {
	const raw = readfile(OPENAPI);
	if (!raw) return null;
	try {
		const spec = json(raw);
		return spec?.info?.version;
	} catch (e) {
		return null;
	}
}

function prefix_entries(uci) {
	return as_list(uci.get('uhttpd', 'main', 'ucode_prefix'));
}

function token_sections(uci) {
	const tokens = [];
	const now = time();
	uci.foreach('uapi', 'token', (s) => {
		const expires_at = s.expires_at ? +s.expires_at : null;
		push(tokens, {
			name: s['.name'],
			scopes: as_list(s.scopes),
			expires_at,
			expired: (expires_at != null) ? (expires_at <= now) : false,
			allowed_cidrs: as_list(s.allowed_cidrs),
			last_used_at: s.last_used_at ? +s.last_used_at : null,
			last_used_ip: s.last_used_ip ?? null
		});
	});
	return tokens;
}

const methods = {
	get_status: {
		call: function() {
			const uci = cursor();
			const entries = prefix_entries(uci);
			const result = {
				installed: !!stat(HANDLER),
				version: read_version(),
				wired: (PREFIX_ENTRY in entries),
				prefix_entries: entries,
				token_count: length(token_sections(uci)),
				insecure: !!stat(INSECURE_MARKER),
				https_listen: as_list(uci.get('uhttpd', 'main', 'listen_https'))
			};
			uci.unload('uhttpd');
			uci.unload('uapi');
			return result;
		}
	},

	list_tokens: {
		call: function() {
			const uci = cursor();
			const tokens = token_sections(uci);
			uci.unload('uapi');
			return { tokens };
		}
	},

	// Authoritative scope list. uapi does not yet expose its scope tree through a
	// sanctioned interface (KNOWN_PATHS in scope.uc is module-private and
	// openapi.json does not enumerate scopes), and parsing the source file is too
	// brittle to rely on. Tracked upstream at
	// https://github.com/openwrt-iac/uapi/issues/5; once uapi ships a CLI/export,
	// fetch it here. Until then this returns empty and the token form falls back
	// to a free-text scope field.
	list_scopes: {
		call: function() {
			return { scopes: [] };
		}
	},

	create_token: {
		args: {
			name: 'string',
			scopes: [],
			expires_in_seconds: 0,
			allowed_cidrs: [],
			force: false
		},
		call: function(req) {
			const name = req.args?.name;
			const scopes = as_list(req.args?.scopes);
			const cidrs = as_list(req.args?.allowed_cidrs);
			const expires = +req.args?.expires_in_seconds;

			if (!name || !match(name, NAME_RE))
				return { error: 'Invalid name: must match [A-Za-z0-9_]+ (use underscores, not hyphens)' };
			if (!length(scopes))
				return { error: 'At least one scope is required' };

			let cmd = `${TOKEN_CLI} create --name ${shellquote(name)}`;
			for (let s in scopes) {
				if (!length(`${s}`)) continue;
				cmd += ` --scope ${shellquote(s)}`;
			}
			for (let c in cidrs) {
				if (!length(`${c}`)) continue;
				cmd += ` --allowed-cidr ${shellquote(c)}`;
			}
			if (expires > 0)
				cmd += ` --expires-in ${shellquote(expires)}`;
			if (req.args?.force)
				cmd += ' --force';

			// The CLI prints the cleartext bearer to stdout and a notice to
			// stderr; on failure it dies with a message on stderr. Capture the
			// two streams separately so we can surface either cleanly.
			const errfile = `/tmp/.luci-uapi-create.${time()}`;
			const fd = popen(`${cmd} 2>${shellquote(errfile)}`);
			if (!fd)
				return { error: 'Failed to launch uapi-token' };
			const stdout = trim(fd.read('all'));
			const code = fd.close();
			const stderr = trim(readfile(errfile) ?? '');
			unlink(errfile);

			if (code != 0 || !length(stdout))
				return { error: length(stderr) ? stderr : `uapi-token exited ${code}` };

			return { bearer: stdout, name, message: stderr };
		}
	},

	revoke_token: {
		args: { name: 'string' },
		call: function(req) {
			const name = req.args?.name;
			if (!name || !match(name, NAME_RE))
				return { error: 'Invalid token name' };

			const errfile = `/tmp/.luci-uapi-revoke.${time()}`;
			const fd = popen(`${TOKEN_CLI} revoke ${shellquote(name)} 2>${shellquote(errfile)}`);
			if (!fd)
				return { error: 'Failed to launch uapi-token' };
			fd.read('all');
			const code = fd.close();
			const stderr = trim(readfile(errfile) ?? '');
			unlink(errfile);

			if (code != 0)
				return { error: length(stderr) ? stderr : `uapi-token exited ${code}` };
			return { result: 'OK' };
		}
	},

	set_insecure: {
		args: { enable: false },
		call: function(req) {
			if (req.args?.enable) {
				if (writefile(INSECURE_MARKER, '') == null)
					return { error: `Cannot create ${INSECURE_MARKER}` };
			} else {
				if (stat(INSECURE_MARKER) && !unlink(INSECURE_MARKER))
					return { error: `Cannot remove ${INSECURE_MARKER}` };
			}
			return { result: 'OK', insecure: !!stat(INSECURE_MARKER) };
		}
	}
};

return { 'luci.uapi': methods };
