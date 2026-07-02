      *> JP: 1 guild / 1 voice connection の runtime 状態をまとめた構造です。
      *> EN: Runtime state for one guild-level voice connection.
       01 DC-VOICE-SESSION.
      *> JP: Gateway event から受け取る接続コンテキストです。
      *> EN: Connection context received from Gateway events.
          05 DC-VS-GUILD-ID PIC X(32).
          05 DC-VS-CHANNEL-ID PIC X(32).
          05 DC-VS-SESSION-ID PIC X(128).
          05 DC-VS-TOKEN PIC X(256).
          05 DC-VS-ENDPOINT PIC X(256).
          05 DC-VS-GATEWAY-URL PIC X(256).
      *> JP: Voice UDP discovery と送信先解決に使うネットワーク情報です。
      *> EN: Network information used for voice UDP discovery and destination selection.
          05 DC-VS-IP PIC X(64).
          05 DC-VS-PORT PIC 9(5) COMP-5.
          05 DC-VS-DISCOVERED-IP PIC X(64).
          05 DC-VS-DISCOVERED-PORT PIC 9(5) COMP-5.
          05 DC-VS-UDP-HANDLE PIC 9(10) COMP-5.
          05 DC-VS-SSRC PIC 9(10) COMP-5.
      *> JP: Heartbeat / RTP 送信の進行を追うカウンタ群です。
      *> EN: Counters that track heartbeat cadence and RTP transmission progress.
          05 DC-VS-HEARTBEAT-INTERVAL PIC 9(10) COMP-5.
          05 DC-VS-HEARTBEAT-NEXT-AT PIC 9(18) COMP-5.
          05 DC-VS-HEARTBEAT-NONCE PIC 9(18) COMP-5.
          05 DC-VS-MEDIA-NONCE PIC 9(18) COMP-5.
          05 DC-VS-LAST-SEQ PIC S9(10) COMP-5.
      *> JP: 次に送る control payload を決めるための state flags です。
      *> EN: State flags that decide which control payload should be sent next.
          05 DC-VS-IDENTIFY-NEEDED PIC 9.
          05 DC-VS-RESUME-REQUESTED PIC 9.
          05 DC-VS-HEARTBEAT-DUE PIC 9.
          05 DC-VS-AWAITING-ACK PIC 9.
      *> JP: READY / SESSION_DESCRIPTION 後に埋まる暗号化と準備状態です。
      *> EN: Encryption and readiness state populated after READY / SESSION_DESCRIPTION.
          05 DC-VS-SECRET-KEY PIC X(128).
          05 DC-VS-READY-FLAG PIC 9.
          05 DC-VS-UDP-READY-FLAG PIC 9.
          05 DC-VS-ENCRYPTION-MODE PIC X(64).
      *> JP: 大まかな接続段階です。tick や payload builder の分岐条件になります。
      *> EN: Coarse connection phase used by tick logic and payload builders.
          05 DC-VS-STATE PIC 9.
             88 VS-DISCONNECTED VALUE 0.
             88 VS-WAITING-EVENTS VALUE 1.
             88 VS-GATEWAY-CONNECTING VALUE 2.
             88 VS-UDP-DISCOVERING VALUE 3.
             88 VS-READY VALUE 4.
             88 VS-RECONNECTING VALUE 5.
      *> JP: Voice Gateway 向けの outbound command を 1 件だけ保持する簡易キューです。
      *> EN: Minimal single-slot outbound queue for Voice Gateway commands.
          05 DC-VS-COMMAND-QUEUED PIC 9.
          05 DC-VS-COMMAND-NAME PIC X(32).
          05 DC-VS-COMMAND-PAYLOAD PIC X(8192).
      *> JP: Voice WebSocket session を固定長 state に退避するための領域です。
      *> EN: Storage used to persist the Voice WebSocket session inside fixed-width state.
          05 DC-VS-WS-HANDLE PIC 9(10) COMP-5.
          05 DC-VS-WS-OPEN-FLAG PIC 9.
          05 DC-VS-WS-LAST-OPCODE PIC 9(2) COMP-5.
          05 DC-VS-WS-LOOPBACK-FLAG PIC 9.
          05 DC-VS-WS-LIVE-FLAG PIC 9.
          05 DC-VS-WS-HOST PIC X(256).
          05 DC-VS-WS-PATH PIC X(512).
          05 DC-VS-WS-SEC-KEY PIC X(64).
          05 DC-VS-WS-PORT PIC 9(5) COMP-5.
          05 DC-VS-WS-HANDSHAKE-REQUEST-LENGTH PIC 9(9) COMP-5.
          05 DC-VS-WS-HANDSHAKE-REQUEST PIC X(8192).
          05 DC-VS-WS-HANDSHAKE-RESPONSE-LENGTH PIC 9(9) COMP-5.
          05 DC-VS-WS-HANDSHAKE-RESPONSE PIC X(8192).
          05 DC-VS-WS-INBOUND-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 DC-VS-WS-INBOUND-BUFFER PIC X(8192).
          05 DC-VS-WS-OUTBOUND-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 DC-VS-WS-OUTBOUND-BUFFER PIC X(8192).

      *> JP: Voice identify payload の入力構造です。
      *> EN: Input structure for a Voice identify payload.
       01 DC-VOICE-IDENTIFY.
          05 DC-VI-SERVER-ID PIC X(32).
          05 DC-VI-USER-ID PIC X(32).
          05 DC-VI-SESSION-ID PIC X(128).
          05 DC-VI-TOKEN PIC X(256).

      *> JP: UDP discovery 後に送る select-protocol payload の入力構造です。
      *> EN: Input structure for the select-protocol payload sent after UDP discovery.
       01 DC-SELECT-PROTOCOL.
          05 DC-SP-PROTOCOL PIC X(16).
          05 DC-SP-ADDRESS PIC X(64).
          05 DC-SP-PORT PIC 9(5) COMP-5.
          05 DC-SP-MODE PIC X(64).

      *> JP: speaking 通知 payload の入力構造です。
      *> EN: Input structure for a speaking notification payload.
       01 DC-SPEAKING-PAYLOAD.
          05 DC-SPEAKING-FLAG PIC 9.
          05 DC-SPEAKING-DELAY PIC 9(10) COMP-5.
          05 DC-SPEAKING-SSRC PIC 9(10) COMP-5.
