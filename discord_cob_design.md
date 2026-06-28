# discord.cob 設計書

## All COBOL Discord Bot Framework / Voice Music Bot 対応設計

---

## 1. プロジェクト概要

`discord.cob` は、COBOLのみでDiscord Botを開発するためのライブラリである。

本プロジェクトの最終目標は、COBOLでDiscordのVoice Channelに接続し、音楽再生Botを実装できる状態にすることである。

JavaScriptにおける `discord.js` のように、Discord APIの複雑な通信処理を隠蔽し、COBOL側では手続き型の分かりやすいAPIでBotを開発できることを目指す。

---

## 2. 基本方針

### 2.1 All COBOL方針

`discord.cob` では、原則として人間が書くソースコードをすべてCOBOLに統一する。

以下の処理もCOBOLで実装する。

- HTTP Client
- TLS Client
- WebSocket Client
- JSON Parser
- Discord Gateway Client
- Slash Command / Interaction Handler
- Voice Gateway Client
- UDP通信
- RTP Packet生成
- Voice暗号化
- Opus Packet Reader
- Audio Player
- Music Queue
- Music Bot本体

### 2.2 Cアダプタ禁止

本プロジェクトでは、以下のようなC補助モジュールは作成しない。

```text
dc_http.c
dc_ws.c
dc_udp.c
dc_opus.c
dc_crypto.c
```

ただし、GnuCOBOLなどの処理系が内部的にCOBOLをCへ変換してビルドすることは許容する。

ここでいうAll COBOLとは、次の意味である。

```text
ライブラリとして人間が書くソースコードはCOBOLのみ。
Cによる補助モジュールは作らない。
低レベル処理も可能な限りCOBOLで実装する。
```

---

## 3. 目標

### 3.1 短期目標

- COBOLでJSONを解析できる
- COBOLでHTTP通信の構造を扱える
- COBOLでWebSocket Frameを扱える
- Discord Gatewayへ接続できる
- `READY` イベントを受信できる
- Slash Commandに応答できる

### 3.2 中期目標

- BotをVoice Channelに参加させる
- Voice Gatewayへ接続する
- UDP Discoveryを行う
- RTP Packetを生成する
- 無音Packetを送信する
- 暗号化済みVoice Packetを送信する

### 3.3 最終目標

- Opus音声をVoice Channelへ送信する
- `/play` `/skip` `/stop` `/queue` などを持つMusic Botを実装する
- COBOLだけでDiscord Voice Music Botを成立させる

---

## 4. ディレクトリ構成

```text
discord.cob/
├── src/
│   ├── core/
│   │   ├── dc-client.cob
│   │   ├── dc-event-loop.cob
│   │   ├── dc-dispatcher.cob
│   │   ├── dc-state.cob
│   │   ├── dc-error.cob
│   │   └── dc-logger.cob
│   │
│   ├── net/
│   │   ├── dc-tcp.cob
│   │   ├── dc-tls.cob
│   │   ├── dc-http.cob
│   │   ├── dc-websocket.cob
│   │   ├── dc-udp.cob
│   │   └── dc-url.cob
│   │
│   ├── json/
│   │   ├── dc-json-tokenizer.cob
│   │   ├── dc-json-parser.cob
│   │   ├── dc-json-path.cob
│   │   └── dc-json-writer.cob
│   │
│   ├── gateway/
│   │   ├── dc-gateway.cob
│   │   ├── dc-identify.cob
│   │   ├── dc-heartbeat.cob
│   │   ├── dc-resume.cob
│   │   └── dc-gateway-events.cob
│   │
│   ├── interactions/
│   │   ├── dc-interaction.cob
│   │   ├── dc-slash-command.cob
│   │   ├── dc-command-router.cob
│   │   └── dc-interaction-response.cob
│   │
│   ├── voice/
│   │   ├── dc-voice-manager.cob
│   │   ├── dc-voice-gateway.cob
│   │   ├── dc-voice-state.cob
│   │   ├── dc-voice-server.cob
│   │   ├── dc-voice-udp.cob
│   │   ├── dc-voice-heartbeat.cob
│   │   └── dc-speaking.cob
│   │
│   ├── rtp/
│   │   ├── dc-rtp-header.cob
│   │   ├── dc-rtp-packet.cob
│   │   ├── dc-rtp-sequence.cob
│   │   └── dc-rtp-timestamp.cob
│   │
│   ├── crypto/
│   │   ├── dc-crypto.cob
│   │   ├── dc-chacha20.cob
│   │   ├── dc-poly1305.cob
│   │   ├── dc-aead.cob
│   │   ├── dc-nonce.cob
│   │   └── dc-dave.cob
│   │
│   ├── opus/
│   │   ├── dc-opus-reader.cob
│   │   ├── dc-ogg-opus.cob
│   │   ├── dc-opus-frame.cob
│   │   ├── dc-opus-packet.cob
│   │   └── dc-opus-encoder.cob
│   │
│   ├── audio/
│   │   ├── dc-audio-source.cob
│   │   ├── dc-audio-player.cob
│   │   ├── dc-audio-clock.cob
│   │   └── dc-audio-buffer.cob
│   │
│   ├── music/
│   │   ├── dc-music-bot.cob
│   │   ├── dc-music-queue.cob
│   │   ├── dc-track.cob
│   │   ├── dc-nowplaying.cob
│   │   └── dc-music-commands.cob
│   │
│   └── copybooks/
│       ├── discord-client.cpy
│       ├── discord-result.cpy
│       ├── discord-event.cpy
│       ├── discord-interaction.cpy
│       ├── discord-voice.cpy
│       ├── discord-rtp.cpy
│       ├── discord-crypto.cpy
│       ├── discord-opus.cpy
│       └── discord-music.cpy
│
├── examples/
│   ├── 01-rest-message/
│   ├── 02-gateway-ready/
│   ├── 03-slash-command/
│   ├── 04-voice-join/
│   ├── 05-udp-discovery/
│   ├── 06-rtp-silence/
│   ├── 07-encrypted-rtp/
│   ├── 08-play-opus-file/
│   └── 09-music-bot/
│
├── tests/
├── docs/
├── Makefile
└── README.md
```

---

## 5. 全体アーキテクチャ

```text
COBOL User Bot
    |
    v
discord.cob Public API
    |
    +-- Core Layer
    |     +-- Client
    |     +-- Event Loop
    |     +-- Dispatcher
    |     +-- State Store
    |
    +-- Network Layer
    |     +-- TCP
    |     +-- TLS
    |     +-- HTTP
    |     +-- WebSocket
    |     +-- UDP
    |
    +-- Discord Gateway Layer
    |     +-- Identify
    |     +-- Heartbeat
    |     +-- Resume
    |     +-- Dispatch
    |
    +-- Interaction Layer
    |     +-- Slash Command
    |     +-- Interaction Reply
    |
    +-- Voice Layer
    |     +-- Voice State Update
    |     +-- Voice Gateway
    |     +-- UDP Discovery
    |     +-- Speaking State
    |
    +-- RTP Layer
    |     +-- RTP Header
    |     +-- Sequence
    |     +-- Timestamp
    |     +-- Packet Builder
    |
    +-- Crypto Layer
    |     +-- Nonce
    |     +-- AEAD
    |     +-- Voice Encryption
    |     +-- DAVE Future Layer
    |
    +-- Opus Layer
    |     +-- Opus Packet Reader
    |     +-- Ogg Opus Reader
    |     +-- Opus Encoder Future Layer
    |
    +-- Audio Layer
    |     +-- Audio Source
    |     +-- Audio Player
    |     +-- Audio Clock
    |
    +-- Music Layer
          +-- Queue
          +-- Player Control
          +-- Music Commands
```

---

## 6. 公開API設計

### 6.1 初期化

```cobol
CALL "DC-CLIENT-INIT"
    USING DC-CONFIG
          DC-CLIENT
          DC-RESULT.
```

```cobol
01 DC-CONFIG.
   05 DC-BOT-TOKEN              PIC X(256).
   05 DC-INTENTS                PIC 9(10) COMP-5.
   05 DC-LOG-LEVEL              PIC 9(2) COMP-5.
   05 DC-GATEWAY-VERSION        PIC 9(2) COMP-5 VALUE 10.
   05 DC-VOICE-GATEWAY-VERSION  PIC 9(2) COMP-5 VALUE 8.
   05 DC-AUDIO-FRAME-MS         PIC 9(2) COMP-5 VALUE 20.
   05 DC-AUDIO-SAMPLE-RATE      PIC 9(5) COMP-5 VALUE 48000.
   05 DC-AUDIO-CHANNELS         PIC 9 VALUE 2.
```

### 6.2 ログイン

```cobol
CALL "DC-LOGIN"
    USING DC-CLIENT
          DC-RESULT.
```

内部処理。

```text
1. Gateway URL取得
2. TLS接続
3. WebSocket接続
4. HELLO受信
5. Heartbeat開始
6. Identify送信
7. READY受信
8. Event Loop開始
```

### 6.3 イベント登録

```cobol
CALL "DC-ON"
    USING DC-CLIENT
          "READY"
          "APP-ON-READY"
          DC-RESULT.

CALL "DC-ON"
    USING DC-CLIENT
          "INTERACTION_CREATE"
          "APP-ON-INTERACTION"
          DC-RESULT.
```

COBOLでは関数オブジェクトを扱いにくいため、イベント名とCOBOLプログラム名を登録する方式にする。

### 6.4 Voice接続API

```cobol
CALL "DC-VOICE-JOIN"
    USING DC-CLIENT
          DC-GUILD-ID
          DC-VOICE-CHANNEL-ID
          DC-RESULT.
```

```cobol
CALL "DC-VOICE-LEAVE"
    USING DC-CLIENT
          DC-GUILD-ID
          DC-RESULT.
```

### 6.5 Music API

```cobol
CALL "DC-MUSIC-PLAY"
    USING DC-CLIENT
          DC-GUILD-ID
          DC-VOICE-CHANNEL-ID
          DC-AUDIO-SOURCE
          DC-RESULT.
```

```cobol
CALL "DC-MUSIC-SKIP"
    USING DC-CLIENT
          DC-GUILD-ID
          DC-RESULT.
```

```cobol
CALL "DC-MUSIC-STOP"
    USING DC-CLIENT
          DC-GUILD-ID
          DC-RESULT.
```

```cobol
CALL "DC-MUSIC-QUEUE-LIST"
    USING DC-CLIENT
          DC-GUILD-ID
          DC-MUSIC-QUEUE
          DC-RESULT.
```

---

## 7. Core設計

### 7.1 Client

`dc-client.cob` は、Bot全体の状態を保持する中心モジュールである。

```cobol
01 DC-CLIENT.
   05 DC-CLIENT-ID              PIC X(32).
   05 DC-CLIENT-USER-ID         PIC X(32).
   05 DC-CLIENT-TOKEN           PIC X(256).
   05 DC-CLIENT-STATE           PIC 9.
      88 CLIENT-INIT            VALUE 0.
      88 CLIENT-CONNECTING      VALUE 1.
      88 CLIENT-READY           VALUE 2.
      88 CLIENT-DISCONNECTED    VALUE 3.
   05 DC-CLIENT-SEQUENCE        PIC S9(10) COMP-5.
   05 DC-CLIENT-SESSION-ID      PIC X(128).
```

### 7.2 Event Dispatcher

イベント名に対して、実行するCOBOLプログラム名を登録する。

```cobol
01 DC-EVENT-HANDLER-TABLE.
   05 DC-HANDLER-COUNT          PIC 9(4) COMP-5.
   05 DC-HANDLER OCCURS 100 TIMES.
      10 DC-HANDLER-EVENT-NAME  PIC X(64).
      10 DC-HANDLER-PROGRAM     PIC X(64).
```

イベント発火時には以下のように呼び出す。

```cobol
CALL DC-HANDLER-PROGRAM
    USING DC-EVENT
          DC-RESULT.
```

---

## 8. Network Layer設計

### 8.1 TCP

`dc-tcp.cob` は、TCP接続の抽象化を行う。

役割。

```text
- TCP接続作成
- TCP送信
- TCP受信
- TCP切断
- タイムアウト管理
```

### 8.2 TLS

Discord GatewayやREST APIはTLSが必要になる。

All COBOLでTLSを実装する場合、以下が必要になる。

```text
- TLS Record Layer
- Client Hello
- Server Hello
- Certificate処理
- Key Exchange
- Key Schedule
- Application Data
- AEAD暗号
```

TLSは本プロジェクト最大級の難所である。

そのため、`dc-tls.cob` は独立したサブプロジェクトとしても成立する設計にする。

### 8.3 HTTP

`dc-http.cob` はHTTP/1.1クライアントを実装する。

必要機能。

```text
- GET
- POST
- PATCH
- DELETE
- Header生成
- Body送信
- Status Code解析
- Header解析
- Content-Length対応
- Chunked Transfer Encoding対応
- Rate Limit Header解析
```

API例。

```cobol
CALL "DC-HTTP-POST"
    USING DC-HTTP-REQUEST
          DC-HTTP-RESPONSE
          DC-RESULT.
```

### 8.4 WebSocket

Gateway接続のためにWebSocket Clientを実装する。

必要機能。

```text
- HTTP Upgrade Request
- Sec-WebSocket-Key生成
- Sec-WebSocket-Accept検証
- Frame生成
- Mask処理
- Text Frame
- Binary Frame
- Ping
- Pong
- Close
- Fragment対応
```

API例。

```cobol
CALL "DC-WS-CONNECT"
    USING DC-WS-REQUEST
          DC-WS-SESSION
          DC-RESULT.

CALL "DC-WS-SEND-TEXT"
    USING DC-WS-SESSION
          DC-WS-PAYLOAD
          DC-RESULT.

CALL "DC-WS-RECV"
    USING DC-WS-SESSION
          DC-WS-FRAME
          DC-RESULT.
```

### 8.5 UDP

Voice通信ではUDPが必要になる。

`dc-udp.cob` はUDP通信を担当する。

必要機能。

```text
- UDP Socket作成
- UDP送信
- UDP受信
- Remote Host / Port管理
- Local IP / Port管理
- タイムアウト管理
```

API例。

```cobol
CALL "DC-UDP-OPEN"
    USING DC-UDP-SESSION
          DC-RESULT.

CALL "DC-UDP-SEND"
    USING DC-UDP-SESSION
          DC-UDP-PACKET
          DC-RESULT.

CALL "DC-UDP-RECV"
    USING DC-UDP-SESSION
          DC-UDP-PACKET
          DC-RESULT.
```

---

## 9. JSON設計

Discord APIはJSON中心である。

COBOLの固定長データ構造とJSONは相性が悪いため、最初は完全なDOMではなく、必要な値をPathで取り出す方式にする。

### 9.1 JSON Tokenizer

扱うToken。

```text
{
}
[
]
:
,
string
number
true
false
null
```

### 9.2 JSON Path Reader

対応するPath例。

```text
$.op
$.t
$.s
$.d.heartbeat_interval
$.d.session_id
$.d.guild_id
$.d.channel_id
$.d.token
$.d.endpoint
$.d.ssrc
```

API例。

```cobol
CALL "DC-JSON-GET-STRING"
    USING JSON-BUFFER
          "$.d.token"
          OUT-VALUE
          DC-RESULT.
```

```cobol
CALL "DC-JSON-GET-NUMBER"
    USING JSON-BUFFER
          "$.d.ssrc"
          OUT-NUMBER
          DC-RESULT.
```

---

## 10. Discord Gateway設計

### 10.1 Gateway接続フロー

```text
DC-LOGIN
  ↓
Get Gateway URL
  ↓
TLS Connect
  ↓
WebSocket Connect
  ↓
Receive HELLO
  ↓
Start Heartbeat
  ↓
Send IDENTIFY
  ↓
Receive READY
  ↓
Dispatch Loop
```

### 10.2 Gateway State

```cobol
01 DC-GATEWAY-STATE.
   05 DC-GW-URL                 PIC X(256).
   05 DC-GW-SESSION-ID          PIC X(128).
   05 DC-GW-SEQUENCE            PIC S9(10) COMP-5.
   05 DC-GW-HEARTBEAT-INTERVAL  PIC 9(10) COMP-5.
   05 DC-GW-LAST-ACK-FLAG       PIC 9 VALUE 1.
   05 DC-GW-STATE               PIC 9.
      88 GW-DISCONNECTED        VALUE 0.
      88 GW-CONNECTING          VALUE 1.
      88 GW-IDENTIFYING         VALUE 2.
      88 GW-READY               VALUE 3.
      88 GW-RECONNECTING        VALUE 4.
```

### 10.3 Heartbeat

```text
1. HELLOからheartbeat_intervalを取得
2. intervalごとにHeartbeat送信
3. Heartbeat ACKを待つ
4. ACKが来なければ再接続
5. sequence番号を保存
6. Resumeを試す
```

### 10.4 Identify

Identify Payloadには以下を含める。

```text
token
intents
properties
presence
```

Music Botでは、基本的にSlash Command中心にするため、Message Content Intentには依存しない設計にする。

---

## 11. Interaction / Slash Command設計

Music BotではPrefix CommandではなくSlash Commandを中心にする。

理由。

```text
- Message Content Intentへの依存を減らせる
- Discord上のUIとして使いやすい
- コマンド構造が明確になる
- 将来的にAutocompleteへ拡張しやすい
```

### 11.1 対応コマンド

```text
/join
/leave
/play file:<path>
/pause
/resume
/skip
/stop
/queue
/nowplaying
```

### 11.2 Command Router

```cobol
EVALUATE DC-COMMAND-NAME
    WHEN "/join"
        CALL "DC-MUSIC-CMD-JOIN"
            USING DC-INTERACTION
                  DC-RESULT

    WHEN "/play"
        CALL "DC-MUSIC-CMD-PLAY"
            USING DC-INTERACTION
                  DC-RESULT

    WHEN "/skip"
        CALL "DC-MUSIC-CMD-SKIP"
            USING DC-INTERACTION
                  DC-RESULT

    WHEN "/stop"
        CALL "DC-MUSIC-CMD-STOP"
            USING DC-INTERACTION
                  DC-RESULT
END-EVALUATE.
```

---

## 12. Voice設計

### 12.1 Voice接続全体フロー

DiscordのVoice接続は、通常GatewayとVoice Gatewayの2段階で行う。

```text
/play or /join
    ↓
Main Gatewayへ Voice State Update 送信
    ↓
VOICE_STATE_UPDATE 受信
    ↓
VOICE_SERVER_UPDATE 受信
    ↓
Voice Gateway URL構築
    ↓
Voice GatewayへWebSocket接続
    ↓
Voice Identify送信
    ↓
Voice Hello受信
    ↓
Voice Heartbeat開始
    ↓
Voice Ready受信
    ↓
UDP Discovery
    ↓
Select Protocol送信
    ↓
Session Description受信
    ↓
Secret Key保存
    ↓
Speaking送信
    ↓
RTP + encrypted Opus audio をUDP送信
```

### 12.2 Voice Manager

`dc-voice-manager.cob` はGuildごとのVoice接続状態を管理する。

役割。

```text
- GuildごとのVoice Session保持
- Join / Leave処理
- Voice Gateway接続管理
- UDP Session管理
- 再接続管理
- Music Playerとの橋渡し
```

### 12.3 Voice Session構造

```cobol
01 DC-VOICE-SESSION.
   05 DC-VS-GUILD-ID             PIC X(32).
   05 DC-VS-CHANNEL-ID           PIC X(32).
   05 DC-VS-SESSION-ID           PIC X(128).
   05 DC-VS-TOKEN                PIC X(256).
   05 DC-VS-ENDPOINT             PIC X(256).
   05 DC-VS-GATEWAY-URL          PIC X(256).
   05 DC-VS-SSRC                 PIC 9(10) COMP-5.
   05 DC-VS-SECRET-KEY           PIC X(128).
   05 DC-VS-READY-FLAG           PIC 9 VALUE 0.
   05 DC-VS-UDP-READY-FLAG       PIC 9 VALUE 0.
   05 DC-VS-ENCRYPTION-MODE      PIC X(64).
   05 DC-VS-STATE                PIC 9.
      88 VS-DISCONNECTED         VALUE 0.
      88 VS-WAITING-EVENTS       VALUE 1.
      88 VS-GATEWAY-CONNECTING   VALUE 2.
      88 VS-UDP-DISCOVERING      VALUE 3.
      88 VS-READY                VALUE 4.
      88 VS-RECONNECTING         VALUE 5.
```

### 12.4 VOICE_STATE_UPDATE / VOICE_SERVER_UPDATE

Voice接続には、通常Gatewayから以下2つのイベントが必要である。

```text
VOICE_STATE_UPDATE:
  session_id を取得する

VOICE_SERVER_UPDATE:
  voice token と endpoint を取得する
```

どちらが先に届くかは固定しない。

そのため、両方が揃うまでVoice Gateway接続を開始しない。

```cobol
IF DC-HAS-VOICE-STATE = 1
   AND DC-HAS-VOICE-SERVER = 1
   CALL "DC-VOICE-GATEWAY-CONNECT"
       USING DC-VOICE-SESSION
             DC-RESULT
END-IF.
```

---

## 13. Voice Gateway設計

### 13.1 Voice Gateway Client

`dc-voice-gateway.cob` の役割。

```text
- Voice GatewayへのWebSocket接続
- Voice Identify送信
- Voice Hello受信
- Voice Heartbeat管理
- Voice Ready受信
- Select Protocol送信
- Session Description受信
- Speaking送信
- Voice Gateway再接続
```

### 13.2 Voice Identify

Voice Gateway接続後、以下の情報を送る。

```text
server_id
user_id
session_id
token
```

COBOL構造。

```cobol
01 DC-VOICE-IDENTIFY.
   05 DC-VI-SERVER-ID           PIC X(32).
   05 DC-VI-USER-ID             PIC X(32).
   05 DC-VI-SESSION-ID          PIC X(128).
   05 DC-VI-TOKEN               PIC X(256).
```

### 13.3 Voice Heartbeat

通常Gatewayとは別に、Voice GatewayにもHeartbeatを送る。

```cobol
01 DC-VOICE-HEARTBEAT.
   05 DC-VH-INTERVAL-MS         PIC 9(10) COMP-5.
   05 DC-VH-LAST-NONCE          PIC 9(18) COMP-5.
   05 DC-VH-LAST-ACK-FLAG       PIC 9 VALUE 1.
   05 DC-VH-RECONNECT-FLAG      PIC 9 VALUE 0.
```

### 13.4 Voice Ready

Voice Readyでは、主に以下を取得する。

```text
ssrc
ip
port
modes
heartbeat_interval
```

このうち、`ssrc` はRTP Packet生成に必要である。

### 13.5 Select Protocol

UDP Discovery後、Voice Gatewayへ使用するIP、Port、暗号化モードを通知する。

```cobol
01 DC-SELECT-PROTOCOL.
   05 DC-SP-PROTOCOL            PIC X(16) VALUE "udp".
   05 DC-SP-ADDRESS             PIC X(64).
   05 DC-SP-PORT                PIC 9(5) COMP-5.
   05 DC-SP-MODE                PIC X(64).
```

### 13.6 Speaking

音声送信前にSpeaking状態を送る。

```cobol
01 DC-SPEAKING-PAYLOAD.
   05 DC-SPEAKING-FLAG          PIC 9 VALUE 1.
   05 DC-SPEAKING-DELAY         PIC 9(10) COMP-5 VALUE 0.
   05 DC-SPEAKING-SSRC          PIC 9(10) COMP-5.
```

---

## 14. UDP設計

### 14.1 UDP Layerの役割

`dc-udp.cob` と `dc-voice-udp.cob` でUDP通信を扱う。

役割。

```text
- UDPソケット作成
- Voice ServerへのUDP送信
- UDP受信
- IP Discovery Packet送信
- IP Discovery Response解析
- RTP Packet送信
- UDP Keepalive
```

### 14.2 UDP Session構造

```cobol
01 DC-UDP-SESSION.
   05 DC-UDP-HANDLE             PIC 9(10) COMP-5.
   05 DC-UDP-REMOTE-HOST        PIC X(256).
   05 DC-UDP-REMOTE-PORT        PIC 9(5) COMP-5.
   05 DC-UDP-LOCAL-IP           PIC X(64).
   05 DC-UDP-LOCAL-PORT         PIC 9(5) COMP-5.
   05 DC-UDP-READY-FLAG         PIC 9 VALUE 0.
```

### 14.3 UDP Discovery

Voice Readyで得られるSSRCを使い、UDP Discoveryを行う。

```text
1. Voice ServerへDiscovery Packetを送信
2. 返ってきたPacketから外部IPとPortを取得
3. そのIPとPortをSelect ProtocolでVoice Gatewayに送る
```

構造。

```cobol
01 DC-UDP-DISCOVERY.
   05 DC-UD-PACKET              PIC X(74).
   05 DC-UD-SSRC                PIC 9(10) COMP-5.
   05 DC-UD-DISCOVERED-IP       PIC X(64).
   05 DC-UD-DISCOVERED-PORT     PIC 9(5) COMP-5.
```

### 14.4 UDP Packet構造

```cobol
01 DC-UDP-PACKET.
   05 DC-UDP-PACKET-LENGTH      PIC 9(5) COMP-5.
   05 DC-UDP-PACKET-DATA        PIC X(4096).
```

---

## 15. RTP設計

### 15.1 RTPの役割

Discord Voiceへ送る音声は、RTP Headerの後ろに暗号化済みOpus音声データを付けた形で送る。

```text
UDP Payload
    |
    +-- RTP Header
    |
    +-- Encrypted Opus Audio
```

### 15.2 RTP Header

基本RTP Headerは12 bytes。

```text
Byte 0      : Version / Padding / Extension / CSRC Count
Byte 1      : Marker / Payload Type
Byte 2-3    : Sequence Number
Byte 4-7    : Timestamp
Byte 8-11   : SSRC
```

COBOL構造。

```cobol
01 DC-RTP-HEADER.
   05 DC-RTP-BYTE-0             PIC X.
   05 DC-RTP-BYTE-1             PIC X.
   05 DC-RTP-SEQUENCE-BYTES     PIC X(2).
   05 DC-RTP-TIMESTAMP-BYTES    PIC X(4).
   05 DC-RTP-SSRC-BYTES         PIC X(4).
```

### 15.3 RTP State

```cobol
01 DC-RTP-STATE.
   05 DC-RTP-SEQUENCE           PIC 9(10) COMP-5.
   05 DC-RTP-TIMESTAMP          PIC 9(10) COMP-5.
   05 DC-RTP-SSRC               PIC 9(10) COMP-5.
   05 DC-RTP-FRAME-SAMPLES      PIC 9(10) COMP-5 VALUE 960.
```

20msフレーム、48kHz音声の場合、1フレームごとにtimestampを960進める。

```text
sequence  = sequence + 1
timestamp = timestamp + 960
```

### 15.4 RTP Packet Builder

```cobol
CALL "DC-RTP-BUILD-PACKET"
    USING DC-RTP-STATE
          DC-OPUS-FRAME
          DC-ENCRYPTED-PACKET
          DC-RESULT.
```

処理。

```text
1. RTP Header生成
2. Opus Frame取得
3. RTP Headerを追加認証データとして扱う
4. Opus部分を暗号化
5. UDP送信用Packetを生成
```

### 15.5 RTP Advance

送信成功後、RTP状態を進める。

```cobol
CALL "DC-RTP-ADVANCE"
    USING DC-RTP-STATE
          DC-RESULT.
```

内部処理。

```text
sequence  = sequence + 1
timestamp = timestamp + 960
```

---

## 16. 暗号化設計

### 16.1 Crypto Layerの役割

`crypto/` はDiscord Voice送信に必要な暗号化を担当する。

```text
crypto/
├── dc-crypto.cob
├── dc-chacha20.cob
├── dc-poly1305.cob
├── dc-aead.cob
├── dc-nonce.cob
└── dc-dave.cob
```

### 16.2 暗号化の基本方針

Voice GatewayのSession Descriptionで受け取ったSecret Keyを保存し、RTP HeaderとOpus Frameを使って暗号化済みPacketを作る。

```text
RTP Header
    +
Opus Frame
    +
Secret Key
    +
Nonce
    ↓
Encrypted Voice Packet
```

### 16.3 AEAD設計

AEADでは以下を扱う。

```text
- key
- nonce
- plaintext
- associated data
- ciphertext
- authentication tag
```

COBOL構造。

```cobol
01 DC-AEAD-CONTEXT.
   05 DC-AEAD-KEY               PIC X(64).
   05 DC-AEAD-NONCE             PIC X(24).
   05 DC-AEAD-AAD               PIC X(64).
   05 DC-AEAD-PLAINTEXT         PIC X(4096).
   05 DC-AEAD-CIPHERTEXT        PIC X(4096).
   05 DC-AEAD-TAG               PIC X(32).
```

### 16.4 Nonce管理

Nonceは暗号化モードに応じて生成方法を分ける。

```text
- RTP Header由来
- Counter由来
- Random由来
- RTP Size AEAD用
```

```cobol
01 DC-NONCE-STATE.
   05 DC-NONCE-COUNTER          PIC 9(18) COMP-5.
   05 DC-NONCE-BUFFER           PIC X(24).
```

### 16.5 ChaCha20 / Poly1305

All COBOL方針では、以下もCOBOLで実装する。

```text
dc-chacha20.cob:
  - Quarter Round
  - Block Function
  - Key Stream生成
  - XOR処理

dc-poly1305.cob:
  - One-time key処理
  - Message block処理
  - Tag生成

dc-aead.cob:
  - ChaCha20-Poly1305構成
  - AAD処理
  - Tag付与
```

### 16.6 Crypto API

```cobol
CALL "DC-CRYPTO-ENCRYPT-VOICE"
    USING DC-VOICE-SESSION
          DC-RTP-HEADER
          DC-OPUS-FRAME
          DC-ENCRYPTED-PACKET
          DC-RESULT.
```

内部処理。

```text
1. 暗号化モードを確認
2. Nonceを生成
3. RTP HeaderをAADに設定
4. Opus Frameを暗号化
5. Authentication Tagを付与
6. Packetを返す
```

### 16.7 DAVE対応層

将来的なDiscord Voice仕様変更に備え、DAVE対応用の抽象層を用意する。

初期段階では未実装でもよい。

```cobol
01 DC-DAVE-STATE.
   05 DC-DAVE-ENABLED-FLAG      PIC 9 VALUE 0.
   05 DC-DAVE-PROTOCOL-VERSION  PIC 9(4) COMP-5.
   05 DC-DAVE-KEY-MATERIAL      PIC X(512).
   05 DC-DAVE-READY-FLAG        PIC 9 VALUE 0.
```

役割。

```text
- DAVE対応の有無を判定
- DAVE関連Payloadの保持
- 将来的な鍵交換処理
- 将来的なE2EE処理
- 通常Voice Encryptionとの切り替え
```

---

## 17. Opus設計

### 17.1 Opus Layerの方針

All COBOLで完全なOpus Encoderを最初から作るのは非常に重い。

そのため、段階的に実装する。

```text
Stage 1:
  事前にOpus化されたFrameを読み込んで送信

Stage 2:
  Ogg OpusファイルからOpus Packetを取り出す

Stage 3:
  WAV PCMを読み込む

Stage 4:
  COBOL製簡易Opus Encoderを作る

Stage 5:
  実用的な音楽再生に対応する
```

Music Botの初期版では、`.opus` または `.ogg opus` 内のOpus Packetを読み取って送信する。

### 17.2 Opus Frame構造

```cobol
01 DC-OPUS-FRAME.
   05 DC-OPUS-LENGTH            PIC 9(5) COMP-5.
   05 DC-OPUS-DATA              PIC X(4096).
   05 DC-OPUS-DURATION-MS       PIC 9(3) COMP-5 VALUE 20.
```

### 17.3 Opus Reader API

```cobol
CALL "DC-OPUS-OPEN"
    USING DC-AUDIO-SOURCE
          DC-OPUS-HANDLE
          DC-RESULT.

CALL "DC-OPUS-READ-FRAME"
    USING DC-OPUS-HANDLE
          DC-OPUS-FRAME
          DC-RESULT.
```

処理。

```text
1. Opusファイルを開く
2. Headerを読む
3. Packet境界を検出する
4. 20ms単位でFrameを返す
5. EOFなら再生終了を返す
```

### 17.4 Ogg Opus Reader

Ogg Opus対応では以下を読む。

```text
- Ogg Page Header
- Segment Table
- OpusHead
- OpusTags
- Opus Packet
```

初期版では、完全なOgg仕様対応ではなく、Discord送信用の最低限のPacket抽出を目指す。

### 17.5 Opus Encoder

最終的にはCOBOL製Opus Encoderを目指すが、これは別サブプロジェクト級の難易度になる。

そのため、`dc-opus-encoder.cob` は以下の段階で作る。

```text
Encoder-0:
  未実装。エラーを返す。

Encoder-1:
  無音フレーム生成。

Encoder-2:
  固定パターン音声のOpus Packet生成。

Encoder-3:
  PCMからOpus風Packet生成の研究実装。

Encoder-4:
  実用Opus Encoderへ拡張。
```

---

## 18. Audio Player設計

### 18.1 Audio Playerの役割

`dc-audio-player.cob` は、Opus FrameをRTP Packetとして一定間隔で送信する。

役割。

```text
- 再生状態管理
- Opus Frame読み込み
- 20ms間隔の送信制御
- RTP Packet生成
- 暗号化
- UDP送信
- pause / resume / stop
- 再生終了検知
```

### 18.2 Player State

```cobol
01 DC-AUDIO-PLAYER.
   05 DC-PLAYER-STATE           PIC 9.
      88 PLAYER-IDLE            VALUE 0.
      88 PLAYER-PLAYING         VALUE 1.
      88 PLAYER-PAUSED          VALUE 2.
      88 PLAYER-STOPPED         VALUE 3.
   05 DC-PLAYER-GUILD-ID        PIC X(32).
   05 DC-PLAYER-TRACK-ID        PIC X(64).
   05 DC-PLAYER-FRAME-COUNT     PIC 9(10) COMP-5.
   05 DC-PLAYER-VOLUME          PIC 9(3) VALUE 100.
   05 DC-PLAYER-EOF-FLAG        PIC 9 VALUE 0.
```

### 18.3 送信ループ

```text
WHILE PLAYER-PLAYING
    1. Opus Frameを読む
    2. RTP Headerを生成
    3. Opus Frameを暗号化
    4. UDP Packetとして送信
    5. sequenceを+1
    6. timestampを+960
    7. 20ms待機
END-WHILE
```

COBOL上では、厳密な20ms制御が難しい可能性があるため、初期版では多少の誤差を許容する。

実用段階では、送信時刻を記録し、次フレームまでの差分で補正する。

### 18.4 Voice Frame送信API

```cobol
CALL "DC-VOICE-SEND-FRAME"
    USING DC-VOICE-SESSION
          DC-RTP-STATE
          DC-OPUS-FRAME
          DC-RESULT.
```

内部処理。

```text
1. DC-RTP-BUILD-HEADER
2. DC-CRYPTO-ENCRYPT-VOICE
3. DC-UDP-SEND
4. DC-RTP-ADVANCE
```

---

## 19. Music Bot設計

### 19.1 初期対応コマンド

```text
/join
/leave
/play file:<path>
/pause
/resume
/skip
/stop
/queue
/nowplaying
```

初期版では `/play file:<path>` のみ対応する。

YouTubeや外部URL再生は後回しにする。

### 19.2 Music Queue

```cobol
01 DC-MUSIC-QUEUE.
   05 DC-MQ-GUILD-ID            PIC X(32).
   05 DC-MQ-SIZE                PIC 9(4) COMP-5.
   05 DC-MQ-HEAD                PIC 9(4) COMP-5.
   05 DC-MQ-TAIL                PIC 9(4) COMP-5.
   05 DC-MQ-TRACK OCCURS 100 TIMES.
      10 DC-MQ-TRACK-ID         PIC X(64).
      10 DC-MQ-TITLE            PIC X(128).
      10 DC-MQ-SOURCE           PIC X(512).
      10 DC-MQ-REQUESTER-ID     PIC X(32).
      10 DC-MQ-STATUS           PIC 9.
```

### 19.3 Track構造

```cobol
01 DC-MUSIC-TRACK.
   05 DC-TRACK-ID               PIC X(64).
   05 DC-TRACK-TITLE            PIC X(128).
   05 DC-TRACK-SOURCE           PIC X(512).
   05 DC-TRACK-DURATION-MS      PIC 9(12) COMP-5.
   05 DC-TRACK-REQUESTER-ID     PIC X(32).
   05 DC-TRACK-STATUS           PIC 9.
      88 TRACK-WAITING          VALUE 0.
      88 TRACK-PLAYING          VALUE 1.
      88 TRACK-FINISHED         VALUE 2.
      88 TRACK-ERROR            VALUE 3.
```

### 19.4 `/play`処理

```text
1. Interaction受信
2. ユーザーがVCにいるか確認
3. Botが未接続ならVoice Join
4. TrackをQueueに追加
5. 再生中でなければAudio Player開始
6. Interactionへ返信
```

COBOL疑似コード。

```cobol
IF DC-COMMAND-NAME = "/play"
    CALL "DC-INTERACTION-GET-OPTION"
        USING DC-INTERACTION
              "file"
              DC-AUDIO-SOURCE
              DC-RESULT

    CALL "DC-MUSIC-PLAY"
        USING DC-CLIENT
              DC-GUILD-ID
              DC-USER-VOICE-CHANNEL-ID
              DC-AUDIO-SOURCE
              DC-RESULT
END-IF.
```

---

## 20. Voice Packet送信詳細

### 20.1 送信Packet構造

```text
UDP Packet
    |
    +-- RTP Header, 12 bytes
    |
    +-- Encrypted Opus Payload
    |
    +-- Auth Tag / Suffix if required by mode
```

### 20.2 送信処理

```text
1. Opus Frame取得
2. RTP Header作成
3. Nonce作成
4. Opus Frame暗号化
5. RTP Header + Ciphertext + Tag を結合
6. UDPでVoice Serverへ送信
```

### 20.3 送信モジュール依存関係

```text
dc-audio-player.cob
    ↓
dc-opus-reader.cob
    ↓
dc-rtp-packet.cob
    ↓
dc-crypto.cob
    ↓
dc-udp.cob
```

---

## 21. エラー設計

すべての公開APIは `DC-RESULT` を返す。

```cobol
01 DC-RESULT.
   05 DC-STATUS-CODE            PIC S9(9) COMP-5.
   05 DC-ERROR-CODE             PIC X(64).
   05 DC-ERROR-MESSAGE          PIC X(256).
```

### 21.1 代表的なエラー

```text
DC_OK
DC_ERR_HTTP
DC_ERR_TLS
DC_ERR_WEBSOCKET
DC_ERR_GATEWAY_CLOSED
DC_ERR_JSON_PARSE
DC_ERR_INTERACTION
DC_ERR_VOICE_STATE_TIMEOUT
DC_ERR_VOICE_SERVER_TIMEOUT
DC_ERR_VOICE_GATEWAY
DC_ERR_UDP_SOCKET
DC_ERR_UDP_DISCOVERY
DC_ERR_RTP_BUILD
DC_ERR_CRYPTO_MODE
DC_ERR_CRYPTO_FAILED
DC_ERR_DAVE_REQUIRED
DC_ERR_OPUS_READ
DC_ERR_OPUS_UNSUPPORTED
DC_ERR_AUDIO_TIMING
DC_ERR_MUSIC_QUEUE_FULL
DC_ERR_MUSIC_NOT_CONNECTED
```

---

## 22. セキュリティ設計

### 22.1 Token管理

Bot Tokenはソースコードへ直書きしない。

方針。

```text
- 環境変数から読み込む
- .envはGit管理しない
- ログにTokenを出さない
- エラー表示でもTokenをマスクする
```

### 22.2 コマンド権限

Music Botは荒らしに使われる可能性があるため、権限管理を行う。

```text
- 管理者限定コマンド
- 使用可能ロール設定
- /stop /leave /skip の権限チェック
- キュー追加数制限
- 同時再生制限
```

### 22.3 音源の扱い

初期版では、以下の音源のみを対象とする。

```text
- ローカルの .opus ファイル
- 自作音源
- 使用許諾のある音源
- テスト用音源
```

YouTube等の外部サービス連携は初期実装では扱わない。

---

## 23. ロードマップ

### Phase 0：Core

```text
- Copybook整備
- Error構造
- Logger
- Event Dispatcher
- State Store
```

成果物。

```text
examples/00-core-test
```

### Phase 1：JSON

```text
- JSON Tokenizer
- JSON Parser
- JSON Path Reader
- JSON Writer
```

成果物。

```text
tests/json-parser-test
```

### Phase 2：HTTP / TLS / WebSocket

```text
- HTTP Request生成
- HTTP Response解析
- TLS Client
- WebSocket Handshake
- WebSocket Frame
- Ping/Pong
```

成果物。

```text
examples/01-websocket-echo
```

### Phase 3：Discord Gateway

```text
- Gateway URL取得
- Gateway接続
- Hello受信
- Heartbeat
- Identify
- READY受信
- Dispatch
- Resume
```

成果物。

```text
examples/02-gateway-ready
```

### Phase 4：Interactions

```text
- Slash Command登録
- Interaction受信
- Interaction Reply
- Command Router
```

成果物。

```text
examples/03-slash-command
```

### Phase 5：Voice Join

```text
- Voice State Update送信
- VOICE_STATE_UPDATE受信
- VOICE_SERVER_UPDATE受信
- Voice Gateway接続
- Voice Identify
- Voice Heartbeat
- Voice Ready
```

成果物。

```text
examples/04-voice-join
```

### Phase 6：UDP Discovery

```text
- UDP Socket
- Discovery Packet作成
- Discovery Response解析
- Select Protocol送信
- Session Description受信
```

成果物。

```text
examples/05-udp-discovery
```

### Phase 7：RTP

```text
- RTP Header生成
- Sequence管理
- Timestamp管理
- SSRC管理
- 無音Packet生成
```

成果物。

```text
examples/06-rtp-silence
```

### Phase 8：暗号化

```text
- Nonce生成
- ChaCha20
- Poly1305
- AEAD
- Voice Packet Encryption
- DAVE対応層の土台
```

成果物。

```text
examples/07-encrypted-rtp
```

### Phase 9：Opus Packet送信

```text
- Opus Frame Reader
- Ogg Opus Packet Reader
- 20ms Frame管理
- RTP + 暗号化 + UDP送信
```

成果物。

```text
examples/08-play-opus-file
```

### Phase 10：Music Bot

```text
- /join
- /play
- /pause
- /resume
- /skip
- /stop
- /queue
- /leave
- Queue管理
- 自動再生
- 自動退出
```

成果物。

```text
examples/09-music-bot
```

### Phase 11：Opus Encoder研究

```text
- WAV PCM Reader
- PCM Frame分割
- COBOL製Opus Encoder研究
- 実用化検討
```

成果物。

```text
src/opus/dc-opus-encoder.cob
```

---

## 24. 最初の実装目標

最初からMusic Bot完成を狙わず、以下の順で進める。

```text
1. JSON Parser
2. HTTP Response Parser
3. WebSocket Echo Client
4. Discord Gateway READY受信
5. Slash Command /ping
6. Voice Join
7. UDP Discovery
8. RTP無音送信
9. 暗号化RTP送信
10. Opusファイル再生
11. Music Bot
```

---

## 25. 初期版の制限

初期版のMusic Botは以下の制限を持つ。

```text
- /play はローカルの .opus または .ogg opus のみ
- YouTube再生は非対応
- MP3デコードは非対応
- Opusエンコードは非対応
- DAVEは設計のみ
- Voice暗号化方式の変化に追従する必要あり
```

---

## 26. 完成時の利用イメージ

### 26.1 Music Bot本体

```cobol
IDENTIFICATION DIVISION.
PROGRAM-ID. MUSIC-BOT.

DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "discord-client.cpy".
COPY "discord-result.cpy".
COPY "discord-music.cpy".

PROCEDURE DIVISION.
MAIN.
    MOVE FUNCTION GET-ENVIRONMENT("DISCORD_TOKEN")
        TO DC-BOT-TOKEN

    MOVE 129 TO DC-INTENTS

    CALL "DC-CLIENT-INIT"
        USING DC-CONFIG
              DC-CLIENT
              DC-RESULT

    CALL "DC-ON"
        USING DC-CLIENT
              "READY"
              "ON-READY"
              DC-RESULT

    CALL "DC-ON"
        USING DC-CLIENT
              "INTERACTION_CREATE"
              "ON-INTERACTION"
              DC-RESULT

    CALL "DC-LOGIN"
        USING DC-CLIENT
              DC-RESULT

    STOP RUN.
```

### 26.2 Interaction Handler

```cobol
IDENTIFICATION DIVISION.
PROGRAM-ID. ON-INTERACTION.

DATA DIVISION.
LINKAGE SECTION.
COPY "discord-interaction.cpy".
COPY "discord-result.cpy".

PROCEDURE DIVISION USING DC-INTERACTION DC-RESULT.
MAIN.
    EVALUATE DC-COMMAND-NAME
        WHEN "/play"
            CALL "DC-MUSIC-PLAY"
                USING DC-CLIENT
                      DC-GUILD-ID
                      DC-USER-VOICE-CHANNEL-ID
                      DC-COMMAND-OPTION-1
                      DC-RESULT

        WHEN "/skip"
            CALL "DC-MUSIC-SKIP"
                USING DC-CLIENT
                      DC-GUILD-ID
                      DC-RESULT

        WHEN "/stop"
            CALL "DC-MUSIC-STOP"
                USING DC-CLIENT
                      DC-GUILD-ID
                      DC-RESULT

        WHEN "/leave"
            CALL "DC-VOICE-LEAVE"
                USING DC-CLIENT
                      DC-GUILD-ID
                      DC-RESULT
    END-EVALUATE

    GOBACK.
```

---

## 27. 技術的難所

### 27.1 TLS

All COBOLでDiscordへ接続する最大の難所はTLSである。

TLSは単体で大きなプロジェクトになるため、`dc-tls.cob` は独立性を高く設計する。

### 27.2 UDP

COBOL標準だけではソケットAPIが弱いため、処理系依存の拡張が必要になる可能性がある。

ただし、Cソースを書くのではなく、COBOL側から処理系・OS機能を扱う方針にする。

### 27.3 Voice暗号化

Discord Voiceでは暗号化が必要になる。

COBOLでChaCha20、Poly1305、AEADを実装する必要がある。

### 27.4 Opus

完全なOpus EncoderをCOBOLで実装するのは非常に難しい。

そのため、初期版ではOpus Encoderではなく、Opus Packet Readerから始める。

---

## 28. パッケージ分割案

将来的には、以下のような独立パッケージとしても切り出せる。

```text
cobol-json
cobol-http
cobol-tls
cobol-websocket
cobol-udp
cobol-rtp
cobol-crypto
cobol-opus
discord.cob
```

これにより、`discord.cob` はDiscord Bot用ライブラリであると同時に、COBOLによる現代的通信ライブラリ群の中心にもなる。

---

## 29. まとめ

`discord.cob` は、COBOLでDiscord Botを作るだけでなく、COBOLで現代的なネットワーク通信・リアルタイム通信・音声通信を扱うことを示すプロジェクトである。

特に重要な構成要素は以下である。

```text
- Gateway
- Slash Command
- Voice Gateway
- UDP
- RTP
- Voice Encryption
- DAVE対応層
- Opus Packet Reader
- Audio Player
- Music Queue
```

最終目標はVC Music Botだが、最初の到達点は以下にする。

```text
COBOLでDiscord Gatewayに接続し、READYを受信する
```

次の到達点は以下。

```text
COBOLでVoice Channelに参加する
```

その次に以下を目指す。

```text
COBOLでRTP + encrypted Opus packetをUDP送信する
```

ここまで到達すれば、`discord.cob` は単なるネタではなく、COBOLによる本格的なDiscord Voiceライブラリとして成立する。

---

## 30. 参考情報

- Discord Developer Documentation: Gateway
- Discord Developer Documentation: Voice Connections
- GnuCOBOL Documentation
- WebSocket RFC 6455
- RTP RFC 3550
- Opus RFC 6716
- Ogg Opus RFC 7845
- ChaCha20-Poly1305 RFC 8439
