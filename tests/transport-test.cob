       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRANSPORT-TEST.
       *> JP: TCP/TLS/UDP transport helper と fixture の共通面を検証するテストです。
       *> JP: 実通信 abstraction と loopback fixture が同じ API 契約を守るかを見ます。
       *> EN: Test that verifies the shared surface of TCP/TLS/UDP transport helpers and fixtures.
       *> EN: It checks that real transport abstractions and loopback fixtures obey the same API contract.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-HOST PIC X(256) VALUE "example.test".
       01 WS-TCP-PORT PIC 9(5) COMP-5 VALUE 80.
       01 WS-TLS-PORT PIC 9(5) COMP-5 VALUE 443.
       01 WS-UDP-PORT PIC 9(5) COMP-5 VALUE 5000.
       01 WS-HANDLE PIC 9(10) COMP-5.
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-TCP
           PERFORM TEST-TLS
           PERFORM TEST-UDP
           PERFORM FINISH-TEST.

       TEST-TCP.
           INITIALIZE DC-HTTP-BUFFER
           MOVE 12 TO DC-HTTP-BUFFER-LENGTH
           MOVE "tcp-response" TO DC-HTTP-BUFFER-DATA
           CALL "DC-TCP-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-TCP-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE 0 TO WS-HANDLE
           CALL "DC-TCP-CONNECT"
               USING WS-HOST
                     WS-TCP-PORT
                     WS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK
           IF WS-HANDLE = 0
               DISPLAY "transport-test: tcp handle mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           MOVE 4 TO DC-HTTP-BUFFER-LENGTH
           MOVE "PING" TO DC-HTTP-BUFFER-DATA
           CALL "DC-TCP-SEND"
               USING WS-HANDLE
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TCP-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TCP-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:4) NOT = "PING"
               DISPLAY "transport-test: tcp request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TCP-RECV"
               USING WS-HANDLE
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:12) NOT = "tcp-response"
               DISPLAY "transport-test: tcp response mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-TCP-CLOSE"
               USING WS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK.

       TEST-TLS.
           INITIALIZE DC-HTTP-BUFFER
           MOVE 12 TO DC-HTTP-BUFFER-LENGTH
           MOVE "tls-response" TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE 0 TO WS-HANDLE
           CALL "DC-TLS-CONNECT"
               USING WS-HOST
                     WS-TLS-PORT
                     WS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK
           IF WS-HANDLE = 0
               DISPLAY "transport-test: tls handle mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           MOVE 5 TO DC-HTTP-BUFFER-LENGTH
           MOVE "HELLO" TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-SEND"
               USING WS-HANDLE
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:5) NOT = "HELLO"
               DISPLAY "transport-test: tls request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-RECV"
               USING WS-HANDLE
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:12) NOT = "tls-response"
               DISPLAY "transport-test: tls response mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-TLS-CLOSE"
               USING WS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK.

       TEST-UDP.
           INITIALIZE DC-UDP-PACKET
           MOVE 12 TO DC-UDP-PACKET-LENGTH
           MOVE "udp-response" TO DC-UDP-PACKET-DATA
           CALL "DC-UDP-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-UDP-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-UDP-SESSION
           MOVE WS-HOST TO DC-UDP-REMOTE-HOST
           MOVE WS-UDP-PORT TO DC-UDP-REMOTE-PORT
           CALL "DC-UDP-OPEN"
               USING DC-UDP-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-UDP-HANDLE = 0
               DISPLAY "transport-test: udp handle mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-UDP-PACKET
           MOVE 4 TO DC-UDP-PACKET-LENGTH
           MOVE "PING" TO DC-UDP-PACKET-DATA
           CALL "DC-UDP-SEND"
               USING DC-UDP-SESSION
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-UDP-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-UDP-PACKET-DATA(1:4) NOT = "PING"
               DISPLAY "transport-test: udp request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-RECV"
               USING DC-UDP-SESSION
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-UDP-PACKET-DATA(1:12) NOT = "udp-response"
               DISPLAY "transport-test: udp response mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-UDP-CLOSE"
               USING DC-UDP-SESSION
                     DC-RESULT
           PERFORM CHECK-OK.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "transport-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "transport-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "transport-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM TRANSPORT-TEST.
