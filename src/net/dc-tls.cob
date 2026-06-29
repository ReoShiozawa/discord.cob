       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TLS-CONNECT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FIXTURE-IDX PIC 9(4) COMP-5.
       01 WS-COMMAND PIC X(512).
       01 WS-PORT-TEXT PIC 9(5).
       01 WS-PROC-READ-FD PIC S9(9) COMP-5.
       01 WS-PROC-WRITE-FD PIC S9(9) COMP-5.
       01 WS-PROC-PID PIC S9(9) COMP-5.

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
           IF FUNCTION TRIM(DC-TLS-HOST) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS" TO DC-ERROR-CODE
               MOVE "TLS host is required." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TLS-PORT <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS" TO DC-ERROR-CODE
               MOVE "TLS port must be greater than zero."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR DC-TLS-ENTRY-IN-USE(WS-IDX) = 0
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS_POOL_FULL" TO DC-ERROR-CODE
               MOVE "TLS connection table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-TLS-REGISTRY-ENTRY(WS-IDX)
           MOVE 1 TO DC-TLS-ENTRY-IN-USE(WS-IDX)
           MOVE DC-TLS-HOST TO DC-TLS-ENTRY-HOST(WS-IDX)
           MOVE DC-TLS-PORT TO DC-TLS-ENTRY-PORT(WS-IDX)
           MOVE -1 TO DC-TLS-ENTRY-READ-FD(WS-IDX)
           MOVE -1 TO DC-TLS-ENTRY-WRITE-FD(WS-IDX)

           MOVE 0 TO WS-FIXTURE-IDX
           PERFORM VARYING WS-FIXTURE-IDX FROM 1 BY 1
               UNTIL WS-FIXTURE-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-TLS-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
                  AND FUNCTION TRIM(
                      DC-TLS-FIXTURE-HOST(WS-FIXTURE-IDX))
                      = FUNCTION TRIM(DC-TLS-HOST)
                  AND DC-TLS-FIXTURE-PORT(WS-FIXTURE-IDX)
                      = DC-TLS-PORT)
               CONTINUE
           END-PERFORM

           IF WS-FIXTURE-IDX <= DC-TRANSPORT-MAX-ENTRIES
               AND DC-TLS-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
               MOVE DC-TLS-FIXTURE-RESPONSE-LENGTH(WS-FIXTURE-IDX)
                   TO DC-TLS-ENTRY-INBOUND-LENGTH(WS-IDX)
               MOVE DC-TLS-FIXTURE-RESPONSE(WS-FIXTURE-IDX)
                   TO DC-TLS-ENTRY-INBOUND(WS-IDX)
           ELSE
               MOVE SPACES TO WS-COMMAND
               MOVE DC-TLS-PORT TO WS-PORT-TEXT
               STRING
                   "openssl s_client -quiet -connect "
                       DELIMITED BY SIZE
                   FUNCTION TRIM(DC-TLS-HOST) DELIMITED BY SIZE
                   ":" DELIMITED BY SIZE
                   FUNCTION TRIM(WS-PORT-TEXT) DELIMITED BY SIZE
                   " -servername " DELIMITED BY SIZE
                   FUNCTION TRIM(DC-TLS-HOST) DELIMITED BY SIZE
                   INTO WS-COMMAND
               END-STRING
               CALL "DC-PROC-SPAWN"
                   USING WS-COMMAND
                         WS-PROC-READ-FD
                         WS-PROC-WRITE-FD
                         WS-PROC-PID
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   INITIALIZE DC-TLS-REGISTRY-ENTRY(WS-IDX)
                   GOBACK
               END-IF
               MOVE 1 TO DC-TLS-ENTRY-LIVE-FLAG(WS-IDX)
               MOVE WS-PROC-PID TO DC-TLS-ENTRY-CHILD-PID(WS-IDX)
               MOVE WS-PROC-READ-FD TO DC-TLS-ENTRY-READ-FD(WS-IDX)
               MOVE WS-PROC-WRITE-FD TO DC-TLS-ENTRY-WRITE-FD(WS-IDX)
           END-IF

           MOVE WS-IDX TO DC-TLS-HANDLE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TLS-CONNECT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TLS-SEND.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FIXTURE-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-TLS-HANDLE-IN PIC 9(10) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TLS-HANDLE-IN
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           MOVE DC-TLS-HANDLE-IN TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS_HANDLE" TO DC-ERROR-CODE
               MOVE "TLS handle is invalid." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TLS-ENTRY-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS_HANDLE" TO DC-ERROR-CODE
               MOVE "TLS handle is not open." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-HTTP-BUFFER-LENGTH < 0 OR DC-HTTP-BUFFER-LENGTH > 16384
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS" TO DC-ERROR-CODE
               MOVE "TLS send buffer length is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-HTTP-BUFFER-LENGTH
               TO DC-TLS-ENTRY-OUTBOUND-LENGTH(WS-IDX)
           MOVE DC-HTTP-BUFFER-DATA TO DC-TLS-ENTRY-OUTBOUND(WS-IDX)

           MOVE 0 TO WS-FIXTURE-IDX
           PERFORM VARYING WS-FIXTURE-IDX FROM 1 BY 1
               UNTIL WS-FIXTURE-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-TLS-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
                  AND FUNCTION TRIM(
                      DC-TLS-FIXTURE-HOST(WS-FIXTURE-IDX))
                      = FUNCTION TRIM(DC-TLS-ENTRY-HOST(WS-IDX))
                  AND DC-TLS-FIXTURE-PORT(WS-FIXTURE-IDX)
                      = DC-TLS-ENTRY-PORT(WS-IDX))
               CONTINUE
           END-PERFORM

           IF WS-FIXTURE-IDX <= DC-TRANSPORT-MAX-ENTRIES
               AND DC-TLS-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
               MOVE DC-HTTP-BUFFER-LENGTH
                   TO DC-TLS-FIXTURE-LAST-REQUEST-LENGTH(WS-FIXTURE-IDX)
               MOVE DC-HTTP-BUFFER-DATA
                   TO DC-TLS-FIXTURE-LAST-REQUEST(WS-FIXTURE-IDX)
           END-IF

           IF DC-TLS-ENTRY-LIVE-FLAG(WS-IDX) = 1
               CALL "DC-PROC-WRITE"
                   USING DC-TLS-ENTRY-WRITE-FD(WS-IDX)
                         DC-HTTP-BUFFER
                         DC-RESULT
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TLS-SEND.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TLS-RECV.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-ERROR-CODE PIC X(64).
          05 WS-CLEANUP-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-TLS-HANDLE-IN PIC 9(10) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TLS-HANDLE-IN
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-HTTP-BUFFER-LENGTH
           MOVE SPACES TO DC-HTTP-BUFFER-DATA
           MOVE DC-TLS-HANDLE-IN TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS_HANDLE" TO DC-ERROR-CODE
               MOVE "TLS handle is invalid." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TLS-ENTRY-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS_HANDLE" TO DC-ERROR-CODE
               MOVE "TLS handle is not open." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TLS-ENTRY-LIVE-FLAG(WS-IDX) = 1
               CALL "DC-PROC-READ"
                   USING DC-TLS-ENTRY-READ-FD(WS-IDX)
                         DC-HTTP-BUFFER
                         DC-RESULT
               IF DC-STATUS-CODE = DC-STATUS-OK
                   MOVE DC-HTTP-BUFFER-LENGTH
                       TO DC-TLS-ENTRY-INBOUND-LENGTH(WS-IDX)
                   MOVE DC-HTTP-BUFFER-DATA
                       TO DC-TLS-ENTRY-INBOUND(WS-IDX)
               END-IF
               IF DC-STATUS-CODE = DC-STATUS-EOF
                   CALL "DC-PROC-CLOSE"
                       USING DC-TLS-ENTRY-CHILD-PID(WS-IDX)
                             DC-TLS-ENTRY-READ-FD(WS-IDX)
                             DC-TLS-ENTRY-WRITE-FD(WS-IDX)
                             WS-CLEANUP-RESULT
                   INITIALIZE DC-TLS-REGISTRY-ENTRY(WS-IDX)
               END-IF
               GOBACK
           END-IF

           IF DC-TLS-ENTRY-INBOUND-LENGTH(WS-IDX) = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "TLS inbound buffer is empty."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-TLS-ENTRY-INBOUND-LENGTH(WS-IDX)
               TO DC-HTTP-BUFFER-LENGTH
           MOVE DC-TLS-ENTRY-INBOUND(WS-IDX) TO DC-HTTP-BUFFER-DATA
           MOVE 0 TO DC-TLS-ENTRY-INBOUND-LENGTH(WS-IDX)
           MOVE SPACES TO DC-TLS-ENTRY-INBOUND(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TLS-RECV.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TLS-CLOSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-ERROR-CODE PIC X(64).
          05 WS-CLEANUP-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-TLS-HANDLE-IN PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TLS-HANDLE-IN
           DC-RESULT.
       MAIN.
           MOVE DC-TLS-HANDLE-IN TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS_HANDLE" TO DC-ERROR-CODE
               MOVE "TLS handle is invalid." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TLS-ENTRY-IN-USE(WS-IDX) NOT = 1
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           IF DC-TLS-ENTRY-LIVE-FLAG(WS-IDX) = 1
               CALL "DC-PROC-CLOSE"
                   USING DC-TLS-ENTRY-CHILD-PID(WS-IDX)
                         DC-TLS-ENTRY-READ-FD(WS-IDX)
                         DC-TLS-ENTRY-WRITE-FD(WS-IDX)
                         WS-CLEANUP-RESULT
           END-IF

           INITIALIZE DC-TLS-REGISTRY-ENTRY(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TLS-CLOSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TLS-MOCK-SET-RESPONSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-TLS-HOST PIC X(256).
       01 DC-TLS-PORT PIC 9(5) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TLS-HOST
           DC-TLS-PORT
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-TLS-HOST) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS" TO DC-ERROR-CODE
               MOVE "TLS fixture host is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-TLS-FIXTURE-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-TLS-FIXTURE-HOST(WS-IDX))
                      = FUNCTION TRIM(DC-TLS-HOST)
                  AND DC-TLS-FIXTURE-PORT(WS-IDX) = DC-TLS-PORT)
                  OR DC-TLS-FIXTURE-IN-USE(WS-IDX) = 0
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS_POOL_FULL" TO DC-ERROR-CODE
               MOVE "TLS fixture table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-TLS-FIXTURE-ENTRY(WS-IDX)
           MOVE 1 TO DC-TLS-FIXTURE-IN-USE(WS-IDX)
           MOVE DC-TLS-HOST TO DC-TLS-FIXTURE-HOST(WS-IDX)
           MOVE DC-TLS-PORT TO DC-TLS-FIXTURE-PORT(WS-IDX)
           MOVE DC-HTTP-BUFFER-LENGTH
               TO DC-TLS-FIXTURE-RESPONSE-LENGTH(WS-IDX)
           MOVE DC-HTTP-BUFFER-DATA TO DC-TLS-FIXTURE-RESPONSE(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TLS-MOCK-SET-RESPONSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TLS-MOCK-GET-LAST-REQUEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-TLS-HOST PIC X(256).
       01 DC-TLS-PORT PIC 9(5) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TLS-HOST
           DC-TLS-PORT
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-HTTP-BUFFER-LENGTH
           MOVE SPACES TO DC-HTTP-BUFFER-DATA
           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-TLS-FIXTURE-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-TLS-FIXTURE-HOST(WS-IDX))
                      = FUNCTION TRIM(DC-TLS-HOST)
                  AND DC-TLS-FIXTURE-PORT(WS-IDX) = DC-TLS-PORT)
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               OR DC-TLS-FIXTURE-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_TLS_FIXTURE_NOT_FOUND" TO DC-ERROR-CODE
               MOVE "TLS fixture was not found."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TLS-FIXTURE-LAST-REQUEST-LENGTH(WS-IDX) = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "TLS fixture has no recorded request."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-TLS-FIXTURE-LAST-REQUEST-LENGTH(WS-IDX)
               TO DC-HTTP-BUFFER-LENGTH
           MOVE DC-TLS-FIXTURE-LAST-REQUEST(WS-IDX)
               TO DC-HTTP-BUFFER-DATA
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TLS-MOCK-GET-LAST-REQUEST.
