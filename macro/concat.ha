// eaton:macro/concat.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

// A simple macro that removes all whitespace.

use ascii;
use io;
use memio;
use regex::{compile};
use strings;

def CONCAT_RE = "<[ \t]*concat![ \t]+\"(.*)\"[ \t]*/[ \t]*>";

@init fn append_macro() void = {
	append(macros, macro {
		info = (`<concat! "..." />`, "Removes all whitespace"),
		regex = compile(CONCAT_RE)!,
		formatter = &concat,
	});
};

// XXX slice[n..m] instead of reallocating a buffer and deleting
export fn concat(h: io::handle, args: []str) (size | io::error) = {
	assert(len(args) == 1);

	let buf: []u8 = alloc(strings::toutf8(args[0])...);
	defer free(buf);

	for (let i = 0z; i < len(buf); i += 1) {
		if (ascii::isspace(buf[i]: u32: rune)) {
			delete(buf[i]);
			i -= 1; // Otherwise we'll skip the buf[i] that shifted
		};
	};

	let result = io::writeall(h, buf);
	return result;
};

@test fn concat_empty() void = {
	let out = memio::dynamic();
	defer io::close(&out): void;

	concat(&out, [""])!;
	let outstr = memio::string(&out)!;

	assert(outstr == "");
};

@test fn concat_all_whitespace() void = {
	let out = memio::dynamic();
	defer io::close(&out): void;

	concat(&out, ["\f\n\r\t\v "])!;
	let outstr = memio::string(&out)!;

	assert(outstr == "");
};

@test fn concat() void = {
	let out = memio::dynamic();
	defer io::close(&out): void;

	concat(&out, ["\tHello. My name is Bob. :)\n"])!;
	let outstr = memio::string(&out)!;

	assert(outstr == "Hello.MynameisBob.:)");
};
