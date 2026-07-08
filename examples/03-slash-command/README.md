# 03-slash-command

This phase now has three useful entry points:

- `DC-SLASH-COMMAND-BUILD-REQUEST` for building a Discord application-command REST request without sending it
- `DC-COMMAND-SCHEMA-ADD` / `DC-COMMAND-SCHEMA-TO-JSON` / `DC-COMMAND-SCHEMA-SYNC` for declaring commands as structured schema data and synchronizing them without hand-written JSON
- `DC-MUSIC-COMMANDS-REGISTER` and `DC-MUSIC-COMMANDS-OVERWRITE` for syncing the built-in `/join`, `/leave`, `/play`, `/skip`, `/stop`, and `/queue` commands

The sample `main.cob` keeps things local: it builds the low-level request so it can be inspected safely, then declares a small command set with the schema API and prints the generated JSON payload.
