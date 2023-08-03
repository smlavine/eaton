// eaton:main.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

use bytes;
use io;
use os;

use macro;

// XXX: This type is used instead of io::writer because io::writer doesn't
// take io::handle and therefore io::write cannot be an io::writer.
// See hare patch on commit 72429c9.
type _writer = fn(h: io::handle, buf: const []u8) (size | io::error);

// Quotes around macro sections.
type quote = struct {
	text: []u8,  // Text representing the quote
	writer: *_writer, // Text before the quote should be written here
};

const quotes: [2]quote = [
	quote {
		text = ['`', '`'],
		writer = &io::write,
	},
	quote {
		text = ['\'', '\''],
		writer = &macro::process,
	},
];

export fn main() void = {
	let in: []u8 = io::drain(os::stdin)!;
	defer free(in);

	// `q ^= 1` alternates between 0 and 1
	for (let q = 0z, buf = in; len(buf) > 0; q ^= 1) {
		let (before, after) = bytes::cut(buf, quotes[q].text);
		quotes[q].writer(os::stdout, before)!;
		buf = after;
	};
};
