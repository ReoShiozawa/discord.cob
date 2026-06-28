# discord.cob

COBOLだけでDiscord Botを作るための実験的フレームワークです。
設計書 `discord_cob_design.md` を元に、Phase 0/1 の土台と後続フェーズ用のAPI骨格を実装しています。

## 現在の実装状況

実装済み:

- Core: client init, result, logger, event handler registration, dispatch
- JSON: simple JSON Path reader for values such as `$.op`, `$.t`, `$.d.session_id`
- Gateway/Interaction: payload builder and routing skeleton
- RTP: RTP header builder, packet builder, sequence/timestamp advance
- Opus: Discord silence frame builder
- Music: queue init/push/pop and track helper
- Voice/Network/Crypto: public API skeleton with explicit `DC_ERR_*` results

未実装:

- TCP socket
- TLS
- WebSocket transport
- Discord Gateway live connection
- UDP voice transport
- Voice encryption
- Ogg Opus packet reader
- Full music bot playback

## 必要環境

- GnuCOBOL (`cobc`)
- macOSの場合は Homebrew で導入できます。

```sh
brew install gnucobol
```

この環境では `/opt/homebrew/bin/cobc` が見つかったため、追加インストールは行っていません。

## ビルドとテスト

```sh
make build
make test
```

`make test` は以下をコンパイルして実行します。

- `core-test`
- `json-test`
- `rtp-test`
- `music-queue-test`

## Bot Token

Bot Tokenはソースへ書かず、環境変数から読む方針です。

```sh
cp .env.example .env
```

`.env` は `.gitignore` 済みです。

## 次の実装候補

1. JSON tokenizer/parserの厳密化
2. HTTP response/header parser
3. WebSocket frame builder/parser
4. Gateway READY受信用の最小WebSocket接続
5. Slash command `/ping`
6. Voice Join state machine
7. UDP discovery
8. RTP silence sending
9. Voice encryption
10. Ogg Opus packet reader
