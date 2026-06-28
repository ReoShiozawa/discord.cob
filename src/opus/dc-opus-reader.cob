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
           INITIALIZE DC-OPUS-HANDLE
           MOVE 1 TO DC-OPUS-HANDLE-ID
           MOVE DC-AUDIO-SOURCE TO DC-OPUS-SOURCE
           MOVE 0 TO DC-OPUS-EOF-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
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
           INITIALIZE DC-OPUS-FRAME
           MOVE 1 TO DC-OPUS-EOF-FLAG
           MOVE DC-STATUS-EOF TO DC-STATUS-CODE
           MOVE "DC_EOF" TO DC-ERROR-CODE
           MOVE "No Opus file reader is implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-OPUS-READ-FRAME.
