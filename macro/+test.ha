// eaton:macro/+test.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

use io;
use memio;
use strings::{toutf8};

@test fn no_macros() void = {
	const input = "Text and more text";
	let out = memio::dynamic();
	defer io::close(&out): void;

	process(&out, toutf8(input))!;

	let outstr = memio::string(&out)!;

	assert(outstr == input);
};

@test fn one_simple_macro() void = {
	const input = `<upper! "text"/>`;
	let out = memio::dynamic();
	defer io::close(&out): void;

	process(&out, toutf8(input))!;

	let outstr = memio::string(&out)!;

	assert(outstr == "TEXT");
};

@test fn regular_text_and_macro() void = {
	const input = `Hi there, <upper! "everyone" />!";
	let out = memio::dynamic();
	defer io::close(&out): void;

	process(&out, toutf8(input))!;

	let outstr = memio::string(&out)!;

	assert(outstr == "Hi there, EVERYONE!");
};

@test fn multiple_macros() void = {
	const input = `My name is <upper! "eaton"/> and I live at <concat! "123 Apple Street"/>.`;
	let out = memio::dynamic();
	defer io::close(&out): void;

	process(&out, toutf8(input))!;

	let outstr = memio::string(&out)!;

	assert(outstr == "My name is EATON and I live at 123AppleStreet.");
};

@test fn nested_macros() void = {
	const input = `<upper! "<concat! "a b"/>" />"`;
	let out = memio::dynamic();
	defer io::close(&out): void;

	process(&out, toutf8(input))!;

	let outstr = memio::string(&out)!;

	assert(outstr == "AB");
};
