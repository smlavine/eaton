// eaton:+test.ha (https://sr.ht/~smlavine/eaton)
// Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>
// SPDX-License-Identifier: GPL-3.0-or-later

use bufio;
use io;
use os;
use strings;
use strio;

use macro;

let default_quotes: [2]quote = [
	quote {
		text = ['`', '`'],
		writer = &io::write,
	},
	quote {
		text = ['\'', '\''],
		writer = &macro::process,
	},

];

@test fn no_quotes() void = {
	const input = "Hello, my name is Bob.";
	const c = config {
		quotes = default_quotes,
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == input);
};

@test fn quotes() void = {
	const input = "Hello, my name is ``Bob!''";
	const c = config {
		quotes = default_quotes,
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Hello, my name is Bob!");
};

@test fn empty_quotes() void = {
	const input = "Text and ``''more text";
	const c = config {
		quotes = default_quotes,
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Text and more text");
};

@test fn no_start_quote() void = {
	const input = "Text and ''more text";
	const c = config {
		quotes = default_quotes,
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Text and ''more text");
};

@test fn no_end_quote() void = {
	const input = "Text and ``more text";
	const c = config {
		quotes = default_quotes,
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Text and more text");
};

@test fn escape_start_quote() void = {
	const input = "Text and ````''more text";
	const c = config {
		quotes = default_quotes,
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Text and ``more text");
};

@test fn escape_substring_start_quote() void = {
	const input = "Text and `````''more text";
	const c = config {
		quotes = default_quotes,
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Text and ```more text");
};

@test fn custom_quotes_no_quotes() void = {
	const input = "Text and more text";
	const c = config {
		quotes = [
			quote {
				text = strings::toutf8("<quote>"),
				writer = &io::write,
			}, 
			quote {
				text = strings::toutf8("</quote>"),
				writer = &macro::process,
			},
		],
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Text and more text");
};

@test fn quote_with_macro() void = {
	const input = "Text and ``upper!(more text)''";
	const c = config {
		quotes = default_quotes,
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Text and MORE TEXT");
};

@test fn custom_quotes() void = {
	const input = "Text and <quote>more text</quote>";
	const c = config {
		quotes = [
			quote {
				text = strings::toutf8("<quote>"),
				writer = &io::write,
			}, 
			quote {
				text = strings::toutf8("</quote>"),
				writer = &macro::process,
			},
		],
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr == "Text and more text");
};

@test fn custom_quotes_no_start_quote() void = {
	const input = "Text and </quote>more text";
	const c = config {
		quotes = [
			quote {
				text = strings::toutf8("<quote>"),
				writer = &io::write,
			}, 
			quote {
				text = strings::toutf8("</quote>"),
				writer = &macro::process,
			},
		],
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr ==  "Text and </quote>more text");
};

@test fn custom_quotes_no_end_quote() void = {
	const input = "Text and <quote>more text";
	const c = config {
		quotes = [
			quote {
				text = strings::toutf8("<quote>"),
				writer = &io::write,
			}, 
			quote {
				text = strings::toutf8("</quote>"),
				writer = &macro::process,
			},
		],
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr ==  "Text and more text");
};

@test fn custom_quotes_no_end_quote() void = {
	const input = "Text and <quote>more text";
	const c = config {
		quotes = [
			quote {
				text = strings::toutf8("<quote>"),
				writer = &io::write,
			}, 
			quote {
				text = strings::toutf8("</quote>"),
				writer = &macro::process,
			},
		],
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr ==  "Text and more text");
};

@test fn custom_quotes_with_macro() void = {
	const input = "Text and <quote>upper!(MORE TEXT)</quote>";
	const c = config {
		quotes = [
			quote {
				text = strings::toutf8("<quote>"),
				writer = &io::write,
			}, 
			quote {
				text = strings::toutf8("</quote>"),
				writer = &macro::process,
			},
		],
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr ==  "Text and MORE TEXT");
};

@test fn same_start_and_end_quote() void = {
	const input = `Text and "upper!(MORE TEXT)"`;
	const c = config {
		quotes = [
			quote {
				text = strings::toutf8(`"`),
				writer = &io::write,
			}, 
			quote {
				text = strings::toutf8(`"`),
				writer = &macro::process,
			},
		],
		in = &bufio::fixed(strings::toutf8(input), io::mode::READ),
		out = &strio::dynamic(),
		...
	};
	defer io::close(c.out): void;
	run(&c)!;
	let outstr = strio::string(c.out as *io::stream: *strio::stream);

	assert(outstr ==  "Text and MORE TEXT");
};