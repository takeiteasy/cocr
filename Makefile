default:
	$(CC) cocr.m -framework Carbon -framework Cocoa -framework Vision -o cocr

install: default
	mv cocr /usr/local/bin

.PHONY: default
