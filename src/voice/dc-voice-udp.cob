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
       PROGRAM-ID. DC-VOICE-SEND-FRAME.

       DATA DIVISION.
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
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
           MOVE "UDP voice frame sending is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-VOICE-SEND-FRAME.
