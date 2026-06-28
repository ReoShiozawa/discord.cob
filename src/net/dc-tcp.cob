       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TCP-CONNECT.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-TCP-HOST PIC X(256).
       01 DC-TCP-PORT PIC 9(5) COMP-5.
       01 DC-TCP-HANDLE PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TCP-HOST
           DC-TCP-PORT
           DC-TCP-HANDLE
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-TCP-HANDLE
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_TCP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "TCP sockets are not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-TCP-CONNECT.
