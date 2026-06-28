       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-OPEN.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-UDP-SESSION DC-RESULT.
       MAIN.
           MOVE 0 TO DC-UDP-HANDLE
           MOVE 0 TO DC-UDP-READY-FLAG
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
           MOVE "UDP sockets are not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-UDP-OPEN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-SEND.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-UDP-SESSION
           DC-UDP-PACKET
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
           MOVE "UDP send is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-UDP-SEND.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-RECV.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-UDP-SESSION
           DC-UDP-PACKET
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
           MOVE "UDP receive is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-UDP-RECV.
