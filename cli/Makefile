PREFIX ?= $(HOME)/.local/bin

.PHONY: all install clean

all:
	go build -o jira-cli ./cmd/jira/
	go build -o wiki-cli ./cmd/wiki/

install: all
	mkdir -p $(PREFIX)
	cp jira-cli wiki-cli $(PREFIX)/

clean:
	rm -f jira-cli wiki-cli
