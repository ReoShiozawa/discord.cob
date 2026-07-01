       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-UDP-DISCOVERY-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-B1 PIC 9(4) COMP-5.
       01 WS-B2 PIC 9(4) COMP-5.
       01 WS-B3 PIC 9(4) COMP-5.
       01 WS-B4 PIC 9(4) COMP-5.

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-UDP-DISCOVERY DC-RESULT.
       MAIN.
           MOVE LOW-VALUE TO DC-UD-PACKET
           MOVE FUNCTION CHAR(2) TO DC-UD-PACKET(2:1)
           MOVE FUNCTION CHAR(71) TO DC-UD-PACKET(4:1)
           COMPUTE WS-B1 = FUNCTION INTEGER(DC-UD-SSRC / 16777216)
           COMPUTE WS-B2 =
               FUNCTION INTEGER(
                   FUNCTION MOD(DC-UD-SSRC, 16777216) / 65536)
           COMPUTE WS-B3 =
               FUNCTION INTEGER(FUNCTION MOD(DC-UD-SSRC, 65536) / 256)
           COMPUTE WS-B4 = FUNCTION MOD(DC-UD-SSRC, 256)
           MOVE FUNCTION CHAR(WS-B1 + 1) TO DC-UD-PACKET(5:1)
           MOVE FUNCTION CHAR(WS-B2 + 1) TO DC-UD-PACKET(6:1)
           MOVE FUNCTION CHAR(WS-B3 + 1) TO DC-UD-PACKET(7:1)
           MOVE FUNCTION CHAR(WS-B4 + 1) TO DC-UD-PACKET(8:1)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-UDP-DISCOVERY-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-UDP-DISCOVERY-PARSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TYPE PIC 9(5) COMP-5.
       01 WS-LENGTH PIC 9(5) COMP-5.
       01 WS-INDEX PIC 9(5) COMP-5.
       01 WS-TEXT-LEN PIC 9(5) COMP-5.

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-UDP-DISCOVERY DC-RESULT.
       MAIN.
           COMPUTE WS-TYPE =
               ((FUNCTION ORD(DC-UD-PACKET(1:1)) - 1) * 256)
               + (FUNCTION ORD(DC-UD-PACKET(2:1)) - 1)
           COMPUTE WS-LENGTH =
               ((FUNCTION ORD(DC-UD-PACKET(3:1)) - 1) * 256)
               + (FUNCTION ORD(DC-UD-PACKET(4:1)) - 1)
           IF WS-TYPE NOT = 2 OR WS-LENGTH NOT = 70
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "Voice UDP discovery response was invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO DC-UD-DISCOVERED-IP
           MOVE 0 TO DC-UD-DISCOVERED-PORT
           MOVE 0 TO WS-TEXT-LEN
           PERFORM VARYING WS-INDEX FROM 9 BY 1 UNTIL WS-INDEX > 72
               IF DC-UD-PACKET(WS-INDEX:1) = LOW-VALUE
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-TEXT-LEN
               MOVE DC-UD-PACKET(WS-INDEX:1)
                   TO DC-UD-DISCOVERED-IP(WS-TEXT-LEN:1)
           END-PERFORM
           COMPUTE DC-UD-DISCOVERED-PORT =
               ((FUNCTION ORD(DC-UD-PACKET(73:1)) - 1) * 256)
               + (FUNCTION ORD(DC-UD-PACKET(74:1)) - 1)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-UDP-DISCOVERY-PARSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-UDP-DISCOVERY-APPLY.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-SELECT-PROTOCOL.
          05 WS-SP-PROTOCOL PIC X(16).
          05 WS-SP-ADDRESS PIC X(64).
          05 WS-SP-PORT PIC 9(5) COMP-5.
          05 WS-SP-MODE PIC X(64).
       01 WS-ACTION PIC X(32) VALUE "SELECT_PROTOCOL".
       01 WS-PAYLOAD PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-UDP-DISCOVERY
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-UD-DISCOVERED-IP) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "Voice UDP discovery IP is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-UD-DISCOVERED-PORT <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "Voice UDP discovery port is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-UD-DISCOVERED-IP TO DC-VS-DISCOVERED-IP
           MOVE DC-UD-DISCOVERED-PORT TO DC-VS-DISCOVERED-PORT

           MOVE "udp" TO WS-SP-PROTOCOL
           MOVE DC-VS-DISCOVERED-IP TO WS-SP-ADDRESS
           MOVE DC-VS-DISCOVERED-PORT TO WS-SP-PORT
           IF FUNCTION TRIM(DC-VS-ENCRYPTION-MODE) NOT = SPACES
               MOVE DC-VS-ENCRYPTION-MODE TO WS-SP-MODE
           ELSE
               MOVE "aead_xchacha20_poly1305_rtpsize" TO WS-SP-MODE
           END-IF

           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-SELECT-PROTOCOL-BUILD"
               USING WS-SELECT-PROTOCOL
                     WS-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-QUEUE-PAYLOAD"
               USING DC-VOICE-SESSION
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-UDP-DISCOVERY-APPLY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-UDP-SESSION-LOAD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-UDP-SESSION
           DC-RESULT.
       MAIN.
           INITIALIZE DC-UDP-SESSION
           MOVE DC-VS-UDP-HANDLE TO DC-UDP-HANDLE
           MOVE DC-VS-IP TO DC-UDP-REMOTE-HOST
           MOVE DC-VS-PORT TO DC-UDP-REMOTE-PORT
           MOVE DC-VS-DISCOVERED-IP TO DC-UDP-LOCAL-IP
           MOVE DC-VS-DISCOVERED-PORT TO DC-UDP-LOCAL-PORT
           MOVE DC-VS-UDP-READY-FLAG TO DC-UDP-READY-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-UDP-SESSION-LOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-UDP-SESSION-SAVE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-UDP-SESSION
           DC-RESULT.
       MAIN.
           MOVE DC-UDP-HANDLE TO DC-VS-UDP-HANDLE
           MOVE DC-UDP-LOCAL-IP TO DC-VS-DISCOVERED-IP
           MOVE DC-UDP-LOCAL-PORT TO DC-VS-DISCOVERED-PORT
           MOVE DC-UDP-READY-FLAG TO DC-VS-UDP-READY-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-UDP-SESSION-SAVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-UDP-DISCOVER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-VS-IP) = SPACES OR DC-VS-PORT <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "Voice UDP endpoint is not available yet."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-VS-SSRC <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "Voice SSRC is required before UDP discovery."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-VOICE-UDP-SESSION-LOAD"
               USING DC-VOICE-SESSION
                     DC-UDP-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF DC-UDP-HANDLE <= 0
               CALL "DC-UDP-OPEN"
                   USING DC-UDP-SESSION
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           INITIALIZE DC-UDP-DISCOVERY
           MOVE DC-VS-SSRC TO DC-UD-SSRC
           CALL "DC-VOICE-UDP-DISCOVERY-BUILD"
               USING DC-UDP-DISCOVERY
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           INITIALIZE DC-UDP-PACKET
           MOVE 74 TO DC-UDP-PACKET-LENGTH
           MOVE DC-UD-PACKET TO DC-UDP-PACKET-DATA(1:74)
           CALL "DC-UDP-SEND"
               USING DC-UDP-SESSION
                     DC-UDP-PACKET
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-RECV"
               USING DC-UDP-SESSION
                     DC-UDP-PACKET
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           INITIALIZE DC-UDP-DISCOVERY
           IF DC-UDP-PACKET-LENGTH > 0
               MOVE DC-UDP-PACKET-DATA(1:DC-UDP-PACKET-LENGTH)
                   TO DC-UD-PACKET(1:DC-UDP-PACKET-LENGTH)
           END-IF
           CALL "DC-VOICE-UDP-DISCOVERY-PARSE"
               USING DC-UDP-DISCOVERY
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-UDP-DISCOVERY-APPLY"
               USING DC-VOICE-SESSION
                     DC-UDP-DISCOVERY
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE DC-UD-DISCOVERED-IP TO DC-UDP-LOCAL-IP
           MOVE DC-UD-DISCOVERED-PORT TO DC-UDP-LOCAL-PORT
           CALL "DC-VOICE-UDP-SESSION-SAVE"
               USING DC-VOICE-SESSION
                     DC-UDP-SESSION
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-UDP-DISCOVER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-SEND-FRAME.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       01 WS-RTP-HEADER.
          05 WS-RTP-BYTE-0 PIC X.
          05 WS-RTP-BYTE-1 PIC X.
          05 WS-RTP-SEQUENCE-BYTES PIC X(2).
          05 WS-RTP-TIMESTAMP-BYTES PIC X(4).
          05 WS-RTP-SSRC-BYTES PIC X(4).
       01 WS-RTP-PACKET.
          05 WS-RTP-PACKET-LENGTH PIC 9(5) COMP-5.
          05 WS-RTP-PACKET-DATA PIC X(8192).
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-RTP-STATE
           DC-OPUS-FRAME
           DC-RESULT.
       MAIN.
           IF DC-VS-READY-FLAG NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Voice session is not ready." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-VS-UDP-HANDLE <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "Voice UDP session is not open."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-VS-ENCRYPTION-MODE) = SPACES
               CALL "DC-RTP-BUILD-PACKET"
                   USING DC-RTP-STATE
                         DC-OPUS-FRAME
                         WS-RTP-PACKET
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           ELSE
               INITIALIZE WS-RTP-HEADER
               CALL "DC-RTP-BUILD-HEADER"
                   USING DC-RTP-STATE
                         WS-RTP-HEADER
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               CALL "DC-CRYPTO-ENCRYPT-VOICE"
                   USING DC-VOICE-SESSION
                         WS-RTP-HEADER
                         DC-OPUS-FRAME
                         WS-RTP-PACKET
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           CALL "DC-VOICE-UDP-SESSION-LOAD"
               USING DC-VOICE-SESSION
                     DC-UDP-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           INITIALIZE DC-UDP-PACKET
           MOVE WS-RTP-PACKET-LENGTH TO DC-UDP-PACKET-LENGTH
           IF WS-RTP-PACKET-LENGTH > 0
               MOVE WS-RTP-PACKET-DATA(1:WS-RTP-PACKET-LENGTH)
                   TO DC-UDP-PACKET-DATA(1:WS-RTP-PACKET-LENGTH)
           END-IF

           CALL "DC-UDP-SEND"
               USING DC-UDP-SESSION
                     DC-UDP-PACKET
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-UDP-SESSION-SAVE"
               USING DC-VOICE-SESSION
                     DC-UDP-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-RTP-ADVANCE"
               USING DC-RTP-STATE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-SEND-FRAME.
