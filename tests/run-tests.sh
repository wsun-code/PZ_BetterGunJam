#!/usr/bin/env bash
set -euo pipefail

TEST_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
MOD_DIR=$(realpath "$TEST_DIR/..")
GAME_DIR=$(realpath "$MOD_DIR/../ProjectZomboid")
RUNNER="$TEST_DIR/RunKahlua.java"
SUPPORT="$TEST_DIR/support.lua"
NATIVE_MOD_OPTIONS="$GAME_DIR/media/lua/client/PZAPI/ModOptions.lua"
MOD_SCRIPT=$(realpath "${1:-$MOD_DIR/42/media/lua/shared/ZZBetterGunJam.lua}")
CLIENT_OPTIONS=$(realpath "${2:-$MOD_DIR/42/media/lua/client/ZZBetterGunJamOptions.lua}")
TESTS="$TEST_DIR/ZZbetterGunJam_test.lua"

if ! command -v javac >/dev/null 2>&1; then
    echo "A JDK with javac is required to compile the Kahlua test runner." >&2
    exit 1
fi

BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT
javac -d "$BUILD_DIR" "$RUNNER"

# Kahlua loads stdlib.lua relative to the process directory, and the game JAR
# targets the bundled JRE. Compile with the workstation JDK, then execute with
# the game JRE from the game root.
if [[ -x "$GAME_DIR/jre64/bin/java.exe" ]]; then
    if ! command -v wslpath >/dev/null 2>&1; then
        echo "Windows Project Zomboid requires wslpath to run these tests." >&2
        exit 1
    fi

    GAME_WINDOWS=$(wslpath -w "$GAME_DIR")
    BUILD_WINDOWS=$(wslpath -w "$BUILD_DIR")
    SUPPORT_WINDOWS=$(wslpath -w "$SUPPORT")
    NATIVE_MOD_OPTIONS_WINDOWS=$(wslpath -w "$NATIVE_MOD_OPTIONS")
    MOD_SCRIPT_WINDOWS=$(wslpath -w "$MOD_SCRIPT")
    CLIENT_OPTIONS_WINDOWS=$(wslpath -w "$CLIENT_OPTIONS")
    TESTS_WINDOWS=$(wslpath -w "$TESTS")

    (
        cd "$GAME_DIR"
        "$GAME_DIR/jre64/bin/java.exe" \
            -cp "$BUILD_WINDOWS;$GAME_WINDOWS\\projectzomboid.jar" \
            RunKahlua \
            "$SUPPORT_WINDOWS" \
            "$NATIVE_MOD_OPTIONS_WINDOWS" \
            "$MOD_SCRIPT_WINDOWS" \
            "$CLIENT_OPTIONS_WINDOWS" \
            "$TESTS_WINDOWS"
    )
elif [[ -x "$GAME_DIR/jre64/bin/java" ]]; then
    (
        cd "$GAME_DIR"
        "$GAME_DIR/jre64/bin/java" \
            -cp "$BUILD_DIR:$GAME_DIR/projectzomboid.jar" \
            RunKahlua \
            "$SUPPORT" \
            "$NATIVE_MOD_OPTIONS" \
            "$MOD_SCRIPT" \
            "$CLIENT_OPTIONS" \
            "$TESTS"
    )
else
    echo "Project Zomboid's bundled Java runtime was not found under $GAME_DIR/jre64/bin." >&2
    exit 1
fi
