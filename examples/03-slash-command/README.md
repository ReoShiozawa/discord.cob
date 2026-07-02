# 03-slash-command

This phase now has two useful entry points:

- `DC-SLASH-COMMAND-BUILD-REQUEST` for building a Discord application-command REST request without sending it
- `DC-MUSIC-COMMANDS-REGISTER` and `DC-MUSIC-COMMANDS-OVERWRITE` for syncing the built-in `/join`, `/leave`, `/play`, `/skip`, `/stop`, and `/queue` commands

The sample `main.cob` keeps things local and only builds the request so it can be inspected safely.
