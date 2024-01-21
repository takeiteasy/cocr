build:
	$(CC) -Isrc/ src/*.m -framework Carbon -framework Cocoa -o rcmd

app: build
	sh appify.sh -s cocr -n cocr

install: build
	mv cocr /usr/local/bin

install-app: app
	mv cocr.app /Applications

default: build
all: app

.PHONY: build default
