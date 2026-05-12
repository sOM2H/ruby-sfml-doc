# ruby-sfml-doc

Hosts the [ruby-sfml](https://github.com/sOM2H/ruby-sfml) HTML
documentation. **The HTML in `public/` is checked into git** —
Netlify serves it as-is without running Ruby.

## Why pre-rendered + committed

`ruby-sfml` is a C-extension gem (links libcsfml). Netlify's build
image has neither libcsfml nor its dev headers, so a Netlify-side
`bundle install ruby-sfml` fails at extconf time. Building locally
where the toolchain already exists, then committing the static
output, sidesteps the whole problem and makes the deploy trivial.

It also means every commit shows up as a reviewable diff: "we
changed the `Color` page" is visible in a PR.

## Layout

```
.
├── build.sh         # local-only: regenerate public/ from sibling
├── netlify.toml     # publish = public, command = ""
├── public/          # ★ tracked HTML — what Netlify serves
└── README.md        # this file
```

## Updating the docs after a ruby-sfml release

From the directory that contains both checkouts:

```sh
cd ruby-sfml-doc
./build.sh                        # regenerates ./public from ../ruby-sfml/
git add public/
git commit -m "Rebuild docs for ruby-sfml X.Y.Z.W"
git push
```

Netlify auto-deploys on every push to `main` — usually live within
~30s of `git push` because there's nothing to build.

If your checkout layout is different from the default (sibling
`../ruby-sfml`), override:

```sh
RUBY_SFML_SRC=/elsewhere/ruby-sfml ./build.sh
```

## Local preview

```sh
./build.sh --serve     # builds + opens public/index.html
```

## Optional: drift check in pre-commit

`./build.sh --check` rebuilds into a tmp dir and diffs against
the committed `public/`. Exits non-zero if anything's out of sync
— useful as a pre-push hook in the main `ruby-sfml` repo:

```sh
# ~/Development/sfml/ruby-sfml/.git/hooks/pre-push
#!/usr/bin/env bash
cd "$(git rev-parse --show-toplevel)/../ruby-sfml-doc"
./build.sh --check || { echo "docs out of date — run build.sh in ruby-sfml-doc"; exit 1; }
```

## What gets rendered

RDoc reads `.rdoc_options` from the **ruby-sfml** source tree (it
ships in the gem too). To change title, theme, excludes, etc.,
edit `ruby-sfml/.rdoc_options` and rebuild. Keeping the config
co-located with the source means the docs config and the docs are
versioned together.
