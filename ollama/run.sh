#!/bin/bash
set -e

echo "Starting Ollama Add-on..."

# Directory configuration for persistent models and binary distribution
export OLLAMA_MODELS=/data/ollama/models
export OLLAMA_HOST=0.0.0.0
export PATH="/data/ollama/dist/bin:/usr/local/bin:$PATH"
export LD_LIBRARY_PATH="/data/ollama/dist/lib/ollama:/usr/local/lib/ollama:${LD_LIBRARY_PATH:-}"

mkdir -p "$OLLAMA_MODELS" /data/ollama/dist/bin /data/ollama/dist/lib

# Ensure existing persistent binary distribution is linked if present
if [ -f /data/ollama/dist/bin/ollama ]; then
    ln -sf /data/ollama/dist/bin/ollama /usr/local/bin/ollama 2>/dev/null || true
fi
if [ -d /data/ollama/dist/lib/ollama ]; then
    ln -sfn /data/ollama/dist/lib/ollama /usr/local/lib/ollama 2>/dev/null || true
fi

# Parse options
AUTO_UPDATE="true"
OLLAMA_VERSION_REQUESTED="latest"

if [ -f /data/options.json ]; then
    OPT_AUTO_UPDATE=$(jq -r '.auto_update // empty' /data/options.json)
    if [ "$OPT_AUTO_UPDATE" = "false" ]; then
        AUTO_UPDATE="false"
    fi
    OPT_VERSION=$(jq -r '.ollama_version // empty' /data/options.json)
    if [ -n "$OPT_VERSION" ] && [ "$OPT_VERSION" != "null" ]; then
        OLLAMA_VERSION_REQUESTED="$OPT_VERSION"
    fi
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) ARCH="" ;;
esac

# Handle automatic updates without container rebuild
if [ "$AUTO_UPDATE" = "true" ]; then
    if [ -z "$ARCH" ]; then
        echo "Warning: Architecture $(uname -m) is unsupported for in-container updates. Using bundled Ollama version."
    else
        CURRENT_VERSION=$(ollama --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || echo "")
        TARGET_VERSION=""
        VER_PARAM=""

        if [ "$OLLAMA_VERSION_REQUESTED" != "latest" ] && [ -n "$OLLAMA_VERSION_REQUESTED" ]; then
            TARGET_VERSION="${OLLAMA_VERSION_REQUESTED#v}"
            VER_PARAM="?version=${TARGET_VERSION}"
        else
            # Extract latest version tag from download redirect header (avoids GitHub API rate limits)
            TARGET_VERSION=$(curl -sIL "https://ollama.com/download/ollama-linux-${ARCH}.tar.zst" 2>/dev/null | grep -i "location: https://github.com/ollama/ollama/releases/download/" | head -n 1 | sed -E 's|.*/releases/download/v?([^/]+)/.*|\1|' || echo "")
            if [ -z "$TARGET_VERSION" ]; then
                # Fallback to GitHub API
                TARGET_VERSION=$(curl -s "https://api.github.com/repos/ollama/ollama/releases/latest" 2>/dev/null | jq -r '.tag_name // empty' | sed 's/^v//' || echo "")
            fi
        fi

        if [ -z "$TARGET_VERSION" ]; then
            echo "Warning: Could not determine target Ollama version (network or rate-limit issue). Using current version: ${CURRENT_VERSION:-unknown}."
        elif [ "$CURRENT_VERSION" = "$TARGET_VERSION" ]; then
            echo "Ollama is up to date (version: ${CURRENT_VERSION})."
        else
            echo "Updating Ollama: current version is '${CURRENT_VERSION:-none}', target version is '${TARGET_VERSION}'..."
            DOWNLOAD_URL="https://ollama.com/download/ollama-linux-${ARCH}.tar.zst${VER_PARAM}"
            TEMP_DIR=$(mktemp -d)
            if curl --fail --show-error --location --silent "$DOWNLOAD_URL" | zstd -d | tar -xf - -C "$TEMP_DIR"; then
                cp -f "$TEMP_DIR/bin/ollama" /data/ollama/dist/bin/ollama
                chmod +x /data/ollama/dist/bin/ollama
                if [ -d "$TEMP_DIR/lib/ollama" ]; then
                    rm -rf /data/ollama/dist/lib/ollama
                    cp -r "$TEMP_DIR/lib/ollama" /data/ollama/dist/lib/ollama
                fi
                ln -sf /data/ollama/dist/bin/ollama /usr/local/bin/ollama 2>/dev/null || true
                ln -sfn /data/ollama/dist/lib/ollama /usr/local/lib/ollama 2>/dev/null || true
                INSTALLED_VER=$(ollama --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || echo "$TARGET_VERSION")
                echo "Successfully updated Ollama to version ${INSTALLED_VER}!"
            else
                echo "Warning: Failed to download or extract Ollama update. Using existing version: ${CURRENT_VERSION:-unknown}."
            fi
            rm -rf "$TEMP_DIR"
        fi
    fi
else
    echo "Auto-update is disabled. Using current version: $(ollama --version 2>/dev/null || echo 'unknown')."
fi

echo "Starting Ollama server (version: $(ollama --version 2>/dev/null || echo 'unknown'))..."
ollama serve &
OLLAMA_PID=$!

trap 'echo "Stopping Ollama..."; kill -TERM $OLLAMA_PID 2>/dev/null; wait $OLLAMA_PID' TERM INT

# Wait for Ollama to be available
echo "Waiting for Ollama API to be ready..."
until curl --silent --fail http://127.0.0.1:11434/api/tags > /dev/null; do
    sleep 2
done

echo "Ollama API is ready."

# Check if there are models to pull in the configuration
if [ -f /data/options.json ]; then
    MODELS_COUNT=$(jq '.models_to_pull | length' /data/options.json)
    if [ "$MODELS_COUNT" -gt 0 ]; then
        for i in $(seq 0 $(($MODELS_COUNT - 1))); do
            MODEL=$(jq -r ".models_to_pull[$i]" /data/options.json)
            if [ -n "$MODEL" ] && [ "$MODEL" != "null" ]; then
                echo "Pulling model: $MODEL (this may take a while depending on size)"
                ollama pull "$MODEL"
            fi
        done
    fi
fi

echo "Startup complete. Ollama is ready to serve requests."
wait $OLLAMA_PID
