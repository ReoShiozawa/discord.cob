       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-PACKET-NEXT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-OPUS-HANDLE
           DC-OPUS-FRAME
           DC-RESULT.
       MAIN.
           CALL "DC-OPUS-READ-FRAME"
               USING DC-OPUS-HANDLE DC-OPUS-FRAME DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-PACKET-NEXT.
