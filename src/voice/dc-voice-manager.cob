       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-STATE-UPDATE-BUILD.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       01 DC-VOICE-CHANNEL-ID-IN PIC X(32).
       01 DC-VOICE-PAYLOAD-OUT PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-GUILD-ID-IN
           DC-VOICE-CHANNEL-ID-IN
           DC-VOICE-PAYLOAD-OUT
           DC-RESULT.
       MAIN.
      *> JP: VOICE_STATE_UPDATE(op=4) は join と leave の両方で共有される payload builder です。
      *> EN: VOICE_STATE_UPDATE (op=4) is the shared payload builder used by both join and leave.
      *> JP: channel_id が空なら Discord には null を送り、leave として扱います。
      *> EN: An empty channel_id is emitted as null so Discord interprets it as a leave.
           MOVE SPACES TO DC-VOICE-PAYLOAD-OUT
           IF FUNCTION TRIM(DC-VOICE-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-VOICE-CHANNEL-ID-IN) = SPACES
               STRING
                   "{" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "op" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":4," DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "d" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":{" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "guild_id" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   FUNCTION TRIM(DC-VOICE-GUILD-ID-IN) DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "," DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "channel_id" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":null," DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "self_mute" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":false," DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "self_deaf" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":false}}" DELIMITED BY SIZE
                   INTO DC-VOICE-PAYLOAD-OUT
               END-STRING
           ELSE
               STRING
                   "{" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "op" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":4," DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "d" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":{" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "guild_id" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   FUNCTION TRIM(DC-VOICE-GUILD-ID-IN) DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "," DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "channel_id" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   FUNCTION TRIM(DC-VOICE-CHANNEL-ID-IN)
                       DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "," DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "self_mute" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":false," DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   "self_deaf" DELIMITED BY SIZE
                   QUOTE DELIMITED BY SIZE
                   ":false}}" DELIMITED BY SIZE
                   INTO DC-VOICE-PAYLOAD-OUT
               END-STRING
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-STATE-UPDATE-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-JOIN.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ACTION PIC X(32) VALUE "VOICE_STATE_UPDATE".
       01 WS-PAYLOAD PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       01 DC-VOICE-CHANNEL-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-GUILD-ID-IN
           DC-VOICE-CHANNEL-ID-IN
           DC-RESULT.
       MAIN.
      *> JP: Voice join 自体は Gateway outbound queue に VOICE_STATE_UPDATE を積むだけです。
      *> EN: Voice join itself only queues a VOICE_STATE_UPDATE on the Gateway outbound queue.
           IF DC-CLIENT-STATE NOT = 2
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_GATEWAY_NOT_READY" TO DC-ERROR-CODE
               MOVE "Gateway client must be ready before voice join."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-VOICE-STATE-UPDATE-BUILD"
               USING DC-VOICE-GUILD-ID-IN
                     DC-VOICE-CHANNEL-ID-IN
                     WS-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-GATEWAY-QUEUE-PAYLOAD"
               USING DC-CLIENT
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-JOIN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-LEAVE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ACTION PIC X(32) VALUE "VOICE_STATE_UPDATE".
       01 WS-EMPTY-CHANNEL PIC X(32).
       01 WS-PAYLOAD PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-GUILD-ID-IN
           DC-RESULT.
       MAIN.
      *> JP: leave も同じく queue ベースで、空 channel を使うだけです。
      *> EN: Leave uses the same queue-based path, only with an empty channel id.
           IF DC-CLIENT-STATE NOT = 2
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_GATEWAY_NOT_READY" TO DC-ERROR-CODE
               MOVE "Gateway client must be ready before voice leave."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-VOICE-STATE-UPDATE-BUILD"
               USING DC-VOICE-GUILD-ID-IN
                     WS-EMPTY-CHANNEL
                     WS-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-GATEWAY-QUEUE-PAYLOAD"
               USING DC-CLIENT
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-LEAVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-SESSION-INIT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       01 DC-VOICE-CHANNEL-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-VOICE-GUILD-ID-IN
           DC-VOICE-CHANNEL-ID-IN
           DC-RESULT.
       MAIN.
      *> JP: Voice session の最初の初期値をここでまとめて作ります。
      *> EN: Establish the initial voice-session defaults in one place.
      *> JP: 実際の endpoint/token/session_id は後続の Gateway voice events で埋まります。
      *> EN: The actual endpoint/token/session_id arrive later from Gateway voice events.
           INITIALIZE DC-VOICE-SESSION
           MOVE DC-VOICE-GUILD-ID-IN TO DC-VS-GUILD-ID
           MOVE DC-VOICE-CHANNEL-ID-IN TO DC-VS-CHANNEL-ID
           MOVE 1 TO DC-VS-STATE
           MOVE 0 TO DC-VS-HEARTBEAT-NONCE
           MOVE 0 TO DC-VS-MEDIA-NONCE
           MOVE 0 TO DC-VS-IDENTIFY-NEEDED
           MOVE 0 TO DC-VS-RESUME-REQUESTED
           MOVE 0 TO DC-VS-HEARTBEAT-DUE
           MOVE 0 TO DC-VS-AWAITING-ACK
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-SESSION-INIT.
