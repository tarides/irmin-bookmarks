all: build

clean:
	dune clean
	rm -rf irmin-bookmarks-extension

build:
	dune build --profile=release
	cp -Lr _build/install/default/lib/irmin-bookmarks-extension irmin-bookmarks-extension
