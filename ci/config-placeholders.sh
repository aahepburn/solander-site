#!/bin/bash
# A published page must not carry a placeholder.
#
# This exists because of one link. The Solander pricing page shipped with
# `href="PADDLE_CHECKOUT_URL_PERSONAL"` on the Buy button: a live page, on a domain Paddle
# reviews, with a Buy button that resolves to a relative path and 404s. Every other check
# passed — the markup balanced, nothing loaded from another origin, the text was all there.
#
# So the checkout URL is a config value with exactly one home (index.html, marked
# AT LAUNCH) and this refuses to deploy while it is unfilled.
set -uo pipefail
cd "$(dirname "$0")/.."

# Markers that mean "somebody has not finished". Matched on published pages only.
PATTERNS='PADDLE_CHECKOUT_URL|REPLACE-|PLACEHOLDER|example\.invalid|TODO_BEFORE_LAUNCH'

status=0
while IFS= read -r file; do
  # HTML comments are blanked first, keeping their newlines so line numbers still point at the
  # real file. A CONFIG comment naming the marker it is telling you to replace is not a
  # failure; a live href is. Matching line by line got this wrong — the give-away was this
  # gate failing on its own instructions.
  hits=$(perl -0pe 's{<!--.*?-->}{ $& =~ s/[^\n]/ /gr }gse' "$file" \
         | grep -nE "$PATTERNS" || true)
  if [ -n "$hits" ]; then
    echo "FAIL $file still carries a placeholder:" >&2
    sed 's/^/     /' <<<"$hits" >&2
    status=1
  fi
done < <(find . -name '*.html' -not -path './.git/*')

if [ $status -eq 0 ]; then
  echo "ok   no placeholders on any published page"
else
  echo "" >&2
  echo "     The Buy button needs the Paddle checkout URL. It is marked AT LAUNCH (Paddle)" >&2
  echo "     in index.html, and that is the only place it appears." >&2
fi
exit $status
