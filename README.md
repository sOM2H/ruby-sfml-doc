# ruby-sfml-doc

This repo builds the [ruby-sfml](https://github.com/sOM2H/ruby-sfml)
documentation site. **It does not contain any docs of its own** — it
fetches the latest gem from RubyGems on every build and runs RDoc over
the unpacked source.

That way the deployed site always matches whatever's `gem install`-able,
without us having to bump a number every time the library releases.

## Layout

```
.
├── Gemfile          # ruby-sfml + rdoc
├── build.sh         # the whole pipeline
├── netlify.toml     # build/publish config + cache headers
└── public/          # RDoc output — generated, gitignored
```

## How a build runs

1. Netlify (or local) calls `./build.sh`.
2. `bundle install` resolves the latest `ruby-sfml`.
3. `gem fetch ruby-sfml` downloads the released `.gem`.
4. `gem unpack` extracts sources into `./.gem-src/src`.
5. `rdoc` runs against those sources using the project's own
   `.rdoc_options` (ships inside the gem).
6. HTML lands in `./public`, which Netlify publishes.

## Local build

```sh
./build.sh              # build into ./public
./build.sh --serve      # build, then open index.html in a browser
```

You need:
- Ruby 3.2+
- Bundler

You do **not** need CSFML installed on the system — RDoc only parses
the gem's source files; it never `require`s `sfml`.

## Triggering a redeploy after a new gem release

The build doesn't know that ruby-sfml released. Two options:

1. **Manual**: Netlify dashboard → Deploys → "Trigger deploy" →
   "Clear cache and deploy site".
2. **Webhook**: Netlify generates a build-hook URL — POST to it
   from a `release` workflow in the main ruby-sfml repo:

   ```yaml
   on:
     release:
       types: [published]
   jobs:
     redeploy-docs:
       runs-on: ubuntu-latest
       steps:
         - run: curl -X POST -d {} ${{ secrets.NETLIFY_DOCS_BUILD_HOOK }}
   ```

   Save the hook URL as `NETLIFY_DOCS_BUILD_HOOK` in the
   ruby-sfml repo's GitHub secrets.

A nightly cron in `netlify.toml` is **deliberately not** used — Netlify
charges per build minute, and ruby-sfml ships at most weekly. Manual
or release-triggered is the right cadence.

## Customising the rendered output

Anything that affects the **rendered docs** lives inside the gem's
`.rdoc_options` (title, markup, template, excludes). Change it there,
release a new ruby-sfml, redeploy this site. Keeping the config close
to the source means the docs always agree with what the gem author
shipped.

Settings local to this repo (build runner, cache headers, etc.) stay
in `netlify.toml` and `build.sh`.
