# Loaded by the Android setup and build scripts.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
toolchain="$PWD/.toolchain"
godot="$toolchain/bin/godot"
export ANDROID_HOME="$toolchain/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export XDG_CONFIG_HOME="$toolchain/config"
export XDG_DATA_HOME="$toolchain/share"
export XDG_CACHE_HOME="$toolchain/cache"
if [[ -z ${JAVA_HOME:-} ]]; then
    for jdk in /usr/lib/jvm/java-17-openjdk-*; do
        if [[ -x "$jdk/bin/keytool" ]]; then
            JAVA_HOME="$jdk"
            break
        fi
    done
    if [[ -z ${JAVA_HOME:-} ]] && command -v java >/dev/null; then
        JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
    fi
fi
if [[ ! -x "${JAVA_HOME:-}/bin/keytool" ]]; then
    echo 'Instala Java com keytool ou define JAVA_HOME para essa instalação.' >&2
    exit 1
fi
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"
