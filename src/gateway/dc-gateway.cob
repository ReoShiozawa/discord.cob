       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-GATEWAY-CONNECT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           MOVE 1 TO DC-CLIENT-STATE
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
           MOVE "Gateway WebSocket transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-GATEWAY-CONNECT.
