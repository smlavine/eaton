// eaton:main.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

use bufio;
use bytes;
use getopt;
use io;
use log;
use os;
use strings::{toutf8};

use macro;

// XXX: This type is used instead of io::writer because io::writer doesn't
// take io::handle and therefore io::write cannot be an io::writer.
// See hare patch on commit 72429c9.
type _writer = fn(h: io::handle, buf: const []u8) (size | io::error);

// Quotes around macro sections.
type quote = struct {
	text: []u8,  // Text representing the quote
	writer: *_writer, // Text before the quote will be written here
};

// The data required to begin a run of the program.
type config = struct {
	quotes: [2]quote,
	line_by_line: bool,
};

// Processes the buffer for quotes, and passes off text between the
// quotes to be processed for macros.
fn quote_buffer(buf: []u8, c: *config) (io::error | void) = {
	// `q ^= 1` alternates between 0 and 1
	for (let q = 0z; len(buf) > 0; q ^= 1) {
		let (before, after) = bytes::cut(buf, c.quotes[q].text);
		c.quotes[q].writer(os::stdout, before)?;
		buf = after;
	};
};

fn run(c: *config) (io::error | void) = {
	log::printfln("c.line_by_line = {}", c.line_by_line);
	switch (c.line_by_line) {
	case true =>
		for (true) {
			log::println("in line by line loop");
			match (bufio::scanline(os::stdin)?) {
			case let sl: []u8 =>
				defer free(sl);
				append(sl, '\n'); // scanline ignores newline
				quote_buffer(sl, c)?;
				bufio::flush(os::stdout)?;
			case io::EOF =>
				break;
			};
		};
	case false =>
		let buf: []u8 = io::drain(os::stdin)?;
		defer free(buf);
		quote_buffer(buf, c)?;
	};
};

// Can be enabled with -z option.
@init fn disable_logger() void = {
	log::setlogger(log::silent);
};

export fn main() void = {
	const cmd = getopt::parse(os::args,
		"reads text from stdin and processes it for macros",
		('i', "quote text", "define custom start quote (default: ``)"),
		('o', "quote text", "define custom end quote (default: '')"),
		('l', "read stdin line-by-line instead of all at once"),
		('z', "enable debug logging to stderr"),
	);
	defer getopt::finish(&cmd);

	let c = config {
		quotes = [
			quote {
				text = toutf8("``"),
				writer = &io::write,
			},
			quote {
				text = toutf8("''"),
				writer = &macro::process,
			},
		],
		...
	};

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		switch (cmd.opts[i].0) {
		case 'i' =>
			c.quotes[0].text = toutf8(cmd.opts[i].1);
		case 'o' =>
			c.quotes[1].text = toutf8(cmd.opts[i].1);
		case 'l' =>
			c.line_by_line = true;
		case 'z' =>
			log::setlogger(log::default);
		};
	};

	match (run(&c)) {
	case let e: io::error =>
		log::println("io::error:", io::strerror(e));
	case void =>
		void;
	};
};
