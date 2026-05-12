# The docs site has exactly one job: parse the latest ruby-sfml gem
# with RDoc and ship the HTML output to Netlify. We pull the gem
# from RubyGems (not the GitHub repo) so the docs always match the
# **published** release — what users actually `gem install`.
#
# Note: ruby-sfml itself dynamically links libcsfml at load time.
# RDoc only parses sources, never loads the gem, so we don't need
# libcsfml on the Netlify build image.

source "https://rubygems.org"

gem "ruby-sfml"   # pinned-by-default to the latest released version
gem "rdoc",  "~> 6.10"
