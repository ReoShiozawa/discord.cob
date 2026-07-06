       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-SESSION-LOAD.
       *> JP: guild ごとの voice session を EXTERNAL ストアから引き戻します。
       *> EN: Load a guild-scoped voice session back out of the EXTERNAL store.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-GUILD-ID-IN
           DC-VOICE-SESSION
           DC-RESULT.
       MAIN.
           INITIALIZE DC-VOICE-SESSION
           IF FUNCTION TRIM(DC-VOICE-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-VOICE-MAX-SESSIONS
               IF DC-VR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-VR-ENTRY-GUILD-ID(WS-IDX))
                      = FUNCTION TRIM(DC-VOICE-GUILD-ID-IN)
                   PERFORM LOAD-ENTRY
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
           END-PERFORM

           MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
           MOVE "DC_ERR_VOICE_STATE_MISSING" TO DC-ERROR-CODE
           MOVE "Voice session was not found."
               TO DC-ERROR-MESSAGE
           GOBACK.

       LOAD-ENTRY.
           MOVE DC-VR-VS-GUILD-ID(WS-IDX) TO DC-VS-GUILD-ID
           MOVE DC-VR-VS-CHANNEL-ID(WS-IDX) TO DC-VS-CHANNEL-ID
           MOVE DC-VR-VS-SESSION-ID(WS-IDX) TO DC-VS-SESSION-ID
           MOVE DC-VR-VS-TOKEN(WS-IDX) TO DC-VS-TOKEN
           MOVE DC-VR-VS-ENDPOINT(WS-IDX) TO DC-VS-ENDPOINT
           MOVE DC-VR-VS-GATEWAY-URL(WS-IDX) TO DC-VS-GATEWAY-URL
           MOVE DC-VR-VS-IP(WS-IDX) TO DC-VS-IP
           MOVE DC-VR-VS-PORT(WS-IDX) TO DC-VS-PORT
           MOVE DC-VR-VS-DISCOVERED-IP(WS-IDX) TO DC-VS-DISCOVERED-IP
           MOVE DC-VR-VS-DISCOVERED-PORT(WS-IDX)
               TO DC-VS-DISCOVERED-PORT
           MOVE DC-VR-VS-UDP-HANDLE(WS-IDX) TO DC-VS-UDP-HANDLE
           MOVE DC-VR-VS-SSRC(WS-IDX) TO DC-VS-SSRC
           MOVE DC-VR-VS-HEARTBEAT-INTERVAL(WS-IDX)
               TO DC-VS-HEARTBEAT-INTERVAL
           MOVE DC-VR-VS-HEARTBEAT-NEXT-AT(WS-IDX)
               TO DC-VS-HEARTBEAT-NEXT-AT
           MOVE DC-VR-VS-HEARTBEAT-NONCE(WS-IDX)
               TO DC-VS-HEARTBEAT-NONCE
           MOVE DC-VR-VS-MEDIA-NONCE(WS-IDX) TO DC-VS-MEDIA-NONCE
           MOVE DC-VR-VS-LAST-SEQ(WS-IDX) TO DC-VS-LAST-SEQ
           MOVE DC-VR-VS-IDENTIFY-NEEDED(WS-IDX) TO DC-VS-IDENTIFY-NEEDED
           MOVE DC-VR-VS-RESUME-REQUESTED(WS-IDX)
               TO DC-VS-RESUME-REQUESTED
           MOVE DC-VR-VS-HEARTBEAT-DUE(WS-IDX) TO DC-VS-HEARTBEAT-DUE
           MOVE DC-VR-VS-AWAITING-ACK(WS-IDX) TO DC-VS-AWAITING-ACK
           MOVE DC-VR-VS-SECRET-KEY(WS-IDX) TO DC-VS-SECRET-KEY
           MOVE DC-VR-VS-READY-FLAG(WS-IDX) TO DC-VS-READY-FLAG
           MOVE DC-VR-VS-UDP-READY-FLAG(WS-IDX) TO DC-VS-UDP-READY-FLAG
           MOVE DC-VR-VS-ENCRYPTION-MODE(WS-IDX) TO DC-VS-ENCRYPTION-MODE
           MOVE DC-VR-VS-STATE(WS-IDX) TO DC-VS-STATE
           MOVE DC-VR-VS-COMMAND-QUEUED(WS-IDX) TO DC-VS-COMMAND-QUEUED
           MOVE DC-VR-VS-COMMAND-NAME(WS-IDX) TO DC-VS-COMMAND-NAME
           MOVE DC-VR-VS-COMMAND-PAYLOAD(WS-IDX) TO DC-VS-COMMAND-PAYLOAD
           MOVE DC-VR-VS-WS-HANDLE(WS-IDX) TO DC-VS-WS-HANDLE
           MOVE DC-VR-VS-WS-OPEN-FLAG(WS-IDX) TO DC-VS-WS-OPEN-FLAG
           MOVE DC-VR-VS-WS-LAST-OPCODE(WS-IDX) TO DC-VS-WS-LAST-OPCODE
           MOVE DC-VR-VS-WS-LOOPBACK-FLAG(WS-IDX) TO DC-VS-WS-LOOPBACK-FLAG
           MOVE DC-VR-VS-WS-LIVE-FLAG(WS-IDX) TO DC-VS-WS-LIVE-FLAG
           MOVE DC-VR-VS-WS-HOST(WS-IDX) TO DC-VS-WS-HOST
           MOVE DC-VR-VS-WS-PATH(WS-IDX) TO DC-VS-WS-PATH
           MOVE DC-VR-VS-WS-SEC-KEY(WS-IDX) TO DC-VS-WS-SEC-KEY
           MOVE DC-VR-VS-WS-PORT(WS-IDX) TO DC-VS-WS-PORT
           MOVE DC-VR-VS-WS-HANDSHAKE-REQUEST-LENGTH(WS-IDX)
               TO DC-VS-WS-HANDSHAKE-REQUEST-LENGTH
           MOVE DC-VR-VS-WS-HANDSHAKE-REQUEST(WS-IDX)
               TO DC-VS-WS-HANDSHAKE-REQUEST
           MOVE DC-VR-VS-WS-HANDSHAKE-RESPONSE-LENGTH(WS-IDX)
               TO DC-VS-WS-HANDSHAKE-RESPONSE-LENGTH
           MOVE DC-VR-VS-WS-HANDSHAKE-RESPONSE(WS-IDX)
               TO DC-VS-WS-HANDSHAKE-RESPONSE
           MOVE DC-VR-VS-WS-INBOUND-BUFFER-LENGTH(WS-IDX)
               TO DC-VS-WS-INBOUND-BUFFER-LENGTH
           MOVE DC-VR-VS-WS-INBOUND-BUFFER(WS-IDX)
               TO DC-VS-WS-INBOUND-BUFFER
           MOVE DC-VR-VS-WS-OUTBOUND-BUFFER-LENGTH(WS-IDX)
               TO DC-VS-WS-OUTBOUND-BUFFER-LENGTH
           MOVE DC-VR-VS-WS-OUTBOUND-BUFFER(WS-IDX)
               TO DC-VS-WS-OUTBOUND-BUFFER.
       END PROGRAM DC-VOICE-SESSION-LOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-SESSION-SAVE.
       *> JP: guild ごとの voice session を EXTERNAL ストアへ保存します。
       *> EN: Save a guild-scoped voice session into the EXTERNAL store.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FREE-IDX PIC 9(4) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-GUILD-ID-IN
           DC-VOICE-SESSION
           DC-RESULT.
       MAIN.
           MOVE 0 TO WS-FREE-IDX
           IF FUNCTION TRIM(DC-VOICE-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-VOICE-MAX-SESSIONS
               IF DC-VR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-VR-ENTRY-GUILD-ID(WS-IDX))
                      = FUNCTION TRIM(DC-VOICE-GUILD-ID-IN)
                   PERFORM SAVE-ENTRY
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
               IF WS-FREE-IDX = 0
                  AND DC-VR-ENTRY-IN-USE(WS-IDX) NOT = 1
                   MOVE WS-IDX TO WS-FREE-IDX
               END-IF
           END-PERFORM

           IF WS-FREE-IDX = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_POOL_FULL" TO DC-ERROR-CODE
               MOVE "Voice session table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE WS-FREE-IDX TO WS-IDX
           MOVE 1 TO DC-VR-ENTRY-IN-USE(WS-IDX)
           MOVE DC-VOICE-GUILD-ID-IN TO DC-VR-ENTRY-GUILD-ID(WS-IDX)
           PERFORM SAVE-ENTRY
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       SAVE-ENTRY.
           MOVE DC-VOICE-GUILD-ID-IN TO DC-VR-ENTRY-GUILD-ID(WS-IDX)
           MOVE DC-VS-GUILD-ID TO DC-VR-VS-GUILD-ID(WS-IDX)
           MOVE DC-VS-CHANNEL-ID TO DC-VR-VS-CHANNEL-ID(WS-IDX)
           MOVE DC-VS-SESSION-ID TO DC-VR-VS-SESSION-ID(WS-IDX)
           MOVE DC-VS-TOKEN TO DC-VR-VS-TOKEN(WS-IDX)
           MOVE DC-VS-ENDPOINT TO DC-VR-VS-ENDPOINT(WS-IDX)
           MOVE DC-VS-GATEWAY-URL TO DC-VR-VS-GATEWAY-URL(WS-IDX)
           MOVE DC-VS-IP TO DC-VR-VS-IP(WS-IDX)
           MOVE DC-VS-PORT TO DC-VR-VS-PORT(WS-IDX)
           MOVE DC-VS-DISCOVERED-IP TO DC-VR-VS-DISCOVERED-IP(WS-IDX)
           MOVE DC-VS-DISCOVERED-PORT TO DC-VR-VS-DISCOVERED-PORT(WS-IDX)
           MOVE DC-VS-UDP-HANDLE TO DC-VR-VS-UDP-HANDLE(WS-IDX)
           MOVE DC-VS-SSRC TO DC-VR-VS-SSRC(WS-IDX)
           MOVE DC-VS-HEARTBEAT-INTERVAL
               TO DC-VR-VS-HEARTBEAT-INTERVAL(WS-IDX)
           MOVE DC-VS-HEARTBEAT-NEXT-AT TO DC-VR-VS-HEARTBEAT-NEXT-AT(WS-IDX)
           MOVE DC-VS-HEARTBEAT-NONCE TO DC-VR-VS-HEARTBEAT-NONCE(WS-IDX)
           MOVE DC-VS-MEDIA-NONCE TO DC-VR-VS-MEDIA-NONCE(WS-IDX)
           MOVE DC-VS-LAST-SEQ TO DC-VR-VS-LAST-SEQ(WS-IDX)
           MOVE DC-VS-IDENTIFY-NEEDED TO DC-VR-VS-IDENTIFY-NEEDED(WS-IDX)
           MOVE DC-VS-RESUME-REQUESTED TO DC-VR-VS-RESUME-REQUESTED(WS-IDX)
           MOVE DC-VS-HEARTBEAT-DUE TO DC-VR-VS-HEARTBEAT-DUE(WS-IDX)
           MOVE DC-VS-AWAITING-ACK TO DC-VR-VS-AWAITING-ACK(WS-IDX)
           MOVE DC-VS-SECRET-KEY TO DC-VR-VS-SECRET-KEY(WS-IDX)
           MOVE DC-VS-READY-FLAG TO DC-VR-VS-READY-FLAG(WS-IDX)
           MOVE DC-VS-UDP-READY-FLAG TO DC-VR-VS-UDP-READY-FLAG(WS-IDX)
           MOVE DC-VS-ENCRYPTION-MODE TO DC-VR-VS-ENCRYPTION-MODE(WS-IDX)
           MOVE DC-VS-STATE TO DC-VR-VS-STATE(WS-IDX)
           MOVE DC-VS-COMMAND-QUEUED TO DC-VR-VS-COMMAND-QUEUED(WS-IDX)
           MOVE DC-VS-COMMAND-NAME TO DC-VR-VS-COMMAND-NAME(WS-IDX)
           MOVE DC-VS-COMMAND-PAYLOAD TO DC-VR-VS-COMMAND-PAYLOAD(WS-IDX)
           MOVE DC-VS-WS-HANDLE TO DC-VR-VS-WS-HANDLE(WS-IDX)
           MOVE DC-VS-WS-OPEN-FLAG TO DC-VR-VS-WS-OPEN-FLAG(WS-IDX)
           MOVE DC-VS-WS-LAST-OPCODE TO DC-VR-VS-WS-LAST-OPCODE(WS-IDX)
           MOVE DC-VS-WS-LOOPBACK-FLAG TO DC-VR-VS-WS-LOOPBACK-FLAG(WS-IDX)
           MOVE DC-VS-WS-LIVE-FLAG TO DC-VR-VS-WS-LIVE-FLAG(WS-IDX)
           MOVE DC-VS-WS-HOST TO DC-VR-VS-WS-HOST(WS-IDX)
           MOVE DC-VS-WS-PATH TO DC-VR-VS-WS-PATH(WS-IDX)
           MOVE DC-VS-WS-SEC-KEY TO DC-VR-VS-WS-SEC-KEY(WS-IDX)
           MOVE DC-VS-WS-PORT TO DC-VR-VS-WS-PORT(WS-IDX)
           MOVE DC-VS-WS-HANDSHAKE-REQUEST-LENGTH
               TO DC-VR-VS-WS-HANDSHAKE-REQUEST-LENGTH(WS-IDX)
           MOVE DC-VS-WS-HANDSHAKE-REQUEST
               TO DC-VR-VS-WS-HANDSHAKE-REQUEST(WS-IDX)
           MOVE DC-VS-WS-HANDSHAKE-RESPONSE-LENGTH
               TO DC-VR-VS-WS-HANDSHAKE-RESPONSE-LENGTH(WS-IDX)
           MOVE DC-VS-WS-HANDSHAKE-RESPONSE
               TO DC-VR-VS-WS-HANDSHAKE-RESPONSE(WS-IDX)
           MOVE DC-VS-WS-INBOUND-BUFFER-LENGTH
               TO DC-VR-VS-WS-INBOUND-BUFFER-LENGTH(WS-IDX)
           MOVE DC-VS-WS-INBOUND-BUFFER
               TO DC-VR-VS-WS-INBOUND-BUFFER(WS-IDX)
           MOVE DC-VS-WS-OUTBOUND-BUFFER-LENGTH
               TO DC-VR-VS-WS-OUTBOUND-BUFFER-LENGTH(WS-IDX)
           MOVE DC-VS-WS-OUTBOUND-BUFFER
               TO DC-VR-VS-WS-OUTBOUND-BUFFER(WS-IDX).
       END PROGRAM DC-VOICE-SESSION-SAVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-SESSION-CLEAR.
       *> JP: 保存済み voice session を guild 単位で消します。
       *> EN: Clear a stored voice session by guild.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-VOICE-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-VOICE-MAX-SESSIONS
               IF DC-VR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-VR-ENTRY-GUILD-ID(WS-IDX))
                      = FUNCTION TRIM(DC-VOICE-GUILD-ID-IN)
                   MOVE 0 TO DC-VR-ENTRY-IN-USE(WS-IDX)
                   MOVE SPACES TO DC-VR-ENTRY-GUILD-ID(WS-IDX)
                   INITIALIZE DC-VR-SESSION(WS-IDX)
                   EXIT PERFORM
               END-IF
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-SESSION-CLEAR.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-STATE-EVENT-HANDLER.
       *> JP: bot 自身に届いた VOICE_STATE_UPDATE を保存済み session へ反映します。
       *> EN: Apply VOICE_STATE_UPDATE for the bot user into the stored session.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice.cpy".
       01 WS-VOICE-JSON PIC X(8192).
       01 WS-PATH PIC X(128).
       01 WS-GUILD-ID PIC X(32).
       01 WS-USER-ID PIC X(32).
       01 WS-CHANNEL-ID PIC X(32).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-EVENT DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "VOICE_STATE_UPDATE"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Gateway event was not VOICE_STATE_UPDATE."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-VOICE-JSON
           IF DC-EVENT-PAYLOAD-LENGTH > 0
               MOVE DC-EVENT-PAYLOAD(1:DC-EVENT-PAYLOAD-LENGTH)
                   TO WS-VOICE-JSON(1:DC-EVENT-PAYLOAD-LENGTH)
           END-IF

           MOVE SPACES TO WS-USER-ID
           MOVE "$.d.user_id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-VOICE-JSON WS-PATH WS-USER-ID WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
              AND FUNCTION TRIM(DC-CLIENT-USER-ID) NOT = SPACES
              AND FUNCTION TRIM(WS-USER-ID)
                  NOT = FUNCTION TRIM(DC-CLIENT-USER-ID)
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           MOVE "$.d.guild_id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-VOICE-JSON WS-PATH WS-GUILD-ID DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE SPACES TO WS-CHANNEL-ID
           MOVE "$.d.channel_id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-VOICE-JSON WS-PATH WS-CHANNEL-ID WS-LOCAL-RESULT

           CALL "DC-VOICE-SESSION-LOAD"
               USING WS-GUILD-ID
                     DC-VOICE-SESSION
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-NOT-FOUND
               CALL "DC-VOICE-SESSION-INIT"
                   USING DC-VOICE-SESSION
                         WS-GUILD-ID
                         WS-CHANNEL-ID
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           ELSE
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
               MOVE WS-GUILD-ID TO DC-VS-GUILD-ID
               MOVE WS-CHANNEL-ID TO DC-VS-CHANNEL-ID
           END-IF

           CALL "DC-VOICE-APPLY-STATE-UPDATE"
               USING WS-VOICE-JSON
                     DC-VOICE-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-SESSION-SAVE"
               USING WS-GUILD-ID
                     DC-VOICE-SESSION
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-STATE-EVENT-HANDLER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-REGISTER.
       *> JP: dispatcher に voice 系 Gateway event handler を登録します。
       *> EN: Register dispatcher handlers for voice-related Gateway events.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-STATE-EVENT PIC X(64) VALUE "VOICE_STATE_UPDATE".
       01 WS-STATE-HANDLER PIC X(64) VALUE "DC-VOICE-STATE-EVENT-HANDLER".
       01 WS-SERVER-EVENT PIC X(64) VALUE "VOICE_SERVER_UPDATE".
       01 WS-SERVER-HANDLER PIC X(64) VALUE "DC-VS-SERVER-HANDLER".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           CALL "DC-ON"
               USING DC-CLIENT
                     WS-STATE-EVENT
                     WS-STATE-HANDLER
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-ON"
               USING DC-CLIENT
                     WS-SERVER-EVENT
                     WS-SERVER-HANDLER
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-REGISTER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-EVENT-LOOP-TICK-STORED.
       *> JP: 保存済み voice session を load -> tick -> save の順で 1 回進めます。
       *> EN: Advance one tick by load -> tick -> save around the stored voice session.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           CALL "DC-VOICE-SESSION-LOAD"
               USING DC-VOICE-GUILD-ID-IN
                     DC-VOICE-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

      *> JP: 保存済み session がまだ WS 未接続でも、endpoint まで揃っていればここで connect します。
      *> JP: 接続を開いた tick では recv/send を急がず、次 tick から通常ループへ入ります。
      *> EN: If the stored session is not yet connected but already has an
      *> EN: endpoint, open the Voice WS here. The connect tick stops there and
      *> EN: lets the next tick enter the normal recv/send loop.
           IF DC-VS-WS-OPEN-FLAG NOT = 1
               IF FUNCTION TRIM(DC-VS-ENDPOINT) = SPACES
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
               CALL "DC-VOICE-GATEWAY-CONNECT"
                   USING DC-CLIENT
                         DC-VOICE-SESSION
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               CALL "DC-VOICE-SESSION-SAVE"
                   USING DC-VOICE-GUILD-ID-IN
                         DC-VOICE-SESSION
                         DC-RESULT
               GOBACK
           END-IF

           CALL "DC-VOICE-EVENT-LOOP-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-SESSION-SAVE"
               USING DC-VOICE-GUILD-ID-IN
                     DC-VOICE-SESSION
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-EVENT-LOOP-TICK-STORED.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-EVENT-LOOP-TICK-ALL.
       *> JP: 保存済み voice session を全 guild 分なめて tick します。
       *> EN: Iterate over every stored voice session and advance one tick per guild.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-GUILD-ID PIC X(32).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-RESULT.
       MAIN.
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-VOICE-MAX-SESSIONS
               IF DC-VR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-VR-ENTRY-GUILD-ID(WS-IDX))
                      NOT = SPACES
                   MOVE DC-VR-ENTRY-GUILD-ID(WS-IDX) TO WS-GUILD-ID
                   CALL "DC-VOICE-EVENT-LOOP-TICK-STORED"
                       USING DC-CLIENT
                             WS-GUILD-ID
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
               END-IF
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-EVENT-LOOP-TICK-ALL.
