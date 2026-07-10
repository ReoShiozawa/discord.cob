# discord.cob

[English README](README.md)

`discord.cob` は、COBOL で Discord Bot を実装するためのオープンソースプロジェクトです。
単に「COBOL から HTTP を呼んでみる」サンプルにとどまらず、Discord Gateway、WebSocket、Voice、UDP、RTP、音声暗号化、Music Bot までをひとつの実行経路として扱います。

最終的な狙いは、Bot 開発者が毎回 Discord の生プロトコルを追わなくても、COBOL から扱いやすい API を通して Bot を組み立てられるようにすることです。

## この README で分かること

- このリポジトリが何を目指しているか
- 現時点でどこまで実装が進んでいるか
- いま利用できる範囲と、あらかじめ知っておきたい制約
- ビルド方法、テスト方法、読み始めるときの入口

## これは何のプロジェクトか

このプロジェクトには、主に次の 3 つの目的があります。

1. COBOL で現代的なネットワークプロトコルをどこまで扱えるかを確かめること
2. Discord Bot に必要な低レイヤを、少しずつライブラリとして整理していくこと
3. Voice 対応の Music Bot を COBOL で動かし、保守できる形にすること

最初の設計マイルストーンは実装済みです。Gateway への接続から Voice negotiation、暗号化した Opus packet の UDP 送信、Interaction を使った Music Bot 操作までが、同じ公開 API の上でつながっています。

## 現在地

このリポジトリは、実験的な 0.x 系の OSS です。

主要なレイヤには実装と自動テストがあり、次の機能をリポジトリ内で確認できます。

- core client state と result helper
- event の登録と dispatch
- 深さと配列を考慮した JSON validation / tokenization / path 抽出と文字列 escape
- HTTP request / response の組み立てと解析、GET / POST / PUT / PATCH / DELETE の実行
- in-memory の TCP / TLS fixture transport
- `nc` / `openssl s_client` を使った OS ベースの TCP / TLS transport
- WebSocket handshake helper
- WebSocket frame の encode / decode、分割受信の蓄積、continuation の再構成、close 処理
- in-memory WebSocket session
- opt-in の live TLS-backed WebSocket session
- fixture-backed / OS-backed の UDP transport
- RTP packet 生成
- music queue と local Ogg Opus の再生管理

対応済みの実装:

- live Discord Gateway への connect / login と最小の event loop
- tick ベースで進む Gateway / Voice heartbeat scheduler
- live Voice Gateway への connect と最小の recv / apply / queue / send loop
- Voice の select protocol / speaking payload builder、UDP discovery の自動適用、session description の `secret_key` 取り込み、送信キュー
- `aead_xchacha20_poly1305_rtpsize` による voice packet 暗号化
- Ogg Opus からの初期 packet 抽出と reader handle の close
- queue に積んだ `.ogg` / `.opus` ソースを、negotiation 済みの Voice session から暗号化して送信する再生経路
- `/join` `/leave` `/play` `/skip` `/pause` `/resume` `/stop` `/queue` `/remove` `/clearqueue` `/nowplaying` を music / voice API に接続する command routing
- `/nowplaying` と `/queue` に対する custom interaction panel と、その場で操作できる inline control
- slash command の HTTP registration / list / delete / overwrite と、music command 一式を同期する helper
- slash command / autocomplete / component / modal submit の interaction JSON 取り込み、focused option lookup、command / component / modal の custom handler routing と command ベースの autocomplete dispatch、即時 / update / modal / deferred / follow-up / autocomplete reply helper、follow-up / original response の get / wait / edit / delete helper、callback POST、dispatcher 経由で登録できる interaction handler

現時点で意図的に範囲外としているもの:

- YouTube 等からの取得、任意形式の transcoding、PCM からの Opus encoding
- Discord の DAVE/E2EE 拡張
- `openssl s_client` / `nc` に依存しない、COBOL 内だけで完結する TLS/TCP 実装
- 実アカウントを使う自動 E2E テスト。通常のテスト suite は fixture 上で完結します

## いまこのリポジトリでできること

特に向いているのは、次のような用途です。

- COBOL で Discord 向けの HTTP / WebSocket / RTP レイヤの実装例を読む
- protocol primitive のテストを追加しながら低レイヤを拡張する
- local Ogg Opus を使う小規模な Voice Bot を組み立てる
- GnuCOBOL で realtime / network 処理をどこまで寄せられるか検証する

大規模な production Bot で成熟した Discord ライブラリの代替として採用する段階ではありません。

## 設計の考え方

このプロジェクトでは、いきなり Bot 向けの表面 API から整えるのではなく、次の順番を重視しています。

1. parser / codec / packet builder のような protocol primitive を固める
2. transport と session の実装を増やす
3. Gateway / Voice の状態遷移を積み上げる
4. その上で、Bot 作者向け API を薄く整理する

この順番にしているのは、Discord まわりの処理が最終的に WebSocket、Voice、UDP、RTP、暗号化まで連続してつながるためです。
上位 API だけを先に作ると、あとから下の層の事情で設計変更が広がりやすくなります。この方針に沿って、公開 API と protocol layer を同じテスト suite で確認しています。

## リポジトリ構成

```text
src/
  core/          client state, dispatcher, result helper
  json/          JSON validation と path reader
  net/           HTTP / transport / WebSocket
  gateway/       Gateway payload builder と event mapping
  voice/         Voice Gateway、session state、UDP negotiation
  rtp/           RTP packet と sequence / timestamp helper
  crypto/        voice encryption レイヤ
  opus/          Ogg Opus reader と packet helper
  audio/         playback 側の抽象
  music/         queue と command helper
  copybooks/     共通 data definition

examples/        段階別のサンプルプログラム
tests/           実行可能な COBOL test
docs/            API メモと roadmap
```

## 公開 API の形

利用側は、Discord の wire format を直接組み立てず、次のような COBOL API を呼び出します。

```cobol
CALL "DC-CLIENT-INIT"
    USING DC-CONFIG
          DC-CLIENT
          DC-RESULT.

CALL "DC-ON"
    USING DC-CLIENT
          "READY"
          "APP-ON-READY"
          DC-RESULT.

CALL "DC-LOGIN"
    USING DC-CLIENT
          DC-RESULT.
```

この API は Gateway、Interaction、Voice、Music Bot の各サンプルで実際に使われています。登録した handler program は `CALL handler USING DC-CLIENT DC-EVENT DC-RESULT` の形で呼び出されます。

## クイックスタート

### 必要環境

- GnuCOBOL
- `cobc`
- `libsodium`
- live transport 用の OpenSSL と netcat

macOS で Homebrew を使う場合:

```sh
brew install gnucobol libsodium pkg-config openssl netcat
```

### ビルド

```sh
make build
```

### テスト

```sh
make test
```

段階別サンプルをまとめてビルドする場合:

```sh
make examples
```

主なテスト:

- `core-test`
- `json-test`
- `http-test`
- `url-test`
- `transport-test`
- `websocket-test`
- `ws-handshake-test`
- `gateway-test`
- `voice-test`
- `rtp-test`
- `opus-test`
- `music-queue-test`
- `music-playback-test`

### サンプル実行

`make examples` の後、実行ファイルは `build/examples/` に生成されます。Music Bot の入口は次のとおりです。

```sh
DISCORD_TOKEN=... \
DISCORD_APPLICATION_ID=... \
DISCORD_GUILD_ID=... \
./build/examples/09-music-bot
```

必要な環境変数と停止方法は [examples/09-music-bot/README.md](examples/09-music-bot/README.md) にまとめています。

## 設定方針

Discord token はソースコードに埋め込まない方針です。

リポジトリには次を含めています。

- `.env.example`
- `.env` を除外する `.gitignore`

実行サンプルも、この方針に沿って環境変数から認証情報を読み込みます。

## どこから読むと追いやすいか

初めて追うなら、次の順番がおすすめです。

1. [docs/roadmap.md](docs/roadmap.md) で現在地を確認する
2. [docs/api.md](docs/api.md) で公開 API の断面を見る
3. `tests/` を読んで、各レイヤの期待動作を掴む
4. `src/net/` と `src/gateway/` を中心に実装を追う

まず動くコードから入りたいなら、`tests/websocket-test.cob` と `tests/transport-test.cob` が比較的追いやすいです。

## ロードマップ

最初の設計マイルストーン後は、次の改善を優先します。

1. reconnect や rate limit を含む実 Discord 上での互換性検証
2. macOS / GnuCOBOL 以外への portability 改善
3. 大きな payload を扱う streaming / buffer 設計
4. PCM transcoding / encoding の任意連携
5. Discord の仕様変化に応じた DAVE 対応

当初の目標だった「Voice channel に参加し、暗号化した Opus 音声を送る COBOL 製 Music Bot」は、`08-play-opus-file` と `09-music-bot` で確認できます。

## コントリビュート

このプロジェクトはまだ探索段階ですが、次のような貢献はとても助かります。

- GnuCOBOL の挙動差や portability の検証
- parser / codec の edge case テスト
- Discord protocol compatibility の確認
- Gateway / Voice の状態遷移整理
- example と documentation の改善

小さめの変更でも、テストが一緒にあるとレビューしやすくなります。
開発手順とリポジトリ固有の約束は [CONTRIBUTING.md](CONTRIBUTING.md) にまとめています。

## 関連ドキュメント

- 設計草案: [discord_cob_design.md](discord_cob_design.md)
- API メモ: [docs/api.md](docs/api.md)
- Roadmap: [docs/roadmap.md](docs/roadmap.md)

## ライセンス

このプロジェクトは MIT License で公開しています。詳細は [LICENSE](LICENSE) を参照してください。
