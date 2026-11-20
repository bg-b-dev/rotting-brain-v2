#!/bin/sh
# Prints "<Service>.<Name> <bytes>" for every script under src/, to compare with #Source in Studio.
cd "$(dirname "$0")/src" && for f in */*.luau; do n=$(basename "$f" | sed -E 's/(\.server|\.client)?\.luau$//'); echo "$(dirname "$f").$n $(wc -c < "$f" | tr -d ' ')"; done
