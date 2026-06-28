       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OGG-OPUS-OPEN.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-AUDIO-SOURCE
           DC-OPUS-HANDLE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_OPUS_UNSUPPORTED" TO DC-ERROR-CODE
           MOVE "Ogg Opus reading is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-OGG-OPUS-OPEN.
