# 04-voice-join

`DC-VOICE-JOIN` and `DC-VOICE-LEAVE` are implemented.

`main.cob` is a runnable live example. It logs in, registers the framework handlers, queues the join, and drives Gateway/Voice negotiation until a stop file appears.

```sh
make build/examples/04-voice-join
DISCORD_TOKEN=... \
DISCORD_APPLICATION_ID=... \
DISCORD_GUILD_ID=... \
DISCORD_VOICE_CHANNEL_ID=... \
DISCORD_STOP_FILE=.discord-cob.stop \
./build/examples/04-voice-join
```

The current shape is Gateway-queue based:

- `DC-VOICE-JOIN` stores a guild-scoped voice session snapshot
- queues a `VOICE_STATE_UPDATE`
- later Gateway voice events enrich that stored session with `session_id`, `token`, and `endpoint`

This phase is no longer just a placeholder; the higher-level orchestration now lives across:

- `src/voice/dc-voice-manager.cob`
- `src/voice/dc-voice-runtime.cob`
- `src/voice/dc-voice-server-handler.cob`
