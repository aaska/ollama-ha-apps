# Project Memory

- **Project Purpose**: Create a Home Assistant Add-on repository to run Ollama locally.
- **Key Decisions**: 
  - Using Docker image from `ollama/ollama:latest`.
  - Persisting models in `/data/ollama/models`.
  - Taking a list of models to pull via HA add-on configuration.
- **Current Status**: Setting up the initial Add-on structure (repository.json, config.yaml, Dockerfile, run.sh).
