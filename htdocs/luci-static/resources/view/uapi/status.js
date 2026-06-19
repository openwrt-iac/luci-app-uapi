'use strict';
'require view';
'require rpc';
'require ui';
'require dom';

const callStatus = rpc.declare({
	object: 'luci.uapi',
	method: 'get_status'
});

const callSetInsecure = rpc.declare({
	object: 'luci.uapi',
	method: 'set_insecure',
	params: [ 'enable' ]
});

function badge(ok, yes, no) {
	return E('span', {
		'class': 'label',
		'style': 'background-color:%s;color:#fff;padding:2px 8px;border-radius:3px'
			.format(ok ? '#5bb75b' : '#999')
	}, [ ok ? (yes || _('Yes')) : (no || _('No')) ]);
}

function warnBadge(text) {
	return E('span', {
		'class': 'label',
		'style': 'background-color:#da4f49;color:#fff;padding:2px 8px;border-radius:3px'
	}, [ text ]);
}

function row(label, value) {
	return E('tr', { 'class': 'tr' }, [
		E('td', { 'class': 'td left', 'width': '33%' }, [ label ]),
		E('td', { 'class': 'td left' }, [ value ])
	]);
}

return view.extend({
	load: function () {
		return callStatus();
	},

	renderService: function (st) {
		const rows = [
			row(_('Handler installed'), badge(!!st.installed)),
			row(_('API version'), st.version ? E('strong', {}, [ st.version ]) : _('Unknown')),
			row(_('Wired into uhttpd'), st.wired
				? badge(true)
				: warnBadge(_('No: run the package install hook'))),
			row(_('Active tokens'), E('span', {
				'style': 'display:inline-flex;align-items:center;gap:.75em'
			}, [
				E('strong', {}, [ '' + (st.token_count || 0) ]),
				E('button', {
					'class': 'cbi-button cbi-button-action',
					'click': function () { location.href = L.url('admin/services/uapi/tokens'); }
				}, [ _('Manage tokens') ])
			]))
		];

		return E('div', { 'class': 'cbi-section' }, [
			E('h3', {}, [ _('Service') ]),
			E('table', { 'class': 'table' }, rows)
		]);
	},

	renderSecurity: function (st) {
		const self = this;
		const httpsOn = (st.https_listen && st.https_listen.length > 0);

		const insecureBtn = E('button', {
			'class': 'btn ' + (st.insecure ? 'cbi-button-negative' : 'cbi-button-action'),
			'click': ui.createHandlerFn(this, function () {
				const enable = !st.insecure;
				if (enable && !confirm(_('This disables TLS enforcement: uapi will accept plain HTTP from any client, not just the loopback. Only do this on a trusted closed network. Continue?')))
					return;
				return callSetInsecure(enable).then(function (res) {
					if (res && res.error)
						ui.addNotification(null, E('p', {}, [ res.error ]), 'error');
					return self.refresh();
				});
			})
		}, [ st.insecure ? _('Remove insecure marker') : _('Create insecure marker') ]);

		const rows = [
			row(_('HTTPS listener'), httpsOn
				? badge(true, _('Enabled'))
				: warnBadge(_('Not configured'))),
			row(_('Insecure HTTP bypass'), st.insecure
				? warnBadge(_('ACTIVE: /etc/uapi.insecure present'))
				: badge(false, '', _('Off'))),
			row('', insecureBtn)
		];

		return E('div', { 'class': 'cbi-section' }, [
			E('h3', {}, [ _('Security') ]),
			st.insecure ? E('div', { 'class': 'alert-message warning' }, [
				_('Plain HTTP is currently accepted from any client. Bearer tokens still apply, but they travel in cleartext. Remove the marker for production use.')
			]) : '',
			E('table', { 'class': 'table' }, rows),
			E('p', { 'class': 'cbi-value-description' }, [
				_('uapi requires TLS for non-loopback clients. The default uhttpd self-signed certificate is not adequate for production; use luci-app-acme for a real certificate.')
			])
		]);
	},

	refresh: function () {
		const self = this;
		return callStatus().then(function (st) {
			const container = document.getElementById('uapi-status');
			if (!container) return;
			dom.content(container, [
				self.renderService(st),
				self.renderSecurity(st)
			]);
		});
	},

	render: function (st) {
		st = st || {};

		const container = E('div', { 'id': 'uapi-status' }, [
			this.renderService(st),
			this.renderSecurity(st)
		]);

		return E('div', {}, [
			E('h2', {}, [ _('uAPI Status') ]),
			container
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
