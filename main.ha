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
			match (bufio::read_line(c.in)?) {
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

// Why? In macros() we only need to copy a (smaller) *macro::macro than a
// macro::macro. But for that, sort::rbisect requires a **macro::macro.
// So this is a helper function to compare **macro::macro which then calls
// macro::compare.
fn macro_ptr_compare(a: const *opaque, b: const *opaque) int = {
	return macro::compare(*(a: **macro::macro), *(b: **macro::macro));
};

// Lists all macros present.
fn macros(h: io::handle) (io::error | void) = {
	let synopsis_mods = &fmt::modifiers {
		padding = fmt::padding::ALIGN_LEFT,
		width = 0, // To be updated to length of longest element
		...
	};

	let alphabetized_info: []*macro::macro = [];
	defer free(alphabetized_info);

	for (let i = 0z; i < len(macro::macros); i += 1) {
		let macro_ptr: *macro::macro = &macro::macros[i];
		let n = sort::rbisect(
			alphabetized_info,
			size(*macro::macro),
			&macro_ptr,
			&macro_ptr_compare,
		);

		insert(alphabetized_info[n], macro_ptr);
		if (synopsis_mods.width < len(alphabetized_info[n].info.0)) {
			synopsis_mods.width =
				len(alphabetized_info[n].info.0): uint;
		};
	};

	for (let i = 0z; i < len(alphabetized_info); i += 1) {
		let (synopsis, description) = alphabetized_info[i].info;
		log::printfln("{%}  {}", synopsis, synopsis_mods, description);
		fmt::fprintfln(h, "{%}  {}",
			synopsis, synopsis_mods, description,
		)?;
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
				writer = &io::writeall,
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
			macros(c.out)!;
			os::exit(os::status::SUCCESS);
		case 'z' =>
			log::setlogger(log::default);
		case =>
			abort("unreachable");
		};
	};

	match (run(&c)) {
	case let e: io::error =>
		log::println("io::error:", io::strerror(e));
	case void =>
		void;
	};
};
