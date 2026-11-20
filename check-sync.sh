#!/bin/sh
# Prints "<Service>.<Name> <bytes> <checksum>" for every script under src/; Studio prints the same pair after a push.
cd "$(dirname "$0")/src" && python3 -c '
import sys, os, re
for f in sorted(sys.argv[1:]):
    b = open(f, "rb").read(); h = 0
    for c in b: h = (h * 31 + c) % 2147483647
    print(os.path.dirname(f) + "." + re.sub(r"(\.server|\.client)?\.luau$", "", os.path.basename(f)), len(b), h)
' */*.luau
