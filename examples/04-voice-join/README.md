# 04-voice-join

`DC-VOICE-JOIN` and `DC-VOICE-LEAVE` are implemented.

The current shape is Gateway-queue based:

- `DC-VOICE-JOIN` stores a guild-scoped voice session snapshot
- queues a `VOICE_STATE_UPDATE`
- later Gateway voice events enrich that stored session with `session_id`, `token`, and `endpoint`

This phase is no longer just a placeholder; the higher-level orchestration now lives across:

- `src/voice/dc-voice-manager.cob`
- `src/voice/dc-voice-runtime.cob`
- `src/voice/dc-voice-server-handler.cob`
