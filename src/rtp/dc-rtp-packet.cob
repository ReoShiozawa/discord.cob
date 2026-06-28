       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-RTP-ADVANCE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-rtp.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-RTP-STATE DC-RESULT.
       MAIN.
           CALL "DC-RTP-SEQUENCE-NEXT" USING DC-RTP-STATE DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           CALL "DC-RTP-TIMESTAMP-ADVANCE"
               USING DC-RTP-STATE DC-RESULT
           GOBACK.
       END PROGRAM DC-RTP-ADVANCE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-RTP-BUILD-PACKET.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RTP-HEADER.
          05 WS-RTP-BYTE-0 PIC X.
          05 WS-RTP-BYTE-1 PIC X.
          05 WS-RTP-SEQUENCE-BYTES PIC X(2).
          05 WS-RTP-TIMESTAMP-BYTES PIC X(4).
          05 WS-RTP-SSRC-BYTES PIC X(4).
       01 WS-COPY-LEN PIC 9(5) COMP-5.

       LINKAGE SECTION.
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-RTP-STATE
           DC-OPUS-FRAME
           DC-RTP-PACKET
           DC-RESULT.
       MAIN.
           IF DC-OPUS-LENGTH > 4084
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_RTP_BUILD" TO DC-ERROR-CODE
               MOVE "Opus frame is too large for the RTP packet buffer."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE WS-RTP-HEADER
           CALL "DC-RTP-BUILD-HEADER"
               USING DC-RTP-STATE WS-RTP-HEADER DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE SPACES TO DC-RTP-PACKET-DATA
           MOVE WS-RTP-HEADER TO DC-RTP-PACKET-DATA(1:12)
           MOVE DC-OPUS-LENGTH TO WS-COPY-LEN
           IF WS-COPY-LEN > 0
               MOVE DC-OPUS-DATA(1:WS-COPY-LEN)
                   TO DC-RTP-PACKET-DATA(13:WS-COPY-LEN)
           END-IF
           COMPUTE DC-RTP-PACKET-LENGTH = 12 + DC-OPUS-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-RTP-BUILD-PACKET.
