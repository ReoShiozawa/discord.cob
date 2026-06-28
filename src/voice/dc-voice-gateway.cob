       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-GATEWAY-CONNECT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-VOICE-SESSION DC-RESULT.
       MAIN.
           MOVE 2 TO DC-VS-STATE
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
           MOVE "Voice Gateway WebSocket is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-VOICE-GATEWAY-CONNECT.
