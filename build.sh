#!/bin/bash
# Build Terminale: terminale.so plus the precompressed static files.
#
#   ./build.sh            optimized build
#   ./build.sh --fast     quick unoptimized build (for development)
#   ./build.sh --test     build, then run the test suite
#   ./build.sh --clean    remove what the build produced
#
# Needs the Strada compiler (strada) and the C headers for OpenSSL, libcrypt
# and PTYs. Running it needs an installed Cannoli (see ./start.sh).
set -e
cd "$(dirname "$0")"
STRADA="${STRADA:-strada}"
FLAGS=""
RUN_TESTS=0
for arg in "$@"; do
    case "$arg" in
        --fast) FLAGS="-O0 --no-lto" ;;
        --test) RUN_TESTS=1 ;;
        --clean) rm -f terminale.so static/*.gz; echo "Cleaned."; exit 0 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "build.sh: unknown option $arg (try --help)" >&2; exit 2 ;;
    esac
done

fail() { echo "build.sh: $*" >&2; exit 1; }
command -v "$STRADA" >/dev/null || fail "the Strada compiler ('$STRADA') was not found.
  Install Strada (https://github.com/strada-lang/strada), or set STRADA=/path/to/strada."
command -v gzip >/dev/null || fail "gzip was not found."
missing=""
for h in openssl/hmac.h crypt.h pty.h; do
    [ -f "/usr/include/$h" ] || [ -f "/usr/local/include/$h" ] || ls /usr/include/*/"$h" >/dev/null 2>&1 || missing="$missing $h"
done
[ -z "$missing" ] || fail "missing C headers:$missing
  Debian/Ubuntu: sudo apt install build-essential libssl-dev libcrypt-dev
  Fedora/RHEL:   sudo dnf install gcc openssl-devel libxcrypt-devel"

echo "Building terminale.so ..."
if ! "$STRADA" $FLAGS --shared terminale.strada -o terminale.so -l util -l crypt -l crypto > .build.log 2>&1; then
    cat .build.log >&2
    rm -f .build.log
    fail "compilation failed (output above)."
fi
rm -f .build.log
for f in static/xterm.js static/addon-webgl.js static/addon-fit.js static/addon-web-links.js static/addon-search.js \
         static/xterm.css static/app.js static/app.css static/themes.js; do
    gzip -9 -k -f "$f"
done
echo "Built $(pwd)/terminale.so"

if command -v cannoli >/dev/null; then
    echo "Cannoli: $(command -v cannoli)"
else
    echo "Note: 'cannoli' is not installed yet -- needed to run it (https://github.com/strada-lang/cannoli)."
fi
if [ "$RUN_TESTS" = 1 ]; then
    echo
    exec bash t/test.sh
fi
echo "Start it with:  ./start.sh -u $(id -un)      (./start.sh --help for options)"
