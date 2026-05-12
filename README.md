# ruby-sfml-doc

Hosts the [ruby-sfml](https://github.com/sOM2H/ruby-sfml) HTML
documentation. **The HTML in `public/` is checked into git** —
Netlify serves it as-is without running Ruby.

## Why pre-rendered + committed

`ruby-sfml` is a C-extension gem (links libcsfml). Netlify's
build image has neither libcsfml nor its dev headers, so a
Netlify-side `bundle install ruby-sfml` fails at extconf time.
Building locally where the toolchain already exists, then
committing the static output, sidesteps the whole problem and
makes the deploy trivial.

It also means every doc change shows up as a reviewable diff in
a PR: "we changed the `Color` page" is visible at the byte level.

## Layout

```
.
├── netlify.toml     # publish = public, command = ""
├── public/          # ★ tracked HTML — what Netlify serves
└── README.md
```

The build script lives in the **main** ruby-sfml repo at
[`script/build-docs.sh`](https://github.com/sOM2H/ruby-sfml/blob/main/script/build-docs.sh).
It writes into this repo's `public/`.

## Updating the docs after a ruby-sfml release

From the parent directory that contains both checkouts:

```sh
cd ruby-sfml
script/build-docs.sh

cd ../ruby-sfml-doc
git add public/
git commit -m "Rebuild docs for ruby-sfml X.Y.Z.W"
git push
```

Netlify auto-deploys on every push to `main` — usually live
within ~30s because there's nothing to build, just static files
to upload.

## Local preview

```sh
cd ruby-sfml
script/build-docs.sh --serve     # build + open index.html
```

## Optional drift check

`script/build-docs.sh --check` rebuilds into a tmp dir and diffs
against the committed `public/`. Exits non-zero if anything's
out of sync — useful as a pre-push hook in the main `ruby-sfml`
repo to catch "shipped a release without rebuilding the docs":

```sh
# ruby-sfml/.git/hooks/pre-push
#!/usr/bin/env bash
"$(git rev-parse --show-toplevel)/script/build-docs.sh" --check
```

## How `public/` is rendered

RDoc reads `.rdoc_options` from the **ruby-sfml** source tree
(title, markup, template, excludes). To change the rendered
look, edit `ruby-sfml/.rdoc_options`, rebuild here, push. Doc
config and doc content stay versioned together.
