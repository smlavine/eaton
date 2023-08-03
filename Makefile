.POSIX:

eaton: main.ha macro/*.ha
	hare build

clean:
	rm eaton

.PHONY: clean
