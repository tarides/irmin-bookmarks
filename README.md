# Irmin Bookmarks

`irmin-bookmarks` is an experimental browser extension (tested on Firefox) that
uses `irmin-client` and `irmin-server` to store bookmarks in a local git
repository.

## Building

Install dependencies

```sh
opam switch create . --deps-only -y ocaml-base-compiler.4.14.0
```

Build

```sh
make clean build
```

Now the extension will be in `irmin-bookmarks-extension`.

You can [temporarily
install](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Your_first_WebExtension#installing)
the extension in Firefox to test it out.

You will need to have the server running for it to work:

```sh
dune exec server/main.exe # or ./_build/install/default/bin/irmin-bookmarks
```

By default, the server runs on port 4242 and stores data at `$HOME/.irmin-bookmarks`.
