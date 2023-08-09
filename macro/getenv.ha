// eaton:macro/getenv.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// Converts the provided environment variable name to its value, if one exists.
// Otherwise is replaced with the empty string.

use io;
use memio;
use os;
use regex::{compile};
use strings;

// TODO: provided default value; doesn't work
//def GETENV_RE = `getenv!\([[:space:]]*([^),]*)(,[[:space:]]*"[^"]*")?[[:space:]]*\)`;

def GETENV_RE = `getenv!\([[:space:]]*([^)[:space:]]*)[[:space:]]*\)`;

@init fn append_macro() void = {
	append(macros, macro {
		info = (
			`getenv!(...)`,
			`Replaces macro with environment variable value, or "" if unset`,
		),
		regex = compile(GETENV_RE)!,
		formatter = &getenv,
	});
};

export fn getenv(h: io::handle, args: []str) (size | io::error) = {
	// TODO: default value, like in tryenv. Can variable amount of
	// capture groups be used?
	assert(len(args) == 1);
	return io::write(h, strings::toutf8(os::tryenv(args[0], "")));
};

@test fn getenv() void = {
	let out = memio::dynamic();
	defer io::close(&out): void;

	os::setenv("foo", "baz")!;

	getenv(&out, ["foo"])!;
	let outstr = memio::string(&out)!;

	assert(outstr == "baz");
};

@test fn getenv_unset() void = {
	let out = memio::dynamic();
	defer io::close(&out): void;

	os::unsetenv("foo")!;

	getenv(&out, ["foo"])!;
	let outstr = memio::string(&out)!;

	assert(outstr == "");
};
