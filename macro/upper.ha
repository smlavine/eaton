// eaton:macro/upper.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// A simple macro that converts all lowercase characters within the macro to
// uppercase.
// Useful for debugging and development.

use ascii::{strupper};
use io;
use memio;
use regex::{compile};
use strings::{toutf8};

def UPPER_RE = `upper!\(([^)]*)\)`;

@init fn append_macro() void = {
	append(macros, macro {
		info = (
			`upper!(...)`,
			"Converts all lowercase characters to uppercase",
		),
		regex = compile(UPPER_RE)!,
		formatter = &upper,
	});
};

export fn upper(h: io::handle, args: []str) (size | io::error) = {
	assert(len(args) == 1);
	let s = strupper(args[0]);
	let written = io::writeall(h, toutf8(s))?;
	free(s);
	return written;
};

@test fn upper() void = {
	let out = memio::dynamic();
	defer io::close(&out): void;

	upper(&out, ["lowercase text AND SOME UPPERCASE and 123 numbers"])!;
	let outstr = memio::string(&out)!;

	assert(outstr == "LOWERCASE TEXT AND SOME UPPERCASE AND 123 NUMBERS");
};
