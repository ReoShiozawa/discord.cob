       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-OPEN.
       *> JP: UDP socket の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: voice discovery や音声 packet 送信の土台になる最小 transport 層です。
       *> EN: Helpers for UDP open/send/recv/close plus fixture support.
       *> EN: It is the minimal transport layer underneath voice discovery and audio-packet sending.

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
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-UDP-SESSION DC-RESULT.
       MAIN.
           MOVE 0 TO DC-UDP-HANDLE
           MOVE 0 TO DC-UDP-READY-FLAG
           IF FUNCTION TRIM(DC-UDP-REMOTE-HOST) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "UDP remote host is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-UDP-REMOTE-PORT <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "UDP remote port must be greater than zero."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR DC-UDP-ENTRY-IN-USE(WS-IDX) = 0
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_POOL_FULL" TO DC-ERROR-CODE
               MOVE "UDP session table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-UDP-REGISTRY-ENTRY(WS-IDX)
           MOVE 1 TO DC-UDP-ENTRY-IN-USE(WS-IDX)
           MOVE DC-UDP-REMOTE-HOST TO DC-UDP-ENTRY-HOST(WS-IDX)
           MOVE DC-UDP-REMOTE-PORT TO DC-UDP-ENTRY-PORT(WS-IDX)
           MOVE -1 TO DC-UDP-ENTRY-READ-FD(WS-IDX)
           MOVE -1 TO DC-UDP-ENTRY-WRITE-FD(WS-IDX)

           MOVE 0 TO WS-FIXTURE-IDX
           PERFORM VARYING WS-FIXTURE-IDX FROM 1 BY 1
               UNTIL WS-FIXTURE-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-UDP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
                  AND FUNCTION TRIM(
                      DC-UDP-FIXTURE-HOST(WS-FIXTURE-IDX))
                      = FUNCTION TRIM(DC-UDP-REMOTE-HOST)
                  AND DC-UDP-FIXTURE-PORT(WS-FIXTURE-IDX)
                      = DC-UDP-REMOTE-PORT)
               CONTINUE
           END-PERFORM

           IF WS-FIXTURE-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE SPACES TO WS-COMMAND
               MOVE DC-UDP-REMOTE-PORT TO WS-PORT-TEXT
               STRING
                   "nc -u " DELIMITED BY SIZE
                   FUNCTION TRIM(DC-UDP-REMOTE-HOST) DELIMITED BY SIZE
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
                   INITIALIZE DC-UDP-REGISTRY-ENTRY(WS-IDX)
                   GOBACK
               END-IF
               MOVE 1 TO DC-UDP-ENTRY-LIVE-FLAG(WS-IDX)
               MOVE WS-PROC-PID TO DC-UDP-ENTRY-CHILD-PID(WS-IDX)
               MOVE WS-PROC-READ-FD TO DC-UDP-ENTRY-READ-FD(WS-IDX)
               MOVE WS-PROC-WRITE-FD TO DC-UDP-ENTRY-WRITE-FD(WS-IDX)
           END-IF

           MOVE WS-IDX TO DC-UDP-HANDLE
           MOVE 1 TO DC-UDP-READY-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-UDP-OPEN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-SEND.
       *> JP: UDP socket の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: voice discovery や音声 packet 送信の土台になる最小 transport 層です。
       *> EN: Helpers for UDP open/send/recv/close plus fixture support.
       *> EN: It is the minimal transport layer underneath voice discovery and audio-packet sending.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FIXTURE-IDX PIC 9(4) COMP-5.
       01 WS-HTTP-BUFFER.
          05 WS-HTTP-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 WS-HTTP-BUFFER-DATA PIC X(16384).

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-UDP-SESSION
           DC-UDP-PACKET
           DC-RESULT.
       MAIN.
           MOVE DC-UDP-HANDLE TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_HANDLE" TO DC-ERROR-CODE
               MOVE "UDP handle is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-UDP-ENTRY-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_HANDLE" TO DC-ERROR-CODE
               MOVE "UDP handle is not open."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-UDP-PACKET-LENGTH < 0 OR DC-UDP-PACKET-LENGTH > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "UDP packet length is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-UDP-PACKET-LENGTH TO DC-UDP-ENTRY-OUTBOUND-LENGTH(WS-IDX)
           MOVE DC-UDP-PACKET-DATA TO DC-UDP-ENTRY-OUTBOUND(WS-IDX)

           MOVE 0 TO WS-FIXTURE-IDX
           PERFORM VARYING WS-FIXTURE-IDX FROM 1 BY 1
               UNTIL WS-FIXTURE-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-UDP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
                  AND FUNCTION TRIM(DC-UDP-FIXTURE-HOST(WS-FIXTURE-IDX))
                      = FUNCTION TRIM(DC-UDP-ENTRY-HOST(WS-IDX))
                  AND DC-UDP-FIXTURE-PORT(WS-FIXTURE-IDX)
                      = DC-UDP-ENTRY-PORT(WS-IDX))
               CONTINUE
           END-PERFORM

           IF WS-FIXTURE-IDX <= DC-TRANSPORT-MAX-ENTRIES
               AND DC-UDP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
               MOVE DC-UDP-PACKET-LENGTH
                   TO DC-UDP-FIXTURE-LAST-REQUEST-LENGTH(WS-FIXTURE-IDX)
               MOVE DC-UDP-PACKET-DATA
                   TO DC-UDP-FIXTURE-LAST-REQUEST(WS-FIXTURE-IDX)
           END-IF

           IF DC-UDP-ENTRY-LIVE-FLAG(WS-IDX) = 1
               INITIALIZE WS-HTTP-BUFFER
               MOVE DC-UDP-PACKET-LENGTH TO WS-HTTP-BUFFER-LENGTH
               IF DC-UDP-PACKET-LENGTH > 0
                   MOVE DC-UDP-PACKET-DATA(1:DC-UDP-PACKET-LENGTH)
                       TO WS-HTTP-BUFFER-DATA(1:DC-UDP-PACKET-LENGTH)
               END-IF
               CALL "DC-PROC-WRITE"
                   USING DC-UDP-ENTRY-WRITE-FD(WS-IDX)
                         WS-HTTP-BUFFER
                         DC-RESULT
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-UDP-SEND.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-RECV.
       *> JP: UDP socket の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: voice discovery や音声 packet 送信の土台になる最小 transport 層です。
       *> EN: Helpers for UDP open/send/recv/close plus fixture support.
       *> EN: It is the minimal transport layer underneath voice discovery and audio-packet sending.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FIXTURE-IDX PIC 9(4) COMP-5.
       01 WS-HTTP-BUFFER.
          05 WS-HTTP-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 WS-HTTP-BUFFER-DATA PIC X(16384).
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-ERROR-CODE PIC X(64).
          05 WS-CLEANUP-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-UDP-SESSION
           DC-UDP-PACKET
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-UDP-PACKET-LENGTH
           MOVE SPACES TO DC-UDP-PACKET-DATA
           MOVE DC-UDP-HANDLE TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_HANDLE" TO DC-ERROR-CODE
               MOVE "UDP handle is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-UDP-ENTRY-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_HANDLE" TO DC-ERROR-CODE
               MOVE "UDP handle is not open."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-UDP-ENTRY-LIVE-FLAG(WS-IDX) = 1
               CALL "DC-PROC-READ"
                   USING DC-UDP-ENTRY-READ-FD(WS-IDX)
                         WS-HTTP-BUFFER
                         DC-RESULT
               IF DC-STATUS-CODE = DC-STATUS-OK
                   IF WS-HTTP-BUFFER-LENGTH > 8192
                       MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                       MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
                       MOVE "UDP packet exceeded the packet buffer."
                           TO DC-ERROR-MESSAGE
                       GOBACK
                   END-IF
                   MOVE WS-HTTP-BUFFER-LENGTH TO DC-UDP-PACKET-LENGTH
                   IF WS-HTTP-BUFFER-LENGTH > 0
                       MOVE WS-HTTP-BUFFER-DATA(1:WS-HTTP-BUFFER-LENGTH)
                           TO DC-UDP-PACKET-DATA(1:WS-HTTP-BUFFER-LENGTH)
                   END-IF
                   GOBACK
               END-IF
               IF DC-STATUS-CODE = DC-STATUS-EOF
                   CALL "DC-PROC-CLOSE"
                       USING DC-UDP-ENTRY-CHILD-PID(WS-IDX)
                             DC-UDP-ENTRY-READ-FD(WS-IDX)
                             DC-UDP-ENTRY-WRITE-FD(WS-IDX)
                             WS-CLEANUP-RESULT
                   INITIALIZE DC-UDP-REGISTRY-ENTRY(WS-IDX)
               END-IF
               GOBACK
           END-IF

           IF DC-UDP-ENTRY-INBOUND-LENGTH(WS-IDX) = 0
               MOVE 0 TO WS-FIXTURE-IDX
               PERFORM VARYING WS-FIXTURE-IDX FROM 1 BY 1
                   UNTIL WS-FIXTURE-IDX > DC-TRANSPORT-MAX-ENTRIES
                      OR (DC-UDP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
                      AND FUNCTION TRIM(
                          DC-UDP-FIXTURE-HOST(WS-FIXTURE-IDX))
                          = FUNCTION TRIM(DC-UDP-ENTRY-HOST(WS-IDX))
                      AND DC-UDP-FIXTURE-PORT(WS-FIXTURE-IDX)
                          = DC-UDP-ENTRY-PORT(WS-IDX))
                   CONTINUE
               END-PERFORM

               IF WS-FIXTURE-IDX <= DC-TRANSPORT-MAX-ENTRIES
                   AND DC-UDP-FIXTURE-IN-USE(WS-FIXTURE-IDX) = 1
                   MOVE DC-UDP-FIXTURE-RESPONSE-LENGTH(WS-FIXTURE-IDX)
                       TO DC-UDP-ENTRY-INBOUND-LENGTH(WS-IDX)
                   MOVE DC-UDP-FIXTURE-RESPONSE(WS-FIXTURE-IDX)
                       TO DC-UDP-ENTRY-INBOUND(WS-IDX)
                   MOVE 0 TO DC-UDP-FIXTURE-RESPONSE-LENGTH(WS-FIXTURE-IDX)
                   MOVE SPACES TO DC-UDP-FIXTURE-RESPONSE(WS-FIXTURE-IDX)
               END-IF
           END-IF

           IF DC-UDP-ENTRY-INBOUND-LENGTH(WS-IDX) = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "UDP inbound buffer is empty."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-UDP-ENTRY-INBOUND-LENGTH(WS-IDX) TO DC-UDP-PACKET-LENGTH
           MOVE DC-UDP-ENTRY-INBOUND(WS-IDX) TO DC-UDP-PACKET-DATA
           MOVE 0 TO DC-UDP-ENTRY-INBOUND-LENGTH(WS-IDX)
           MOVE SPACES TO DC-UDP-ENTRY-INBOUND(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-UDP-RECV.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-CLOSE.
       *> JP: UDP socket の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: voice discovery や音声 packet 送信の土台になる最小 transport 層です。
       *> EN: Helpers for UDP open/send/recv/close plus fixture support.
       *> EN: It is the minimal transport layer underneath voice discovery and audio-packet sending.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-ERROR-CODE PIC X(64).
          05 WS-CLEANUP-ERROR-MESSAGE PIC X(256).
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-UDP-SESSION
           DC-RESULT.
       MAIN.
           MOVE DC-UDP-HANDLE TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           IF DC-UDP-ENTRY-LIVE-FLAG(WS-IDX) = 1
               CALL "DC-PROC-CLOSE"
                   USING DC-UDP-ENTRY-CHILD-PID(WS-IDX)
                         DC-UDP-ENTRY-READ-FD(WS-IDX)
                         DC-UDP-ENTRY-WRITE-FD(WS-IDX)
                         WS-CLEANUP-RESULT
           END-IF

           INITIALIZE DC-UDP-REGISTRY-ENTRY(WS-IDX)
           MOVE 0 TO DC-UDP-HANDLE
           MOVE 0 TO DC-UDP-READY-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-UDP-CLOSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-MOCK-SET-RESPONSE.
       *> JP: UDP socket の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: voice discovery や音声 packet 送信の土台になる最小 transport 層です。
       *> EN: Helpers for UDP open/send/recv/close plus fixture support.
       *> EN: It is the minimal transport layer underneath voice discovery and audio-packet sending.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-UDP-HOST PIC X(256).
       01 DC-UDP-PORT PIC 9(5) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-UDP-HOST
           DC-UDP-PORT
           DC-UDP-PACKET
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-UDP-HOST) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
               MOVE "UDP fixture host is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-UDP-FIXTURE-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-UDP-FIXTURE-HOST(WS-IDX))
                      = FUNCTION TRIM(DC-UDP-HOST)
                  AND DC-UDP-FIXTURE-PORT(WS-IDX) = DC-UDP-PORT)
                  OR DC-UDP-FIXTURE-IN-USE(WS-IDX) = 0
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_POOL_FULL" TO DC-ERROR-CODE
               MOVE "UDP fixture table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-UDP-FIXTURE-ENTRY(WS-IDX)
           MOVE 1 TO DC-UDP-FIXTURE-IN-USE(WS-IDX)
           MOVE DC-UDP-HOST TO DC-UDP-FIXTURE-HOST(WS-IDX)
           MOVE DC-UDP-PORT TO DC-UDP-FIXTURE-PORT(WS-IDX)
           MOVE DC-UDP-PACKET-LENGTH
               TO DC-UDP-FIXTURE-RESPONSE-LENGTH(WS-IDX)
           MOVE DC-UDP-PACKET-DATA TO DC-UDP-FIXTURE-RESPONSE(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-UDP-MOCK-SET-RESPONSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-UDP-MOCK-GET-LAST-REQUEST.
       *> JP: UDP socket の open/send/recv/close と fixture 支援をまとめた helper 群です。
       *> JP: voice discovery や音声 packet 送信の土台になる最小 transport 層です。
       *> EN: Helpers for UDP open/send/recv/close plus fixture support.
       *> EN: It is the minimal transport layer underneath voice discovery and audio-packet sending.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-transport.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-UDP-HOST PIC X(256).
       01 DC-UDP-PORT PIC 9(5) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-UDP-HOST
           DC-UDP-PORT
           DC-UDP-PACKET
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-UDP-PACKET-LENGTH
           MOVE SPACES TO DC-UDP-PACKET-DATA
           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-TRANSPORT-MAX-ENTRIES
                  OR (DC-UDP-FIXTURE-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-UDP-FIXTURE-HOST(WS-IDX))
                      = FUNCTION TRIM(DC-UDP-HOST)
                  AND DC-UDP-FIXTURE-PORT(WS-IDX) = DC-UDP-PORT)
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-TRANSPORT-MAX-ENTRIES
               OR DC-UDP-FIXTURE-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_UDP_FIXTURE_NOT_FOUND" TO DC-ERROR-CODE
               MOVE "UDP fixture was not found."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-UDP-FIXTURE-LAST-REQUEST-LENGTH(WS-IDX) = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "UDP fixture has no recorded request."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-UDP-FIXTURE-LAST-REQUEST-LENGTH(WS-IDX)
               TO DC-UDP-PACKET-LENGTH
           MOVE DC-UDP-FIXTURE-LAST-REQUEST(WS-IDX)
               TO DC-UDP-PACKET-DATA
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-UDP-MOCK-GET-LAST-REQUEST.
