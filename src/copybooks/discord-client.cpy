      *> JP: アプリケーションが起動時に与える静的な設定です。
      *> EN: Static configuration supplied by the application at startup.
       01 DC-CONFIG.
          05 DC-BOT-TOKEN PIC X(256).
          05 DC-INTENTS PIC 9(10) COMP-5.
          05 DC-LOG-LEVEL PIC 9(2) COMP-5.
          05 DC-GATEWAY-VERSION PIC 9(2) COMP-5.
          05 DC-VOICE-GATEWAY-VERSION PIC 9(2) COMP-5.
          05 DC-AUDIO-FRAME-MS PIC 9(2) COMP-5.
          05 DC-AUDIO-SAMPLE-RATE PIC 9(5) COMP-5.
          05 DC-AUDIO-CHANNELS PIC 9.
          05 DC-MUSIC-IDLE-LEAVE-TICKS PIC 9(9) COMP-5.

      *> JP: DC-CLIENT は実行中の bot 状態をひとまとめに持つ中心構造です。
      *> EN: DC-CLIENT is the central runtime structure that carries bot state.
       01 DC-CLIENT.
      *> JP: Discord 上の bot identity と認証に関する情報です。
      *> EN: Bot identity and authentication-related fields.
          05 DC-CLIENT-ID PIC X(32).
          05 DC-CLIENT-USER-ID PIC X(32).
          05 DC-CLIENT-TOKEN PIC X(256).
          05 DC-CLIENT-GATEWAY-ENDPOINT PIC X(256).
      *> JP: 高水準の接続状態です。event loop や login 処理が参照します。
      *> EN: High-level connection state consumed by login and event-loop logic.
          05 DC-CLIENT-STATE PIC 9.
             88 CLIENT-INIT VALUE 0.
             88 CLIENT-CONNECTING VALUE 1.
             88 CLIENT-READY VALUE 2.
             88 CLIENT-DISCONNECTED VALUE 3.
      *> JP: Gateway session の継続に必要なシーケンス番号や session id です。
      *> EN: Sequence/session values required to continue a Gateway session.
          05 DC-CLIENT-SEQUENCE PIC S9(10) COMP-5.
          05 DC-CLIENT-SESSION-ID PIC X(128).
      *> JP: Heartbeat と再接続判断に使う runtime flags です。
      *> EN: Runtime flags used for heartbeat and reconnect decisions.
          05 DC-CLIENT-GW-HEARTBEAT-INTERVAL PIC 9(10) COMP-5.
          05 DC-CLIENT-GW-HEARTBEAT-NEXT-AT PIC 9(18) COMP-5.
          05 DC-CLIENT-GW-IDENTIFY-NEEDED PIC 9.
          05 DC-CLIENT-GW-RESUME-REQUESTED PIC 9.
          05 DC-CLIENT-GW-HEARTBEAT-DUE PIC 9.
          05 DC-CLIENT-GW-AWAITING-ACK PIC 9.
      *> JP: 送信待ちの Gateway command を 1 件だけ持つ簡易キューです。
      *> EN: A minimal single-slot queue for the next outbound Gateway command.
          05 DC-CLIENT-GW-COMMAND-QUEUED PIC 9.
          05 DC-CLIENT-GW-COMMAND-NAME PIC X(32).
          05 DC-CLIENT-GW-COMMAND-PAYLOAD PIC X(8192).
      *> JP: Gateway WebSocket の接続先、handshake、I/O バッファを保持します。
      *> EN: Gateway WebSocket destination, handshake data, and I/O buffers.
          05 DC-CLIENT-GW-WS-HANDLE PIC 9(10) COMP-5.
          05 DC-CLIENT-GW-WS-OPEN-FLAG PIC 9.
          05 DC-CLIENT-GW-WS-LAST-OPCODE PIC 9(2) COMP-5.
          05 DC-CLIENT-GW-WS-LOOPBACK-FLAG PIC 9.
          05 DC-CLIENT-GW-WS-LIVE-FLAG PIC 9.
          05 DC-CLIENT-GW-WS-HOST PIC X(256).
          05 DC-CLIENT-GW-WS-PATH PIC X(512).
          05 DC-CLIENT-GW-WS-SEC-KEY PIC X(64).
          05 DC-CLIENT-GW-WS-PORT PIC 9(5) COMP-5.
          05 DC-CLIENT-GW-WS-HANDSHAKE-REQUEST-LENGTH
             PIC 9(9) COMP-5.
          05 DC-CLIENT-GW-WS-HANDSHAKE-REQUEST PIC X(8192).
          05 DC-CLIENT-GW-WS-HANDSHAKE-RESPONSE-LENGTH
             PIC 9(9) COMP-5.
          05 DC-CLIENT-GW-WS-HANDSHAKE-RESPONSE PIC X(8192).
          05 DC-CLIENT-GW-WS-INBOUND-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 DC-CLIENT-GW-WS-INBOUND-BUFFER PIC X(8192).
          05 DC-CLIENT-GW-WS-OUTBOUND-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 DC-CLIENT-GW-WS-OUTBOUND-BUFFER PIC X(8192).
      *> JP: 起動設定を runtime 側へ複写した値です。
      *> EN: Startup configuration mirrored into runtime state.
          05 DC-CLIENT-INTENTS PIC 9(10) COMP-5.
          05 DC-CLIENT-LOG-LEVEL PIC 9(2) COMP-5.
          05 DC-CLIENT-GATEWAY-VERSION PIC 9(2) COMP-5.
          05 DC-CLIENT-VOICE-GATEWAY-VERSION PIC 9(2) COMP-5.
          05 DC-CLIENT-AUDIO-FRAME-MS PIC 9(2) COMP-5.
          05 DC-CLIENT-AUDIO-SAMPLE-RATE PIC 9(5) COMP-5.
          05 DC-CLIENT-AUDIO-CHANNELS PIC 9.
          05 DC-CLIENT-MUSIC-IDLE-LEAVE-TICKS PIC 9(9) COMP-5.
      *> JP: 一般 Gateway event 名から program 名へ引く登録表です。
      *> EN: Registration table from Gateway event name to handler program.
          05 DC-EVENT-HANDLER-TABLE.
             10 DC-HANDLER-COUNT PIC 9(4) COMP-5.
             10 DC-HANDLER OCCURS 100 TIMES.
                15 DC-HANDLER-EVENT-NAME PIC X(64).
                15 DC-HANDLER-PROGRAM PIC X(64).
      *> JP: Interaction command 名から custom handler を引く登録表です。
      *> EN: Registration table from interaction command name to custom handler.
          05 DC-IA-COMMAND-HANDLERS.
             10 DC-IA-COMMAND-COUNT PIC 9(4) COMP-5.
             10 DC-IA-COMMAND-HANDLER OCCURS 100 TIMES.
                15 DC-IA-COMMAND-NAME PIC X(128).
                15 DC-IA-COMMAND-PROGRAM PIC X(64).
      *> JP: Button/select など component の custom_id 用登録表です。
      *> EN: Registration table for component custom_id values such as buttons/selects.
          05 DC-IA-COMPONENT-HANDLERS.
             10 DC-IA-COMPONENT-COUNT PIC 9(4) COMP-5.
             10 DC-IA-COMPONENT-HANDLER OCCURS 100 TIMES.
                15 DC-IA-COMPONENT-ID PIC X(128).
                15 DC-IA-COMPONENT-PROGRAM PIC X(64).
      *> JP: Modal submit の custom_id 用登録表です。
      *> EN: Registration table for modal-submit custom_id values.
          05 DC-IA-MODAL-HANDLERS.
             10 DC-IA-MODAL-COUNT PIC 9(4) COMP-5.
             10 DC-IA-MODAL-HANDLER OCCURS 100 TIMES.
                15 DC-IA-MODAL-ID PIC X(128).
                15 DC-IA-MODAL-PROGRAM PIC X(64).
