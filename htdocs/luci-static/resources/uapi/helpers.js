'use strict';
'require baseclass';

return baseclass.extend({
	fmtTime: function (epoch) {
		if (!epoch) return '-';
		return new Date(epoch * 1000).toLocaleString();
	},

	badge: function (ok, yes, no) {
		return E('span', {
			'class': 'label',
			'style': 'background-color:%s;color:#fff;padding:2px 8px;border-radius:3px'
				.format(ok ? '#5bb75b' : '#999')
		}, [ ok ? (yes || _('Yes')) : (no || _('No')) ]);
	},

	warnBadge: function (text) {
		return E('span', {
			'class': 'label',
			'style': 'background-color:#da4f49;color:#fff;padding:2px 8px;border-radius:3px'
		}, [ text ]);
	},

	row: function (label, value) {
		return E('tr', { 'class': 'tr' }, [
			E('td', { 'class': 'td left', 'width': '33%' }, [ label ]),
			E('td', { 'class': 'td left' }, [ value ])
		]);
	}
});
