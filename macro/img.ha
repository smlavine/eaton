// eaton:macro/img.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// Converts the provided src and alt-text into an <img> that is surrounded by
// a clickable link to itself (HTML).

use fmt;
use io;
use regex::{compile};
use strings::{toutf8};

def IMG_RE = `img!\([[:space:]]*"(.*)"[[:space:]]*,[[:space:]]*"(.*)"[[:space:]]*\)`;

@init fn append_macro() void = {
	append(macros, macro {
		info = (
			`img!("src", "alt")`,
			"Converts the provided src and alt-text into an <img> that is surrounded by a clickable link to itself (HTML).",
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
