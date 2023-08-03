// eaton:macro/img.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// Converts the provided src and alt-text into an <img> that is surrounded by
// a clickable link to itself (HTML).

use io;
use regex::{compile};
use strings::{toutf8};

def IMG_RE = `img!\([[:space:]]*"(.*)"[[:space:]]*,[[:space:]]*"(.*)"[[:space:]]*\)`;

@init fn append_macro() void = {
	append(macros, macro {
		description = `img!("src", "alt")`,
		regex = compile(IMG_RE)!,
		formatter = &img,
	});
};

export fn img(h: io::handle, args: []str) (size | io::error) = {
	assert(len(args) == 2);

	return io::write(h, toutf8(`<a href="`))?
		+ io::write(h, toutf8(args[0]))?
		+ io::write(h, toutf8(`"><img src="`))?
		+ io::write(h, toutf8(args[0]))?
		+ io::write(h, toutf8(`" alt="`))?
		+ io::write(h, toutf8(args[1]))?
		+ io::write(h, toutf8(`"></a>`))?;
};