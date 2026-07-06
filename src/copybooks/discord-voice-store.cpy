      *> JP: guild ごとの voice session を保存する EXTERNAL ストアです。
      *> JP: Gateway event dispatch と voice tick のあいだで session を受け渡すために使います。
      *> EN: EXTERNAL store for guild-scoped voice sessions.
      *> EN: It carries sessions between Gateway event dispatch and repeated voice ticks.
       78 DC-VOICE-MAX-SESSIONS VALUE 8.

       01 DC-VOICE-RUNTIME-STORE EXTERNAL.
          05 DC-VR-ENTRY OCCURS DC-VOICE-MAX-SESSIONS TIMES.
             10 DC-VR-ENTRY-IN-USE PIC 9.
             10 DC-VR-ENTRY-GUILD-ID PIC X(32).
             10 DC-VR-SESSION.
                15 DC-VR-VS-GUILD-ID PIC X(32).
                15 DC-VR-VS-CHANNEL-ID PIC X(32).
                15 DC-VR-VS-SESSION-ID PIC X(128).
                15 DC-VR-VS-TOKEN PIC X(256).
                15 DC-VR-VS-ENDPOINT PIC X(256).
                15 DC-VR-VS-GATEWAY-URL PIC X(256).
                15 DC-VR-VS-IP PIC X(64).
                15 DC-VR-VS-PORT PIC 9(5) COMP-5.
                15 DC-VR-VS-DISCOVERED-IP PIC X(64).
                15 DC-VR-VS-DISCOVERED-PORT PIC 9(5) COMP-5.
                15 DC-VR-VS-UDP-HANDLE PIC 9(10) COMP-5.
                15 DC-VR-VS-SSRC PIC 9(10) COMP-5.
                15 DC-VR-VS-HEARTBEAT-INTERVAL PIC 9(10) COMP-5.
                15 DC-VR-VS-HEARTBEAT-NEXT-AT PIC 9(18) COMP-5.
                15 DC-VR-VS-HEARTBEAT-NONCE PIC 9(18) COMP-5.
                15 DC-VR-VS-MEDIA-NONCE PIC 9(18) COMP-5.
                15 DC-VR-VS-LAST-SEQ PIC S9(10) COMP-5.
                15 DC-VR-VS-IDENTIFY-NEEDED PIC 9.
                15 DC-VR-VS-RESUME-REQUESTED PIC 9.
                15 DC-VR-VS-HEARTBEAT-DUE PIC 9.
                15 DC-VR-VS-AWAITING-ACK PIC 9.
                15 DC-VR-VS-SECRET-KEY PIC X(128).
                15 DC-VR-VS-READY-FLAG PIC 9.
                15 DC-VR-VS-UDP-READY-FLAG PIC 9.
                15 DC-VR-VS-ENCRYPTION-MODE PIC X(64).
                15 DC-VR-VS-STATE PIC 9.
                15 DC-VR-VS-COMMAND-QUEUED PIC 9.
                15 DC-VR-VS-COMMAND-NAME PIC X(32).
                15 DC-VR-VS-COMMAND-PAYLOAD PIC X(8192).
                15 DC-VR-VS-WS-HANDLE PIC 9(10) COMP-5.
                15 DC-VR-VS-WS-OPEN-FLAG PIC 9.
                15 DC-VR-VS-WS-LAST-OPCODE PIC 9(2) COMP-5.
                15 DC-VR-VS-WS-LOOPBACK-FLAG PIC 9.
                15 DC-VR-VS-WS-LIVE-FLAG PIC 9.
                15 DC-VR-VS-WS-HOST PIC X(256).
                15 DC-VR-VS-WS-PATH PIC X(512).
                15 DC-VR-VS-WS-SEC-KEY PIC X(64).
                15 DC-VR-VS-WS-PORT PIC 9(5) COMP-5.
                15 DC-VR-VS-WS-HANDSHAKE-REQUEST-LENGTH
                   PIC 9(9) COMP-5.
                15 DC-VR-VS-WS-HANDSHAKE-REQUEST PIC X(8192).
                15 DC-VR-VS-WS-HANDSHAKE-RESPONSE-LENGTH
                   PIC 9(9) COMP-5.
                15 DC-VR-VS-WS-HANDSHAKE-RESPONSE PIC X(8192).
                15 DC-VR-VS-WS-INBOUND-BUFFER-LENGTH PIC 9(9) COMP-5.
                15 DC-VR-VS-WS-INBOUND-BUFFER PIC X(8192).
                15 DC-VR-VS-WS-OUTBOUND-BUFFER-LENGTH PIC 9(9) COMP-5.
                15 DC-VR-VS-WS-OUTBOUND-BUFFER PIC X(8192).
