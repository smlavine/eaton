// eaton:main.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

use bufio;
use bytes;
use fmt;
use getopt;
use io;
use log;
use os;
use sort;
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
	in: io::handle,
	out: io::handle,
	line_by_line: bool,
};

// Processes the buffer for quotes, and passes off text between the
// quotes to be processed for macros.
fn quote_buffer(buf: []u8, c: *config) (io::error | void) = {
	// `q ^= 1` alternates between 0 and 1
	for (let q = 0z; len(buf) > 0; q ^= 1) {
		let (before, after) = bytes::cut(buf, c.quotes[q].text);
		c.quotes[q].writer(c.out, before)?;
		buf = after;
	};
};

fn run(c: *config) (io::error | void) = {
	switch (c.line_by_line) {
	case true =>
		for (true) {
			match (bufio::scanline(c.in)?) {
			case let sl: []u8 =>
				defer free(sl);
				append(sl, '\n'); // scanline ignores newline
				quote_buffer(sl, c)?;
				bufio::flush(c.out)?;
			case io::EOF =>
				break;
			};
		};
	case false =>
		let buf: []u8 = io::drain(c.in)?;
		defer free(buf);
		quote_buffer(buf, c)?;
	};
};

// Lists all macros present.
fn macros() void = {
	let synopsis_mods = fmt::modifiers {
		padding = fmt::padding::ALIGN_LEFT,
		width = 0, // To be updated to length of longest element
		...
	};

	let alphabetized_info: []*macro::macro = [];

	for (let i = 0z; i < len(macro::macros); i += 1) {
		let n = sort::rbisect(
			alphabetized_info: []void,
			size(*macro::macro),
			&macro::macros[i]: *void,
			&macro::compare,
		);
		insert(alphabetized_info[n], &macro::macros[i]);
	};

	for (let i = 0z; i < len(alphabetized_info); i += 1) {
		let (synopsis, description) = alphabetized_info[i].info;
		// TODO: format so that synopises are left aligned, see
		// synopsis_mods
		fmt::printfln("{} - {}", synopsis, description)!;
	};
};

// Can be re-enabled with the -z option.
@init fn disable_logger() void = {
	if (os::getenv("EATON_LOG") is void) {
		log::setlogger(log::silent);
	};
};

export fn main() void = {
	const cmd = getopt::parse(os::args,
		"reads text from stdin and processes it for macros",
		('i', "quote text", "define custom start quote (default: ``)"),
		('o', "quote text", "define custom end quote (default: '')"),
		('l', "read stdin line-by-line instead of all at once"),
		('m', "don't read input for macros; instead, list and describe all of th e macros present"),
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
		in = os::stdin,
		out = os::stdout,
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
		case 'm' =>
			macros();
			os::exit(os::status::SUCCESS);
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
