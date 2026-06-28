       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-CONNECT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-REQUEST
           DC-WS-SESSION
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-WS-OPEN-FLAG
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "WebSocket transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-WS-CONNECT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-SEND-TEXT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       01 DC-WS-TEXT-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-SESSION
           DC-WS-TEXT-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "WebSocket send is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-WS-SEND-TEXT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-RECV.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-SESSION
           DC-WS-FRAME
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "WebSocket receive is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-WS-RECV.
