/* Load this script using conditional IE comments if you need to support IE 7 and IE 6. */

window.onload = function() {
	function addIcon(el, entity) {
		var html = el.innerHTML;
		el.innerHTML = '<span style="font-family: \'icomoon\'">' + entity + '</span>' + html;
	}
	var icons = {
			'icon-cool' : '&#xe000;',
			'icon-heart' : '&#xe001;',
			'icon-box-add' : '&#xe002;',
			'icon-smiley' : '&#xe003;',
			'icon-checkmark' : '&#xe004;',
			'icon-close' : '&#xe005;',
			'icon-arrow-up' : '&#xe006;',
			'icon-arrow-down' : '&#xe007;',
			'icon-expand' : '&#xe008;',
			'icon-star' : '&#xe009;',
			'icon-bubble' : '&#xe00a;',
			'icon-paragraph-justify' : '&#xe00b;'
		},
		els = document.getElementsByTagName('*'),
		i, attr, html, c, el;
	for (i = 0; ; i += 1) {
		el = els[i];
		if(!el) {
			break;
		}
		attr = el.getAttribute('data-icon');
		if (attr) {
			addIcon(el, attr);
		}
		c = el.className;
		c = c.match(/icon-[^\s'"]+/);
		if (c && icons[c[0]]) {
			addIcon(el, icons[c[0]]);
		}
	}
};