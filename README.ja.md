# discord.cob

[English README](README.md)

`discord.cob` は、COBOL で Discord Bot を構築するための実験的なオープンソースフレームワークです。
最終目標はかなり大きく、Discord Gateway、Voice、Music Bot の層を COBOL で実装しつつ、Bot 利用側には分かりやすい呼び出し型 API を提供することを目指しています。

現在のリポジトリは pre-alpha 段階です。パーサ、コーデック、キュー、RTP パケット生成などの土台は育ってきていますが、Discord への実接続や音声再生はまだ開発途中です。

## プロジェクトの狙い

このプロジェクトは次の 3 つを軸にしています。

- 人間が書く実装を COBOL に寄せる
- Discord の複雑なプロトコル処理をフレームワーク側に隠す
- 低レイヤから段階的に積み上げて、最終的に Voice Music Bot まで到達する

全体設計の草案は [discord_cob_design.md](discord_cob_design.md) にあります。

## 現在の実装状況

実装済み:

- Core の client state、result helper、event registration、dispatch
- Discord 風 JSON payload 向けの JSON validation と JSON path 抽出
- HTTP response parser、header lookup、基本的な chunked transfer decoding
- WebSocket frame encode/decode と masked frame decode
- RTP header / packet 生成
- Opus silence frame 生成
- Music queue と track helper

未実装または開発途中:

- TCP socket transport
- TLS client transport
- WebSocket handshake transport
- Discord Gateway session handling
- UDP voice transport
- Voice encryption
- Ogg Opus parsing
- 本格的な audio playback と music bot workflow

## このリポジトリの位置づけ

現時点の `discord.cob` は、次のように捉えるのがいちばん近いです。

- Discord protocol を COBOL で扱うための整理された研究用コードベース
- 将来の framework API に向けた土台
- COBOL で現代的な network / realtime protocol を扱うための実験場

まだ production-ready な Discord bot library ではありません。

## ディレクトリ構成

```text
src/
  core/          client state, dispatcher, result helper
  json/          JSON validation と path reader
  net/           HTTP / WebSocket codec と今後の transport layer
  gateway/       Gateway payload builder と event mapping
  voice/         voice session state と今後の UDP / gateway logic
  rtp/           RTP packet と sequence / timestamp builder
  crypto/        今後の voice encryption layer
  opus/          Opus helper と今後の reader / encoder
  audio/         playback 側の抽象
  music/         queue と command helper
  copybooks/     共通の COBOL data definition

examples/        phase ごとの example program
tests/           実行可能な COBOL test
docs/            API note と roadmap
```

## API の方向性

公開 API は、client 初期化と event dispatch を中心にした呼び出し型の形を想定しています。

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

この上位 API の骨格はすでにありますが、実際に Discord へ接続する transport や session flow はまだ実装中です。

## クイックスタート

### 必要環境

- GnuCOBOL と `cobc`

macOS で Homebrew を使う場合:

```sh
brew install gnucobol
```

### ビルド

```sh
make build
```

### テスト

```sh
make test
```

現時点のテスト:

- `core-test`
- `json-test`
- `http-test`
- `websocket-test`
- `rtp-test`
- `music-queue-test`

### サンプル実行

HTTP parser のサンプルは次で実行できます。

```sh
mkdir -p build/examples
cobc -free -Wall -I src/copybooks -x \
  -o build/examples/example-http \
  examples/01-rest-message/main.cob \
  $(find src -name '*.cob' | sort)
./build/examples/example-http
```

Bot の entrypoint イメージは [examples/02-gateway-ready/main.cob](examples/02-gateway-ready/main.cob) にあります。

## 設定方針

Discord token はソースコードへ直書きしない方針です。
リポジトリには次を含めています。

- `.env.example`
- `.env` を除外する `.gitignore`

最終的には環境変数ベースの設定を前提に整えていく予定です。

## ロードマップ

近い優先項目:

1. WebSocket handshake helper と `Sec-WebSocket-Accept` 検証
2. 最小限の Discord Gateway `HELLO` / `READY` handling
3. Slash command `/ping`
4. Voice join state handling
5. UDP discovery の土台
6. encrypted voice packet の土台

長期目標:

- Voice channel に参加して音声再生できる COBOL 製 Discord Music Bot

## 補足

このプロジェクトはかなり変わった挑戦です。狙っているのは、たとえば次のような問いです。

- COBOL で現代的な network protocol をどこまで扱えるか
- 手続き型の COBOL で Discord framework らしい API をどう設計するか
- Voice、RTP、暗号化の層を言語境界を増やさず扱えるか

そのため、実接続より前に parser や codec の層を先に厚くしている部分があります。

## ドキュメント

- 設計草案: [discord_cob_design.md](discord_cob_design.md)
- API note: [docs/api.md](docs/api.md)
- Roadmap: [docs/roadmap.md](docs/roadmap.md)

## コントリビュート

まだ探索段階ですが、次の領域の contribution はとても相性がいいです。

- COBOL portability と GnuCOBOL の挙動検証
- parser / codec の正確性
- Discord protocol compatibility
- protocol edge case 向けの test 追加
- example や documentation の改善

小さくてテスト付きの pull request から始めるのが自然です。

## ライセンス

このプロジェクトは MIT License で公開しています。詳細は [LICENSE](LICENSE) を参照してください。
