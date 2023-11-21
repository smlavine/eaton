# [eaton](https://sr.ht/~smlavine/eaton)

A pretty decent macro processor in less than 300 lines of
[Hare](https://harelang.org).

This is still a work in progress, and there are some bugs and features
still being worked on; in particular, nested macros.

## Example usage

```shell-session
$ make
hare build
$ cat input1.txt
Hi there, ``<upper! "everyone"/>''!
$ ./eaton < input1.txt
Hi there, EVERYONE!
```

## Installation

eaton is meant to vendored and extended, not installed like most other
programs. Simply clone this repository where you wish, run `make`, and
you're ready to go. If you are incorporating eaton into an existing
repository, you may prefer to use `git-subtree`:

```shell-session
$ git subtree --squash -P eaton/ add https://git.sr.ht/~smlavine/eaton master
```

## Writing your own macros

To add new macros, simply add a new Hare source file to the `macro`
module. Use the existing macro definitions as examples. Even complex
macros shouldn't take more than ten or twenty lines of your own code.

All of the macros provided with eaton are named like `name!(arguments)`.
But this is just a convention; any macros you write yourself do not have
to follow it.

### Modifying state

There is no method of modifying state (i.e. defining macros or setting
variables) from the input of a macro itself; this would increase
implementation complexity considerably. However, the provided macros
`getenv!` and `system!` are enough to interact with the environment
and state can be stored and retrieved from it however you like.

## Contributing and Copyright

`Copyright (C) 2023 Sebastian LaVine <mail@smlavine.com>`

Licensed under the terms of the [GNU GPL, version 3 or later](https://spdx.org/licenses/GPL-3.0-or-later.html).

Patches? Feedback? Send them to [~smlavine/public-inbox@lists.sr.ht](https://lists.sr.ht/~smlavine/public-inbox).
