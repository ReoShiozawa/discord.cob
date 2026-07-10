# 09-music-bot

This phase now has a minimal runnable startup sample in `main.cob`.

It demonstrates the current high-level path:

1. `DC-CLIENT-INIT`
2. `DC-MUSIC-BOT-BOOTSTRAP`
3. `DC-LOGIN`
4. `DC-BOT-RUN` or `DC-BOT-RUN-UNTIL-FILE`
5. `DC-BOT-SHUTDOWN`

Required environment variables:

- `DISCORD_TOKEN`
- `DISCORD_APPLICATION_ID`
- `DISCORD_GUILD_ID`

Optional environment variables:

- `DISCORD_STEP_COUNT`
- `DISCORD_STOP_FILE`
- `DISCORD_IDLE_LEAVE_TICKS`

Build example:

```sh
mkdir -p build/examples
cobc -free -Wall -I src/copybooks -x \
  -o build/examples/example-music-bot \
  examples/09-music-bot/main.cob \
  $(find src -name '*.cob' | sort)
```

Run example:

```sh
DISCORD_TOKEN=... \
DISCORD_APPLICATION_ID=... \
DISCORD_GUILD_ID=... \
./build/examples/example-music-bot
```

`DISCORD_STEP_COUNT` defaults to `0`. In that mode the example uses `DISCORD_STOP_FILE`, or `.discord-cob.stop` when the variable is omitted, so the runtime can leave Voice and close WebSocket sessions cleanly.

Creating the stop file cleanly ends the loop from outside the process. A positive `DISCORD_STEP_COUNT` selects the bounded runner instead.

`DISCORD_IDLE_LEAVE_TICKS` controls how many idle bot ticks an empty music runtime waits before it automatically queues a voice leave. The default is `1200`.

After the loop exits, the example explicitly calls `DC-BOT-SHUTDOWN` so stored voice/music runtime state and the Gateway session are closed before the process ends.
