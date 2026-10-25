# Task List

## In Progress

## To Do
- [ ] Connect with Home Assistant to test the Add-on.
- [ ] Enhance documentation.

## Done
- [x] Implement dynamic in-container self-update for Ollama without rebuilding and bump version to `0.2.0` [SF, ISA].
- [x] Exclude downloaded models from Home Assistant backups to save space.
- [x] Fix container starting error by overriding base image ENTRYPOINT and bumping version to `0.1.1`.
- [x] Create `build.yaml` to override Supervisor default Alpine image injection.
- [x] Fix Docker build relying on HA Supervisor alpine base instead of official Ollama base.
- [x] Fix add-on config schema format for string arrays.
- [x] Fix invalid map in `config.yaml` causing add-on store to discard the add-on.
- [x] Initial planning for Ollama HA addon.
- [x] Add basic repository configs and ollama add-on files.
