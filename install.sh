#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="kuncung38"
REPO_NAME="moonlighter-dualsense-analog-mod"
WIN_ZIP_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest/download/Moonlighter-DualSense-Analog-Mod.zip"
UNIX_BEPINEX_URL="https://github.com/BepInEx/BepInEx/releases/download/v5.4.22/BepInEx_unix_5.4.22.0.zip"

echo ""
echo "====================================================="
echo "  Moonlighter - DualSense & 360 Analog Movement Mod  "
echo "           SteamOS / Linux / macOS Installer         "
echo "====================================================="
echo ""

OS_NAME="$(uname -s)"

find_moonlighter() {
    local candidates=(
        "$HOME/.local/share/Steam/steamapps/common/Moonlighter"
        "$HOME/.steam/steam/steamapps/common/Moonlighter"
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Moonlighter"
        "/run/media/mmcblk0p1/steamapps/common/Moonlighter"
        "$HOME/Library/Application Support/Steam/steamapps/common/Moonlighter"
    )

    for vdf in \
        "$HOME/.local/share/Steam/steamapps/libraryfolders.vdf" \
        "$HOME/.steam/steam/steamapps/libraryfolders.vdf" \
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/libraryfolders.vdf" \
        "$HOME/Library/Application Support/Steam/steamapps/libraryfolders.vdf"; do
        if [[ -f "$vdf" ]]; then
            while IFS= read -r lib; do
                candidates+=("$lib/steamapps/common/Moonlighter")
            done < <(grep -oE '"path"[[:space:]]+"[^"]+"' "$vdf" | sed -E 's/"path"[[:space:]]+"([^"]+)"/\1/' || true)
        fi
    done

    for dir in "${candidates[@]}"; do
        if [[ -f "$dir/Moonlighter.exe" || -f "$dir/Moonlighter.x86_64" || -d "$dir/Moonlighter.app" ]]; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

GAME_DIR=""
if GAME_DIR="$(find_moonlighter)"; then
    echo "Found Moonlighter at: $GAME_DIR"
else
    read -rp "Could not auto-detect Moonlighter. Enter full path to Moonlighter folder: " GAME_DIR
fi

if [[ -z "$GAME_DIR" || ( ! -f "$GAME_DIR/Moonlighter.exe" && ! -f "$GAME_DIR/Moonlighter.x86_64" && ! -d "$GAME_DIR/Moonlighter.app" ) ]]; then
    echo "ERROR: Moonlighter.exe, Moonlighter.x86_64, or Moonlighter.app not found in '$GAME_DIR'."
    exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading mod package..."
curl -fsSL "$WIN_ZIP_URL" -o "$TMP_DIR/mod.zip"
unzip -qo "$TMP_DIR/mod.zip" -d "$TMP_DIR/mod"

if [[ -f "$GAME_DIR/Moonlighter.exe" ]]; then
    echo "Detected Windows (Proton) build."
    cp -f "$TMP_DIR/mod/winhttp.dll" "$GAME_DIR/"
    cp -f "$TMP_DIR/mod/doorstop_config.ini" "$GAME_DIR/"
    cp -rf "$TMP_DIR/mod/BepInEx" "$GAME_DIR/"

    echo ""
    echo "SUCCESS! Installed for Proton."
    echo "IMPORTANT: In Steam -> Moonlighter -> Properties -> Launch Options, set:"
    echo '  WINEDLLOVERRIDES="winhttp=n,b" %command%'
    echo ""
else
    if [[ -d "$GAME_DIR/Moonlighter.app" ]]; then
        EXEC_NAME="Moonlighter.app"
        PLATFORM_LABEL="macOS"
    else
        EXEC_NAME="Moonlighter.x86_64"
        PLATFORM_LABEL="Native Linux"
    fi

    echo "Detected $PLATFORM_LABEL build."
    echo "Downloading BepInEx 5.4.22.0..."
    curl -fsSL "$UNIX_BEPINEX_URL" -o "$TMP_DIR/bepinex_unix.zip"
    unzip -qo "$TMP_DIR/bepinex_unix.zip" -d "$GAME_DIR"
    mkdir -p "$GAME_DIR/BepInEx/plugins"
    cp -f "$TMP_DIR/mod/BepInEx/plugins/AnalogMovementMod.dll" "$GAME_DIR/BepInEx/plugins/"
    if [[ -f "$GAME_DIR/run_bepinex.sh" ]]; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            sed -i '' "s/executable_name=\"\"/executable_name=\"$EXEC_NAME\"/" "$GAME_DIR/run_bepinex.sh" || true
        else
            sed -i "s/executable_name=\"\"/executable_name=\"$EXEC_NAME\"/" "$GAME_DIR/run_bepinex.sh" || true
        fi
        chmod +x "$GAME_DIR/run_bepinex.sh"
    fi

    echo ""
    echo "SUCCESS! Installed for $PLATFORM_LABEL."
    echo "IMPORTANT: In Steam -> Moonlighter -> Properties -> Launch Options, set:"
    echo '  ./run_bepinex.sh %command%'
    echo ""
    echo "Note: Both 360-degree analog movement and DualSense PlayStation icon detection are enabled!"
    echo ""
fi
