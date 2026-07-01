       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-OPEN.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-AUDIO-SOURCE
           DC-OPUS-HANDLE
           DC-RESULT.
       MAIN.
           CALL "DC-OGG-OPUS-OPEN"
               USING DC-AUDIO-SOURCE
                     DC-OPUS-HANDLE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-OPEN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-READ-FRAME.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-OPUS-HANDLE
           DC-OPUS-FRAME
           DC-RESULT.
       MAIN.
           CALL "DC-OGG-OPUS-READ-FRAME"
               USING DC-OPUS-HANDLE
                     DC-OPUS-FRAME
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-READ-FRAME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-CLOSE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-OPUS-HANDLE DC-RESULT.
       MAIN.
           CALL "DC-OGG-OPUS-CLOSE"
               USING DC-OPUS-HANDLE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-CLOSE.
