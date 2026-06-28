       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-RTP-SEQUENCE-NEXT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-rtp.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-RTP-STATE DC-RESULT.
       MAIN.
           IF DC-RTP-SEQUENCE >= 65535
               MOVE 0 TO DC-RTP-SEQUENCE
           ELSE
               ADD 1 TO DC-RTP-SEQUENCE
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-RTP-SEQUENCE-NEXT.
