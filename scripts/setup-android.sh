#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/android-env.sh"

if [[ $(uname -m) != x86_64 ]]; then
    echo 'Este instalador requer Debian Linux x86_64 (amd64).' >&2
    exit 1
fi

scratch="$(mktemp -d)"
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$toolchain/bin" "$ANDROID_HOME/cmdline-tools" "$XDG_CONFIG_HOME/godot" \
    "$XDG_DATA_HOME/godot/export_templates/4.5.1.stable" "$XDG_CACHE_HOME"
touch "$toolchain/.gdignore"

download() {
    curl --fail --silent --show-error --location --retry 3 "$1" -o "$2"
}

release=https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable
if [[ ! -x "$godot" ]]; then
    archive="$scratch/godot.zip"
    download "$release/Godot_v4.5.1-stable_linux.x86_64.zip" "$archive"
    printf '%s  %s\n' 5bccbed65a94b82c7c319fdb15719ee8113a6e503976cc54e16f1c61fe95f3d74e5e40b8449b5bb89ff7f424574c20af01a4f5ef08b389e4dc338b245185b0b9 "$archive" | sha512sum --check
    unzip -q "$archive" -d "$scratch"
    install -m 755 "$scratch/Godot_v4.5.1-stable_linux.x86_64" "$godot"
fi

template="$XDG_DATA_HOME/godot/export_templates/4.5.1.stable/android_debug.apk"
if [[ ! -s "$template" ]]; then
    archive="$scratch/templates.tpz"
    download "$release/Godot_v4.5.1-stable_export_templates.tpz" "$archive"
    printf '%s  %s\n' 8a65c73541184fbcf1a7afedb37c9c15ed0f3babdaafe36ff47ccc515548ac84bc7563ba5b94c253e6085b121ac608b7e03d35dfc0b2c8c690a646a8755b57e5 "$archive" | sha512sum --check
    unzip -q -j "$archive" templates/android_debug.apk -d "$scratch"
    install -m 644 "$scratch/android_debug.apk" "$template"
fi

sdkmanager="$ANDROID_HOME/cmdline-tools/19.0/bin/sdkmanager"
if [[ ! -x "$sdkmanager" ]]; then
    archive="$scratch/android-cli.zip"
    download https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip "$archive"
    printf '%s  %s\n' 5fdcc763663eefb86a5b8879697aa6088b041e70 "$archive" | sha1sum --check
    unzip -q "$archive" -d "$scratch"
    mv -T "$scratch/cmdline-tools" "$ANDROID_HOME/cmdline-tools/19.0"
fi

if [[ ! -x "$ANDROID_HOME/platform-tools/adb" || ! -x "$ANDROID_HOME/build-tools/35.0.0/apksigner" ]]; then
    "$sdkmanager" --sdk_root="$ANDROID_HOME" --install 'platform-tools' 'build-tools;35.0.0'
fi

keystore="$toolchain/debug.keystore"
if [[ ! -s "$keystore" ]]; then
    keytool -genkeypair -keystore "$keystore" -storepass android \
        -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
        -validity 10000 -dname 'CN=Android Debug,O=Android,C=US'
fi
python3 - "$XDG_CONFIG_HOME/godot/editor_settings-4.5.tres" "$JAVA_HOME" "$ANDROID_HOME" "$keystore" <<'PY'
import json
import sys
from pathlib import Path

settings, java, sdk, keystore = sys.argv[1:]
values = {
    "java_sdk_path": java,
    "android_sdk_path": sdk,
    "debug_keystore": keystore,
    "debug_keystore_user": "androiddebugkey",
    "debug_keystore_pass": "android",
}
Path(settings).write_text(
    '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    + "".join(f"export/android/{key} = {json.dumps(value, ensure_ascii=False)}\n" for key, value in values.items()),
    encoding="utf-8",
)
PY
