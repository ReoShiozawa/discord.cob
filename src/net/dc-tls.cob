       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TLS-CONNECT.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-TLS-HOST PIC X(256).
       01 DC-TLS-PORT PIC 9(5) COMP-5.
       01 DC-TLS-HANDLE PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TLS-HOST
           DC-TLS-PORT
           DC-TLS-HANDLE
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-TLS-HANDLE
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_TLS_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "TLS is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-TLS-CONNECT.
