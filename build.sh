#!/usr/bin/env bash
# Build the ruby-sfml HTML docs into ./public. Designed to be run
# both locally and from Netlify's build pipeline.
#
#   ./build.sh           # build into ./public
#   ./build.sh --serve   # build, then open in a browser
#
# Pipeline:
#   1. bundle install fetches the latest ruby-sfml + rdoc gems
#   2. `gem unpack` extracts ruby-sfml-X.Y.Z.gem into ./.gem-src
#   3. We rdoc the unpacked sources into ./public using the gem's
#      OWN .rdoc_options (it ships in the gem files glob)
#
# This setup means the docs site never needs to be bumped when the
# gem releases — Netlify rebuilds nightly (or on demand via the
# build hook URL) and picks up whatever's current on RubyGems.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

PUBLIC_DIR="$ROOT/public"
SRC_DIR="$ROOT/.gem-src"

echo "==> bundle install"
bundle install --quiet

echo "==> fetching latest ruby-sfml from RubyGems"
rm -rf "$SRC_DIR"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
gem fetch ruby-sfml --quiet
gem unpack ruby-sfml-*.gem >/dev/null
mv ruby-sfml-*/ src
cd "$ROOT"

VERSION="$(ls "$SRC_DIR"/ruby-sfml-*.gem | sed -E 's|.*/ruby-sfml-([0-9.]+)\.gem|\1|')"
echo "==> using ruby-sfml ${VERSION}"

echo "==> running rdoc"
rm -rf "$PUBLIC_DIR"
cd "$SRC_DIR/src"

# The unpacked gem ships with .rdoc_options (markup, excludes,
# template, etc.). We override only the title (so it carries the
# version that's being built) and the output dir (so it lands in
# Netlify's publish dir).
bundle exec --gemfile="$ROOT/Gemfile" rdoc \
  --title "ruby-sfml ${VERSION}" \
  --output "$PUBLIC_DIR" \
  README.md CHANGELOG.md LICENSE.txt lib/

cd "$ROOT"

# Drop a top-level redirect so https://<site>/ lands on index.html
# rather than the file listing. RDoc already creates index.html, but
# we add a fallback _redirects file for Netlify edge.
cat >"$PUBLIC_DIR/_redirects" <<'EOF'
/  /index.html  200
EOF

# Drop a small build-info file so it's clear what's deployed.
cat >"$PUBLIC_DIR/BUILD_INFO.txt" <<EOF
ruby-sfml docs site
Built: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
gem version: ${VERSION}
source: https://rubygems.org/gems/ruby-sfml/versions/${VERSION}
repo:   https://github.com/sOM2H/ruby-sfml
EOF

echo "==> done — output in $PUBLIC_DIR (~$(du -sh "$PUBLIC_DIR" | cut -f1))"

if [[ "${1:-}" == "--serve" ]]; then
  if command -v xdg-open >/dev/null; then
    xdg-open "$PUBLIC_DIR/index.html"
  elif command -v open >/dev/null; then
    open "$PUBLIC_DIR/index.html"
  else
    echo "(no opener found; open $PUBLIC_DIR/index.html manually)"
  fi
fi
