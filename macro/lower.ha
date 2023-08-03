// eaton:macro/lower.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// A simple macro that converts all uppercase characters within the macro to
// lowercase.
// Useful for debugging and development.

use ascii::{strlower};
use io;
use regex::{compile};
use strings::{toutf8};

def LOWER_RE = `lower!\(([^)]*)\)`;

@init fn append_macro() void = {
	append(macros, macro {
		description = `lower!(...)`,
		regex = compile(LOWER_RE)!,
		formatter = &lower,
	});
};

export fn lower(h: io::handle, args: []str) (size | io::error) = {
	assert(len(args) == 1);
	let s = strlower(args[0]);
	let written = io::write(h, toutf8(s))?;
	free(s);
	return written;
};
