# discord.cob

[English README](README.md)

`discord.cob` は、COBOL で Discord Bot を組み立てるためのオープンソース実験プロジェクトです。
ただの「COBOL から HTTP を叩くサンプル」ではなく、Discord Gateway、WebSocket、Voice、RTP、音楽 Bot までを視野に入れた、継続的な実装ベースとして育てています。

最終的には、Bot を作る側が Discord の生プロトコルを毎回意識しなくて済むように、COBOL から呼び出せるフレームワークとして成立させることが目標です。

## この README で分かること

- このリポジトリが何を目指しているか
- 2026年6月時点でどこまで実装済みか
- いま触るなら何が使えて、何はまだ途中か
- ビルド方法、テスト方法、入口になるファイル

## これは何のプロジェクトか

このプロジェクトは、次の 3 つの目的をまとめて扱っています。

1. COBOL で現代的なネットワークプロトコルをどこまで実装できるかを確かめること
2. Discord Bot 開発で必要になる低レイヤを、段階的にライブラリ化していくこと
3. 最終的に Voice 対応の Music Bot を COBOL で動かせるところまで持っていくこと

そのため、現時点では「完成した Bot フレームワーク」よりも、「動く土台が着実に増えている実装リポジトリ」として捉えるのが正確です。

## 現在地

このリポジトリは pre-alpha です。

ただし、単なる構想段階ではありません。以下のレイヤはすでにコードとテストが揃っており、継続的に積み上がっています。

- Core client state と result helper
- event registration / dispatch
- Discord 向け JSON path 抽出と validation
- HTTP request / response の組み立てと解析
- in-memory の TCP/TLS fixture transport
- `nc` / `openssl s_client` を使った OS-backed TCP/TLS transport
- WebSocket handshake helper
- WebSocket frame encode / decode
- in-memory WebSocket session
- opt-in の live TLS-backed WebSocket session
- fixture-backed / OS-backed の UDP transport
- RTP packet 生成
- music queue の基礎

また、いまの時点で「もう動くところ」と「これから厚くするところ」ははっきり分かれています。

すでに通っている実装:

- live Discord Gateway connect / login と最小 event loop
- tick ベースで進む Gateway / Voice heartbeat scheduler
- live Voice Gateway connect と最小の recv/apply/queue/send loop
- Voice の select protocol / speaking payload builder、UDP discovery の自動適用、session description の secret_key 取り込み、送信キュー
- `aead_xchacha20_poly1305_rtpsize` による voice packet 暗号化
- Ogg Opus からの初期 packet 抽出と reader handle の close
- queue に積んだ `.ogg/.opus` ソースを Voice tick にぶら下げて raw/local 送信する再生土台
- `/join` `/leave` `/play` `/skip` `/stop` `/queue` を music / voice API に接続する command routing
- interaction JSON の取り込み、即時 reply payload の生成、callback POST、dispatcher 経由で登録できる interaction handler

引き続き開発中の領域:

- Gateway reconnect と heartbeat 異常時の扱い
- slash command の HTTP registration
- 暗号化を含む end-to-end の music bot workflow

## いまこのリポジトリでできること

現時点で実用的に触りやすいのは、次のような用途です。

- COBOL で Discord 向けの HTTP / WebSocket / RTP レイヤの実装例を読む
- protocol primitive のテストを足しながら低レイヤを拡張する
- Gateway / Voice 実装の前段として request builder や state 管理を進める
- GnuCOBOL でどこまで realtime / network 処理を寄せられるか検証する

逆に、すぐに production bot を立ち上げたい用途にはまだ向いていません。

## 設計の考え方

このプロジェクトでは、いきなり Bot の表面 API だけを整えるのではなく、次の順番を重視しています。

1. parser / codec / packet builder のような protocol primitive を固める
2. transport と session の実装を増やす
3. Gateway / Voice の状態遷移を積み上げる
4. その上で、Bot 作者向け API を薄く整理する

この進め方にしている理由は、Discord まわりは最終的に WebSocket、Voice、UDP、RTP、暗号化まで連続してつながるためです。
上の層だけ先に作ると、あとで下の層の都合に引きずられやすくなります。なので、今は意図的に低レイヤを厚くしています。

## リポジトリ構成

```text
src/
  core/          client state, dispatcher, result helper
  json/          JSON validation と path reader
  net/           HTTP / transport / WebSocket
  gateway/       Gateway payload builder と event mapping
  voice/         voice session state と Voice まわりの土台
  rtp/           RTP packet と sequence / timestamp builder
  crypto/        voice encryption レイヤ
  opus/          Opus helper と今後の reader / encoder
  audio/         playback 側の抽象
  music/         queue と command helper
  copybooks/     共通 data definition

examples/        段階別の example program
tests/           実行可能な COBOL test
docs/            API note と roadmap
```

## 想定している API の形

最終的な利用側 API は、COBOL から素直に呼べる形を目指しています。

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

この上位 API はまだ完成ではありませんが、下支えになる transport と protocol primitive はかなり揃ってきています。登録した handler program は `CALL handler USING DC-CLIENT DC-EVENT DC-RESULT` の形で呼ばれます。

## クイックスタート

### 必要環境

- GnuCOBOL
- `cobc`

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

Gateway 側の入口イメージは [examples/02-gateway-ready/main.cob](examples/02-gateway-ready/main.cob) を見ると掴みやすいです。

## 設定方針

Discord token はソースコードに埋め込まない方針です。

リポジトリには次を含めています。

- `.env.example`
- `.env` を除外する `.gitignore`

今後も、認証情報は環境変数や設定ファイル経由で扱う前提で整えていきます。

## どこから読むと追いやすいか

初見で追うなら、次の順番がおすすめです。

1. [docs/roadmap.md](docs/roadmap.md) で現在地を確認する
2. [docs/api.md](docs/api.md) で exposed API の断面を見る
3. `tests/` を読んで、各レイヤの期待動作を掴む
4. `src/net/` と `src/gateway/` を中心に実装を追う

「まず動くものを見たい」なら `tests/websocket-test.cob` と `tests/transport-test.cob` が入りやすいです。

## ロードマップ

近い優先項目は次の通りです。

1. Gateway reconnect / heartbeat 異常時のライフサイクルを厚くする
2. 音声暗号化を入れる
3. Slash command と playback workflow をつなぐ
4. 暗号化込みの end-to-end playback を成立させる
5. music bot の上位 example を増やす

長期目標は、Voice channel に参加して音声再生できる COBOL 製 Discord Music Bot です。

## コントリビュート

このプロジェクトはまだ探索段階ですが、次の種類の貢献はとても助かります。

- GnuCOBOL の挙動差や portability の検証
- parser / codec の edge case テスト
- Discord protocol compatibility の確認
- Gateway / Voice の状態遷移整理
- example と documentation の改善

小さめの変更でも、テストが一緒にあるとレビューしやすくなります。

## 関連ドキュメント

- 設計草案: [discord_cob_design.md](discord_cob_design.md)
- API note: [docs/api.md](docs/api.md)
- Roadmap: [docs/roadmap.md](docs/roadmap.md)

## ライセンス

このプロジェクトは MIT License で公開しています。詳細は [LICENSE](LICENSE) を参照してください。
