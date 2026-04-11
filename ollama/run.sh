#!/bin/bash
set -e

echo "Starting Ollama Add-on..."

# Set environment to persist models in HA's /data directory
export OLLAMA_MODELS=/data/ollama/models
export OLLAMA_HOST=0.0.0.0

# Start Ollama in the background
ollama serve &
OLLAMA_PID=$!

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
# Wait for the background process to finish so the container doesn't exit
wait $OLLAMA_PID
