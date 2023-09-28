# Irmin Bookmarks

`irmin-bookmarks` is an experimental browser extension (tested on Firefox) that
uses `irmin-client` and `irmin-server` to store bookmarks in a local git
repository.

## Building

This currently depends on unreleased code:

```sh
opam pin add irmin-server https://github.com/metanivek/irmin.git#irmin-server/improves --with-version=3.8.0 -y
```

```sh
opam pin add irmin-client https://github.com/metanivek/irmin.git#irmin-server/improves --with-version=3.8.0 -y
```

Once you have dependencies (TODO have opam files) installed,

```sh
make build
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
