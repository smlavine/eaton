// eaton:macro/img.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// Converts the provided src and alt-text into an <img> that is surrounded by
// a clickable link to itself (HTML).

use fmt;
use io;
use memio;
use regex::{compile};

def IMG_RE = `img!\([[:space:]]*"(.*)"[[:space:]]*,[[:space:]]*"(.*)"[[:space:]]*\)`;

@init fn append_macro() void = {
	append(macros, macro {
		info = (
			`img!("src", "alt")`,
			`<a href="$src"><img src="$src alt="$alt"></a>`
		),
		regex = compile(IMG_RE)!,
		formatter = &img,
	});
};

export fn img(h: io::handle, args: []str) (size | io::error) = {
	assert(len(args) == 2);
	return fmt::fprintf(
		h,
		`<a href="{0}"><img src="{0}" alt="{1}"></a>`,
		args[0], args[1],
	);
};

@test fn img() void = {
	let out = memio::dynamic();
	defer io::close(&out): void;

	img(&out, ["/images/favicon.jpg", "A smiley face :)"])!;
	let outstr = memio::string(&out)!;

	assert(outstr == `<a href="/images/favicon.jpg"><img src="/images/favicon.jpg" alt="A smiley face :)"></a>`);
};
