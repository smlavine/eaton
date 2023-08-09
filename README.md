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
Hi there, ``upper!(everyone)''!
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

### Regular expressions

Take care when writing the regular expressions used to match your
macros. Writing a regular expression that always matches (such as
`(.*)`) will crash the program. The Hare regex engine is greedy, so if
matching for text within parens, don't match closing parens in your
capture. Consider a simple, correct regular expression, as defined in
`macro/upper.ha`:

```hare
def UPPER_RE = `upper!\(([^)]*)\)`;
```

The contents of the capture group is what will be provided to the macro
for formatting. Instead of capturing `.*`, we capture `[^)]*`,
preventing the expression from matching beyond what is intended.

For more information on regular expressions, consider reading [the
documentation for the Hare regex module](https:/docs.harelang.org/regex)
or [regex(7)](https://linux.die.net/man/7/regex).

### Modifying state

There is no method of modifying state (i.e. defining macros or setting
variables) from the input of a macro itself; this would increase
implementation complexity considerably. However, the provided macros
`getenv!` and `system!` are enough to interact with the environment
and state can be stored and retrieved from it however you like.
