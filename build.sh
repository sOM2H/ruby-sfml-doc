#!/usr/bin/env bash
# Regenerate the ruby-sfml HTML docs in ./public from the sibling
# ../ruby-sfml/ source tree, ready to commit + push.
#
# Why local-and-commit rather than build-on-Netlify: ruby-sfml is a
# C-extension gem (links libcsfml). Netlify's build image has neither
# libcsfml nor the dev headers, so `gem install ruby-sfml` fails at
# extconf time. We build where the toolchain already lives — your
# machine — and check the static HTML into git. Netlify serves it
# without ever touching Ruby.
#
# Usage:
#   ./build.sh              build into ./public
#   ./build.sh --serve      build, then open index.html in a browser
#   ./build.sh --check      build into a tmp dir + diff against ./public
#                           (handy in CI / pre-commit hooks)
#
# Assumes ../ruby-sfml/ exists as a sibling. If your checkout lives
# elsewhere, override:
#
#   RUBY_SFML_SRC=/path/to/ruby-sfml ./build.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${RUBY_SFML_SRC:-$ROOT/../ruby-sfml}"
OUT="$ROOT/public"

if [[ ! -d "$SRC/lib/sfml" ]]; then
  echo "error: ruby-sfml source not found at $SRC" >&2
  echo "       set RUBY_SFML_SRC=/path/to/ruby-sfml to override." >&2
  exit 1
fi

VERSION="$(ruby -I "$SRC/lib" -r sfml/version -e 'print SFML::VERSION')"
echo "==> building ruby-sfml $VERSION docs from $SRC"

# `--check` builds into a tmp dir and diffs file lists. Useful in a
# pre-commit hook to catch "docs were changed but not regenerated".
TARGET="$OUT"
if [[ "${1:-}" == "--check" ]]; then
  TARGET="$(mktemp -d)"
fi

rm -rf "$TARGET"

# RDoc reads $SRC/.rdoc_options for project-wide knobs (markup,
# excludes, template). We override --title (to carry the version)
# and --output (to land where Netlify publishes).
(cd "$SRC" && rdoc \
  --title "ruby-sfml ${VERSION}" \
  --output "$TARGET" \
  README.md CHANGELOG.md LICENSE.txt lib/) 2>&1 | tail -8

# A Netlify-friendly fallback redirect from / → /index.html.
cat >"$TARGET/_redirects" <<'EOF'
/  /index.html  200
EOF

# Build provenance so each deployed site lists what it shows.
cat >"$TARGET/BUILD_INFO.txt" <<EOF
ruby-sfml docs site
Built:   $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Version: ${VERSION}
Source:  ${SRC}
Repo:    https://github.com/sOM2H/ruby-sfml
EOF

echo "==> output in $TARGET ($(du -sh "$TARGET" | cut -f1))"

if [[ "${1:-}" == "--check" ]]; then
  # `created.rid` and `BUILD_INFO.txt` carry a build timestamp, so
  # they always differ between runs. Diff everything else.
  drift="$(diff -rq -x created.rid -x BUILD_INFO.txt "$OUT" "$TARGET" 2>&1 || true)"
  if [[ -n "$drift" ]]; then
    echo "::: docs in ./public are out of date with the gem source."
    echo "::: run ./build.sh and commit the result."
    echo "$drift" | head -20 >&2
    rm -rf "$TARGET"
    exit 1
  fi
  rm -rf "$TARGET"
  echo "==> ./public matches a fresh build."
fi

if [[ "${1:-}" == "--serve" ]]; then
  if command -v xdg-open >/dev/null; then
    xdg-open "$TARGET/index.html"
  elif command -v open >/dev/null; then
    open "$TARGET/index.html"
  else
    echo "(no opener found; open $TARGET/index.html manually)"
  fi
fi
