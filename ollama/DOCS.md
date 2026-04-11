# Ollama Home Assistant Add-on

This add-on allows you to run Ollama locally.

## Configuration

You can configure the models you want the add-on to automatically pull (download) upon starting.

### `models_to_pull` (Optional)
A list of model names to pull. For example:
- `llama3`
- `mistral:7b`
- `phi3`

Enter each model as a new item in the list in the Add-on configuration UI.

We recommend doing this one model at a time, especially for large models, as downloading can take significant time depending on your internet connection.

Once the models are downloaded, they are persisted locally. You can access the Ollama API natively via Home Assistant over HTTP on port `11434` (or whatever you configure the port to be).
