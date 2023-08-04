.POSIX:

eaton: main.ha macro/*.ha
	hare build

check:
	hare test

clean:
	rm eaton

.PHONY: check clean
