#!/bin/bash
# Unclosed <style> makes a page render blank while every content check still passes.
#
# That is not hypothetical: solander/terms.html, solander/refunds.html and
# privacy/solander.html all shipped with a <style> block truncated mid-rule. The HTML was
# in the source, curl returned 200, the text was all present — and the browser swallowed
# the entire document as CSS. It was found by a person clicking the link, which is the one
# check that should never be the first to fail.
set -uo pipefail
cd "$(dirname "$0")/.."

status=0
while IFS= read -r file; do
  for tag in style script head body html; do
    open=$(grep -o "<$tag[ >]" "$file" | wc -l | tr -d ' ')
    close=$(grep -o "</$tag>" "$file" | wc -l | tr -d ' ')
    if [ "$open" != "$close" ]; then
      echo "FAIL $file: <$tag> x$open, </$tag> x$close" >&2
      status=1
    fi
  done
  # Braces inside the file should balance; an unclosed CSS rule is the other half of the bug.
  o=$(tr -cd '{' < "$file" | wc -c | tr -d ' ')
  c=$(tr -cd '}' < "$file" | wc -c | tr -d ' ')
  if [ "$o" != "$c" ]; then
    echo "FAIL $file: { x$o, } x$c — unclosed CSS rule?" >&2
    status=1
  fi
done < <(find . -name '*.html' -not -path './.git/*')

[ $status -eq 0 ] && echo "ok   every page's tags and braces balance"
exit $status
