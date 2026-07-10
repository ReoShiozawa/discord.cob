# 05-udp-discovery

This runnable diagnostic performs Discord Voice UDP discovery over the live UDP transport.

```sh
make build/examples/05-udp-discovery
DISCORD_VOICE_IP=... \
DISCORD_VOICE_PORT=... \
DISCORD_VOICE_SSRC=... \
./build/examples/05-udp-discovery
```

The values are obtained from a Voice Gateway `READY` payload and are short-lived. The example prints the externally visible address and port returned by discovery.
