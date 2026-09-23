#!/bin/bash
# Every page footer says "This site does not use cookies or tracking technologies", and the
# Solander privacy notice says "no embedded third-party content and no fonts loaded from
# elsewhere". Paddle's domain review reads those pages. A claim on a public page needs a
# check behind it: one added web font, embedded video or CDN script makes it false, silently.
#
# Links to other sites are fine — the privacy notice has to link Paddle's own. What is
# checked is anything the browser *loads*.
#
# This repo is four hand-written pages, so nothing is skipped.
set -uo pipefail
cd "$(dirname "$0")/.."

status=0
while IFS= read -r file; do
  # src=, and href= only on <link>, which is the loading kind.
  loaded=$(grep -oiE '(src=|<link[^>]*href=)"(https?:)?//[^"]+"' "$file" \
           | sed 's/.*"\(.*\)"/\1/' | grep -v 'quietsignalslab\.com' | sort -u || true)
  if [ -n "$loaded" ]; then
    echo "FAIL $file loads from another origin:" >&2
    echo "$loaded" | sed 's/^/     /' >&2
    status=1
  fi
  for tracker in google-analytics googletagmanager 'gtag(' plausible fathom hotjar segment.com facebook.net; do
    if grep -qiF "$tracker" "$file"; then
      echo "FAIL $file references $tracker" >&2
      status=1
    fi
  done
done < <(find . -name '*.html' -not -path './.git/*')

[ $status -eq 0 ] && echo "ok   no page loads anything from another origin"
exit $status
