# discord.cob

[English README](README.md)

`discord.cob` は、COBOL で Discord Bot を実装するためのオープンソースプロジェクトです。
単に「COBOL から HTTP を呼んでみる」サンプルにとどまらず、Discord Gateway、WebSocket、Voice、UDP、RTP、音声暗号化、Music Bot といった周辺まで、段階的に実装していくことを目指しています。

最終的な狙いは、Bot 開発者が毎回 Discord の生プロトコルを追わなくても、COBOL から扱いやすい API を通して Bot を組み立てられるようにすることです。

## この README で分かること

- このリポジトリが何を目指しているか
- 現時点でどこまで実装が進んでいるか
- いま触るなら何が使えて、何はまだ途中か
- ビルド方法、テスト方法、読み始めるときの入口

## これは何のプロジェクトか

このプロジェクトには、主に次の 3 つの目的があります。

1. COBOL で現代的なネットワークプロトコルをどこまで扱えるかを確かめること
2. Discord Bot に必要な低レイヤを、少しずつライブラリとして整理していくこと
3. 最終的に、Voice 対応の Music Bot を COBOL で動かせるところまで持っていくこと

そのため、このリポジトリは現時点では「完成済みの Bot フレームワーク」というより、「動く土台を着実に積み上げている実装リポジトリ」と捉えるのが実態に近いです。

## 現在地

このリポジトリは pre-alpha 段階です。

ただし、まだ構想だけの状態ではありません。すでにコードとテストが揃っていて、継続的に積み上がっているレイヤがいくつもあります。

- core client state と result helper
- event の登録と dispatch
- Discord 向け JSON validation と JSON path 抽出
- HTTP request / response の組み立てと解析、GET / POST / PUT / PATCH / DELETE の実行
- in-memory の TCP / TLS fixture transport
- `nc` / `openssl s_client` を使った OS ベースの TCP / TLS transport
- WebSocket handshake helper
- WebSocket frame の encode / decode
- in-memory WebSocket session
- opt-in の live TLS-backed WebSocket session
- fixture-backed / OS-backed の UDP transport
- RTP packet 生成
- music queue の基礎

また、現時点では「すでに動いているところ」と「これから厚くしていくところ」が比較的はっきり分かれています。

すでに通っている実装:

- live Discord Gateway への connect / login と最小の event loop
- tick ベースで進む Gateway / Voice heartbeat scheduler
- live Voice Gateway への connect と最小の recv / apply / queue / send loop
- Voice の select protocol / speaking payload builder、UDP discovery の自動適用、session description の `secret_key` 取り込み、送信キュー
- `aead_xchacha20_poly1305_rtpsize` による voice packet 暗号化
- Ogg Opus からの初期 packet 抽出と reader handle の close
- queue に積んだ `.ogg` / `.opus` ソースを Voice tick にぶら下げて raw/local 送信する再生土台
- `/join` `/leave` `/play` `/skip` `/stop` `/queue` を music / voice API に接続する command routing
- slash command の HTTP registration / list / delete / overwrite と、music command 一式を同期する helper
- slash command / component / modal submit の interaction JSON 取り込み、custom handler routing、即時 / update / modal / deferred / follow-up reply helper、follow-up / original response の edit / delete helper、callback POST、dispatcher 経由で登録できる interaction handler

引き続き開発中の領域:

- Gateway reconnect と heartbeat 異常時の扱い
- 暗号化を含む end-to-end の music bot workflow

## いまこのリポジトリでできること

現時点で特に触りやすいのは、次のような用途です。

- COBOL で Discord 向けの HTTP / WebSocket / RTP レイヤの実装例を読む
- protocol primitive のテストを追加しながら低レイヤを拡張する
- Gateway / Voice 実装の前段として request builder や state 管理を進める
- GnuCOBOL で realtime / network 処理をどこまで寄せられるか検証する

逆に、すぐに production 向け Bot を立ち上げたい場合には、まだ向いていません。

## 設計の考え方

このプロジェクトでは、いきなり Bot 向けの表面 API から整えるのではなく、次の順番を重視しています。

1. parser / codec / packet builder のような protocol primitive を固める
2. transport と session の実装を増やす
3. Gateway / Voice の状態遷移を積み上げる
4. その上で、Bot 作者向け API を薄く整理する

この順番にしているのは、Discord まわりの処理が最終的に WebSocket、Voice、UDP、RTP、暗号化まで連続してつながるためです。
上位 API だけを先に作ると、あとから下の層の事情で大きく引きずられやすくなります。そのため、いまは意図的に低レイヤを厚めに作っています。

## リポジトリ構成

```text
src/
  core/          client state, dispatcher, result helper
  json/          JSON validation と path reader
  net/           HTTP / transport / WebSocket
  gateway/       Gateway payload builder と event mapping
  voice/         voice session state と Voice まわりの土台
  rtp/           RTP packet と sequence / timestamp helper
  crypto/        voice encryption レイヤ
  opus/          Opus helper と reader / encoder 周辺
  audio/         playback 側の抽象
  music/         queue と command helper
  copybooks/     共通 data definition

examples/        段階別のサンプルプログラム
tests/           実行可能な COBOL test
docs/            API メモと roadmap
```

## 目指している API の形

最終的には、利用側から素直に呼べる COBOL API を用意したいと考えています。

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

この上位 API 自体はまだ発展途上ですが、その土台になる transport や protocol primitive はかなり揃ってきました。登録した handler program は `CALL handler USING DC-CLIENT DC-EVENT DC-RESULT` の形で呼び出されます。

## クイックスタート

### 必要環境

- GnuCOBOL
- `cobc`
- `libsodium`

macOS で Homebrew を使う場合:

```sh
brew install gnucobol libsodium pkg-config
```

### ビルド

```sh
make build
```

### テスト

```sh
make test
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

HTTP まわりのサンプルは次のように実行できます。

```sh
mkdir -p build/examples
cobc -free -Wall -I src/copybooks -x \
  -o build/examples/example-http \
  examples/01-rest-message/main.cob \
  $(find src -name '*.cob' | sort)
./build/examples/example-http
```

Gateway 側の入口イメージを見たい場合は [examples/02-gateway-ready/main.cob](examples/02-gateway-ready/main.cob) が分かりやすいです。

## 設定方針

Discord token はソースコードに埋め込まない方針です。

リポジトリには次を含めています。

- `.env.example`
- `.env` を除外する `.gitignore`

今後も、認証情報は環境変数や設定ファイル経由で扱う前提で整えていきます。

## どこから読むと追いやすいか

初めて追うなら、次の順番がおすすめです。

1. [docs/roadmap.md](docs/roadmap.md) で現在地を確認する
2. [docs/api.md](docs/api.md) で公開 API の断面を見る
3. `tests/` を読んで、各レイヤの期待動作を掴む
4. `src/net/` と `src/gateway/` を中心に実装を追う

まず動くコードから入りたいなら、`tests/websocket-test.cob` と `tests/transport-test.cob` が比較的追いやすいです。

## ロードマップ

近い優先項目は次の通りです。

1. Gateway reconnect / heartbeat 異常時のライフサイクルを厚くする
2. 音声暗号化まわりをさらに厚くする
3. embed を含む interaction builder と command sync の使い勝手を厚くする
4. 暗号化込みの end-to-end playback を成立させる
5. music bot の上位 example を増やす

長期目標は、Voice channel に参加して音声再生できる COBOL 製 Discord Music Bot を成立させることです。

## コントリビュート

このプロジェクトはまだ探索段階ですが、次のような貢献はとても助かります。

- GnuCOBOL の挙動差や portability の検証
- parser / codec の edge case テスト
- Discord protocol compatibility の確認
- Gateway / Voice の状態遷移整理
- example と documentation の改善

小さめの変更でも、テストが一緒にあるとレビューしやすくなります。

## 関連ドキュメント

- 設計草案: [discord_cob_design.md](discord_cob_design.md)
- API メモ: [docs/api.md](docs/api.md)
- Roadmap: [docs/roadmap.md](docs/roadmap.md)

## ライセンス

このプロジェクトは MIT License で公開しています。詳細は [LICENSE](LICENSE) を参照してください。
