       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-RTP-SEQUENCE-NEXT.
       *> JP: RTP sequence number を前進させる最小 helper です。
       *> JP: 連番ロジックを 1 箇所へ寄せ、packet builder 側を単純化します。
       *> EN: Minimal helper that advances the RTP sequence number.
       *> EN: It centralizes the rolling counter logic so packet builders stay simpler.

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
