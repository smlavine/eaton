// eaton:macro/getenv.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// Converts the provided environment variable name to its value, if one exists.
// Otherwise is replaced with the empty string.

use io;
use os::{tryenv};
use regex::{compile};
use strings::{toutf8};

// TODO: provided default value; doesn't work
//def GETENV_RE = `getenv!\([[:space:]]*([^),]*)(,[[:space:]]*"[^"]*")?[[:space:]]*\)`;

def GETENV_RE = `getenv!\([[:space:]]*([^)[:space:]]*)[[:space:]]*\)`;

@init fn append_macro() void = {
	append(macros, macro {
		description = `getenv!(...)`,
		regex = compile(GETENV_RE)!,
		formatter = &getenv,
	});
};

export fn getenv(h: io::handle, args: []str) (size | io::error) = {
	// TODO: default value, like in tryenv. Can variable amount of
	// capture groups be used?
	assert(len(args) == 1);
	return io::write(h, toutf8(tryenv(args[0], "")));
};
