       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TCP-CONNECT.
       *> JP: TCP 接続の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: 実通信とテスト loopback が同じ表面 API を使えるようにしています。
       *> EN: Helpers for TCP open/send/recv/close plus fixture support.
       *> EN: Real transport and test loopback paths share the same surface API through this file.

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
           IF FUNCTION TRIM(DC-TCP-HOST) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP" TO DC-ERROR-CODE
               MOVE "TCP host is required." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TCP-PORT <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP" TO DC-ERROR-CODE
               MOVE "TCP port must be greater than zero."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR DC-TCP-ENTRY-IN-USE(WS-IDX) = 0
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP_POOL_FULL" TO DC-ERROR-CODE
               MOVE "TCP connection table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-TCP-REGISTRY-ENTRY(WS-IDX)
           MOVE 1 TO DC-TCP-ENTRY-IN-USE(WS-IDX)
           MOVE DC-TCP-HOST TO DC-TCP-ENTRY-HOST(WS-IDX)
           MOVE DC-TCP-PORT TO DC-TCP-ENTRY-PORT(WS-IDX)
           MOVE -1 TO DC-TCP-ENTRY-READ-FD(WS-IDX)
           MOVE -1 TO DC-TCP-ENTRY-WRITE-FD(WS-IDX)

           MOVE 0 TO WS-FIXTURE-IDX
           PERFORM VARYING WS-FIXTURE-IDX FROM 1 BY 1
               UNTIL WS-FIXTURE-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-TCP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
                  AND FUNCTION TRIM(
                      DC-TCP-FIXTURE-HOST(WS-FIXTURE-IDX))
                      = FUNCTION TRIM(DC-TCP-HOST)
                  AND DC-TCP-FIXTURE-PORT(WS-FIXTURE-IDX)
                      = DC-TCP-PORT)
               CONTINUE
           END-PERFORM

           IF WS-FIXTURE-IDX <= DC-TRANSPORT-MAX-ENTRIES
               AND DC-TCP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
               MOVE DC-TCP-FIXTURE-RESPONSE-LENGTH(WS-FIXTURE-IDX)
                   TO DC-TCP-ENTRY-INBOUND-LENGTH(WS-IDX)
               MOVE DC-TCP-FIXTURE-RESPONSE(WS-FIXTURE-IDX)
                   TO DC-TCP-ENTRY-INBOUND(WS-IDX)
           ELSE
               MOVE SPACES TO WS-COMMAND
               MOVE DC-TCP-PORT TO WS-PORT-TEXT
               STRING
                   "nc " DELIMITED BY SIZE
                   FUNCTION TRIM(DC-TCP-HOST) DELIMITED BY SIZE
                   " " DELIMITED BY SIZE
                   FUNCTION TRIM(WS-PORT-TEXT) DELIMITED BY SIZE
                   INTO WS-COMMAND
               END-STRING
               CALL "DC-PROC-SPAWN"
                   USING WS-COMMAND
                         WS-PROC-READ-FD
                         WS-PROC-WRITE-FD
                         WS-PROC-PID
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   INITIALIZE DC-TCP-REGISTRY-ENTRY(WS-IDX)
                   GOBACK
               END-IF
               MOVE 1 TO DC-TCP-ENTRY-LIVE-FLAG(WS-IDX)
               MOVE WS-PROC-PID TO DC-TCP-ENTRY-CHILD-PID(WS-IDX)
               MOVE WS-PROC-READ-FD TO DC-TCP-ENTRY-READ-FD(WS-IDX)
               MOVE WS-PROC-WRITE-FD TO DC-TCP-ENTRY-WRITE-FD(WS-IDX)
           END-IF

           MOVE WS-IDX TO DC-TCP-HANDLE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TCP-CONNECT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TCP-SEND.
       *> JP: TCP 接続の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: 実通信とテスト loopback が同じ表面 API を使えるようにしています。
       *> EN: Helpers for TCP open/send/recv/close plus fixture support.
       *> EN: Real transport and test loopback paths share the same surface API through this file.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FIXTURE-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-TCP-HANDLE-IN PIC 9(10) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TCP-HANDLE-IN
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           MOVE DC-TCP-HANDLE-IN TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP_HANDLE" TO DC-ERROR-CODE
               MOVE "TCP handle is invalid." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TCP-ENTRY-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP_HANDLE" TO DC-ERROR-CODE
               MOVE "TCP handle is not open." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-HTTP-BUFFER-LENGTH < 0 OR DC-HTTP-BUFFER-LENGTH > 16384
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP" TO DC-ERROR-CODE
               MOVE "TCP send buffer length is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-HTTP-BUFFER-LENGTH
               TO DC-TCP-ENTRY-OUTBOUND-LENGTH(WS-IDX)
           MOVE DC-HTTP-BUFFER-DATA TO DC-TCP-ENTRY-OUTBOUND(WS-IDX)

           MOVE 0 TO WS-FIXTURE-IDX
           PERFORM VARYING WS-FIXTURE-IDX FROM 1 BY 1
               UNTIL WS-FIXTURE-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-TCP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
                  AND FUNCTION TRIM(
                      DC-TCP-FIXTURE-HOST(WS-FIXTURE-IDX))
                      = FUNCTION TRIM(DC-TCP-ENTRY-HOST(WS-IDX))
                  AND DC-TCP-FIXTURE-PORT(WS-FIXTURE-IDX)
                      = DC-TCP-ENTRY-PORT(WS-IDX))
               CONTINUE
           END-PERFORM

           IF WS-FIXTURE-IDX <= DC-TRANSPORT-MAX-ENTRIES
               AND DC-TCP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
               MOVE DC-HTTP-BUFFER-LENGTH
                   TO DC-TCP-FIXTURE-LAST-REQUEST-LENGTH(WS-FIXTURE-IDX)
               MOVE DC-HTTP-BUFFER-DATA
                   TO DC-TCP-FIXTURE-LAST-REQUEST(WS-FIXTURE-IDX)
           END-IF

           IF DC-TCP-ENTRY-LIVE-FLAG(WS-IDX) = 1
               CALL "DC-PROC-WRITE"
                   USING DC-TCP-ENTRY-WRITE-FD(WS-IDX)
                         DC-HTTP-BUFFER
                         DC-RESULT
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TCP-SEND.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TCP-RECV.
       *> JP: TCP 接続の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: 実通信とテスト loopback が同じ表面 API を使えるようにしています。
       *> EN: Helpers for TCP open/send/recv/close plus fixture support.
       *> EN: Real transport and test loopback paths share the same surface API through this file.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-ERROR-CODE PIC X(64).
          05 WS-CLEANUP-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-TCP-HANDLE-IN PIC 9(10) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TCP-HANDLE-IN
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-HTTP-BUFFER-LENGTH
           MOVE SPACES TO DC-HTTP-BUFFER-DATA
           MOVE DC-TCP-HANDLE-IN TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP_HANDLE" TO DC-ERROR-CODE
               MOVE "TCP handle is invalid." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TCP-ENTRY-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP_HANDLE" TO DC-ERROR-CODE
               MOVE "TCP handle is not open." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TCP-ENTRY-LIVE-FLAG(WS-IDX) = 1
               CALL "DC-PROC-READ"
                   USING DC-TCP-ENTRY-READ-FD(WS-IDX)
                         DC-HTTP-BUFFER
                         DC-RESULT
               IF DC-STATUS-CODE = DC-STATUS-OK
                   MOVE DC-HTTP-BUFFER-LENGTH
                       TO DC-TCP-ENTRY-INBOUND-LENGTH(WS-IDX)
                   MOVE DC-HTTP-BUFFER-DATA
                       TO DC-TCP-ENTRY-INBOUND(WS-IDX)
               END-IF
               IF DC-STATUS-CODE = DC-STATUS-EOF
                   CALL "DC-PROC-CLOSE"
                       USING DC-TCP-ENTRY-CHILD-PID(WS-IDX)
                             DC-TCP-ENTRY-READ-FD(WS-IDX)
                             DC-TCP-ENTRY-WRITE-FD(WS-IDX)
                             WS-CLEANUP-RESULT
                   INITIALIZE DC-TCP-REGISTRY-ENTRY(WS-IDX)
               END-IF
               GOBACK
           END-IF

           IF DC-TCP-ENTRY-INBOUND-LENGTH(WS-IDX) = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "TCP inbound buffer is empty."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-TCP-ENTRY-INBOUND-LENGTH(WS-IDX)
               TO DC-HTTP-BUFFER-LENGTH
           MOVE DC-TCP-ENTRY-INBOUND(WS-IDX) TO DC-HTTP-BUFFER-DATA
           MOVE 0 TO DC-TCP-ENTRY-INBOUND-LENGTH(WS-IDX)
           MOVE SPACES TO DC-TCP-ENTRY-INBOUND(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TCP-RECV.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TCP-CLOSE.
       *> JP: TCP 接続の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: 実通信とテスト loopback が同じ表面 API を使えるようにしています。
       *> EN: Helpers for TCP open/send/recv/close plus fixture support.
       *> EN: Real transport and test loopback paths share the same surface API through this file.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-ERROR-CODE PIC X(64).
          05 WS-CLEANUP-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-TCP-HANDLE-IN PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TCP-HANDLE-IN
           DC-RESULT.
       MAIN.
           MOVE DC-TCP-HANDLE-IN TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP_HANDLE" TO DC-ERROR-CODE
               MOVE "TCP handle is invalid." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TCP-ENTRY-IN-USE(WS-IDX) NOT = 1
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           IF DC-TCP-ENTRY-LIVE-FLAG(WS-IDX) = 1
               CALL "DC-PROC-CLOSE"
                   USING DC-TCP-ENTRY-CHILD-PID(WS-IDX)
                         DC-TCP-ENTRY-READ-FD(WS-IDX)
                         DC-TCP-ENTRY-WRITE-FD(WS-IDX)
                         WS-CLEANUP-RESULT
           END-IF

           INITIALIZE DC-TCP-REGISTRY-ENTRY(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TCP-CLOSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TCP-MOCK-SET-RESPONSE.
       *> JP: TCP 接続の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: 実通信とテスト loopback が同じ表面 API を使えるようにしています。
       *> EN: Helpers for TCP open/send/recv/close plus fixture support.
       *> EN: Real transport and test loopback paths share the same surface API through this file.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-TCP-HOST PIC X(256).
       01 DC-TCP-PORT PIC 9(5) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TCP-HOST
           DC-TCP-PORT
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-TCP-HOST) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP" TO DC-ERROR-CODE
               MOVE "TCP fixture host is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-TCP-FIXTURE-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-TCP-FIXTURE-HOST(WS-IDX))
                      = FUNCTION TRIM(DC-TCP-HOST)
                  AND DC-TCP-FIXTURE-PORT(WS-IDX) = DC-TCP-PORT)
                  OR DC-TCP-FIXTURE-IN-USE(WS-IDX) = 0
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP_POOL_FULL" TO DC-ERROR-CODE
               MOVE "TCP fixture table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-TCP-FIXTURE-ENTRY(WS-IDX)
           MOVE 1 TO DC-TCP-FIXTURE-IN-USE(WS-IDX)
           MOVE DC-TCP-HOST TO DC-TCP-FIXTURE-HOST(WS-IDX)
           MOVE DC-TCP-PORT TO DC-TCP-FIXTURE-PORT(WS-IDX)
           MOVE DC-HTTP-BUFFER-LENGTH
               TO DC-TCP-FIXTURE-RESPONSE-LENGTH(WS-IDX)
           MOVE DC-HTTP-BUFFER-DATA TO DC-TCP-FIXTURE-RESPONSE(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TCP-MOCK-SET-RESPONSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TCP-MOCK-GET-LAST-REQUEST.
       *> JP: TCP 接続の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: 実通信とテスト loopback が同じ表面 API を使えるようにしています。
       *> EN: Helpers for TCP open/send/recv/close plus fixture support.
       *> EN: Real transport and test loopback paths share the same surface API through this file.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-TCP-HOST PIC X(256).
       01 DC-TCP-PORT PIC 9(5) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TCP-HOST
           DC-TCP-PORT
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-HTTP-BUFFER-LENGTH
           MOVE SPACES TO DC-HTTP-BUFFER-DATA
           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-TCP-FIXTURE-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-TCP-FIXTURE-HOST(WS-IDX))
                      = FUNCTION TRIM(DC-TCP-HOST)
                  AND DC-TCP-FIXTURE-PORT(WS-IDX) = DC-TCP-PORT)
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               OR DC-TCP-FIXTURE-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_TCP_FIXTURE_NOT_FOUND" TO DC-ERROR-CODE
               MOVE "TCP fixture was not found."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-TCP-FIXTURE-LAST-REQUEST-LENGTH(WS-IDX) = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "TCP fixture has no recorded request."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-TCP-FIXTURE-LAST-REQUEST-LENGTH(WS-IDX)
               TO DC-HTTP-BUFFER-LENGTH
           MOVE DC-TCP-FIXTURE-LAST-REQUEST(WS-IDX)
               TO DC-HTTP-BUFFER-DATA
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TCP-MOCK-GET-LAST-REQUEST.
