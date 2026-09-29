#!/bin/bash
# A Download button links the DMG itself, so a click downloads the app rather than opening a
# GitHub page to hunt through.
#
# Both apps release from one repository, Quiet-Signals-Lab/solander, tagged pdf-v<version> and
# desk-v<version>. So `releases/latest` cannot mean either app, and each button names its exact
# file instead. That file changes with every release, and so does the app's appcast: this keeps
# them the same file. Every live link into the release repository must be the newest enclosure
# (the first <item>) in that app's appcast.
set -uo pipefail
cd "$(dirname "$0")/.."

repo='https://github.com/Quiet-Signals-Lab/solander/releases/download'
# HTML and XML comments blanked first, as in config-placeholders.sh: an AT LAUNCH comment
# showing the link to paste is not a live link.
uncommented() { perl -0pe 's{<!--.*?-->}{ $& =~ s/[^\n]/ /gr }gse' "$1"; }

status=0
# The appcasts are read below, and Sparkle refuses one that is not well-formed XML.
for feed in */appcast.xml; do
  python3 -c 'import sys, xml.etree.ElementTree as E; E.parse(sys.argv[1])' "$feed" 2>/dev/null \
    || { echo "FAIL $feed is not well-formed XML; Sparkle would reject it" >&2; status=1; }
done
while IFS= read -r file; do
  for link in $(uncommented "$file" | grep -oE 'https://github\.com/Quiet-Signals-Lab/[^"]*' | sort -u); do
    case "$link" in
      "$repo"/pdf-v*) app=pdf ;;
      "$repo"/desk-v*) app=desk ;;
      *)
        echo "FAIL $file links $link" >&2
        echo "     Download links name the DMG: $repo/<pdf|desk>-v<version>/<file>.dmg" >&2
        status=1
        continue ;;
    esac
    newest=$(uncommented "$app/appcast.xml" | grep -oE 'url="[^"]+"' | head -1 | sed 's/^url="//; s/"$//')
    if [ "$link" != "$newest" ]; then
      echo "FAIL $file links $link" >&2
      echo "     but the newest release in $app/appcast.xml is ${newest:-(none)}" >&2
      status=1
    fi
  done
done < <(find . -name '*.html' -not -path './.git/*')

[ $status -eq 0 ] && echo "ok   every Download link is the newest DMG in its app's appcast"
exit $status
