#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/android-env.sh"

if [[ ! -x "$godot" || ! -x "$ANDROID_HOME/build-tools/35.0.0/apksigner" || ! -s "$toolchain/debug.keystore" ]]; then
    echo 'Executa primeiro ./scripts/setup-android.sh.' >&2
    exit 1
fi

mkdir -p build
apk="$PWD/build/gravity-junkyard-debug.apk"
temporary="$(mktemp -d "$PWD/build/export.XXXXXXXX")"
trap 'rm -rf -- "$temporary"' EXIT
"$godot" --headless --path "$PWD" --editor --import --quit
"$godot" --headless --path "$PWD" --export-debug Android "$temporary/gravity-junkyard-debug.apk"
"$ANDROID_HOME/build-tools/35.0.0/apksigner" verify "$temporary/gravity-junkyard-debug.apk"
mv -f -- "$temporary/gravity-junkyard-debug.apk" "$apk"
printf 'APK verificado: %s\n' "$apk"
