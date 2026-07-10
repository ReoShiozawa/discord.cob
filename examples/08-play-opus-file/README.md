# 08-play-opus-file

This phase now has a runnable example in `main.cob`.

It demonstrates the current live-oriented path:

1. `DC-CLIENT-INIT`
2. `DC-BOT-REGISTER-DEFAULTS`
3. `DC-LOGIN`
4. `DC-MUSIC-PLAY`
5. `DC-BOT-RUN` or `DC-BOT-RUN-UNTIL-FILE`
6. `DC-BOT-SHUTDOWN`

Required environment variables:

- `DISCORD_TOKEN`
- `DISCORD_GUILD_ID`
- `DISCORD_VOICE_CHANNEL_ID`
- `DISCORD_AUDIO_SOURCE`

Optional environment variables:

- `DISCORD_STEP_COUNT`
- `DISCORD_STOP_FILE`
- `DISCORD_IDLE_LEAVE_TICKS`

Build example:

```sh
mkdir -p build/examples
cobc -free -Wall -I src/copybooks -x \
  -o build/examples/example-play-opus-file \
  examples/08-play-opus-file/main.cob \
  $(find src -name '*.cob' | sort)
```

Run example:

```sh
DISCORD_TOKEN=... \
DISCORD_GUILD_ID=... \
DISCORD_VOICE_CHANNEL_ID=... \
DISCORD_AUDIO_SOURCE=/absolute/path/to/file.ogg \
./build/examples/example-play-opus-file
```

`DISCORD_STEP_COUNT` defaults to `0`. In that mode the example waits for `DISCORD_STOP_FILE`, or `.discord-cob.stop` when the variable is omitted.

Creating the stop file cleanly ends the loop from outside the process. A positive `DISCORD_STEP_COUNT` selects the bounded runner instead.

`DISCORD_IDLE_LEAVE_TICKS` controls how long an empty playback runtime waits before it automatically queues a voice leave. The default is `1200`.

After the loop exits, the example explicitly calls `DC-BOT-SHUTDOWN` so stored voice/music runtime state and the Gateway session are closed before the process ends.

Scope:

- Voice negotiation and encrypted packet delivery are handled by the framework runtime.
- This example accepts local Ogg Opus / Opus sources; downloading and transcoding are not included.
- Use `DISCORD_STOP_FILE` for a clean, externally controlled shutdown.
