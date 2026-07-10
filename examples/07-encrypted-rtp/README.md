# 07-encrypted-rtp

This runnable diagnostic sends one encrypted Opus silence frame using an already negotiated Voice session.

```sh
make build/examples/07-encrypted-rtp
DISCORD_VOICE_IP=... \
DISCORD_VOICE_PORT=... \
DISCORD_VOICE_SSRC=... \
DISCORD_VOICE_SECRET_KEY_HEX=... \
./build/examples/07-encrypted-rtp
```

The secret key must be the 32-byte `secret_key` from `SESSION_DESCRIPTION`, represented as 64 hexadecimal digits. Prefer the high-level `08-play-opus-file` or `09-music-bot` example for normal use; this program exists for transport diagnostics.
