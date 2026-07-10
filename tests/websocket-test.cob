       IDENTIFICATION DIVISION.
       PROGRAM-ID. WEBSOCKET-TEST.
       *> JP: WebSocket frame encode/decode と send/recv helper の契約を検証するテストです。
       *> JP: Gateway/Voice 共通で使う WS wire format の土台をここで固定します。
       *> EN: Test that verifies WebSocket frame encode/decode and send/recv contracts.
       *> EN: It fixes the WS wire-format foundation shared by Gateway and Voice flows.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-ACCEPT PIC X(64).
       01 WS-LONG-PAYLOAD PIC X(130).
       01 WS-TEXT-PAYLOAD PIC X(8192).
       01 WS-FRAME-A.
          05 WS-FRAME-A-LENGTH PIC 9(9) COMP-5.
          05 WS-FRAME-A-DATA PIC X(8192).
       01 WS-FRAME-B.
          05 WS-FRAME-B-LENGTH PIC 9(9) COMP-5.
          05 WS-FRAME-B-DATA PIC X(8192).
       01 WS-LIVE-HOST PIC X(256) VALUE "live.example.test".
       01 WS-LIVE-PORT PIC 9(5) COMP-5 VALUE 8443.
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.
       01 WS-IDX PIC 9(4) COMP-5.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-CONNECT
           PERFORM TEST-ENCODE-DECODE
           PERFORM TEST-MASKED-DECODE
           PERFORM TEST-MASKED-ENCODE
           PERFORM TEST-EXTENDED-LENGTH
           PERFORM TEST-LIVE-CONNECT-SEND
           PERFORM TEST-SEND-RECV
           PERFORM TEST-COALESCED-FRAMES
           PERFORM TEST-FRAGMENTED-MESSAGE
           PERFORM TEST-PING-PONG
           PERFORM TEST-CLOSE
           PERFORM TEST-EXPLICIT-CLOSE
           PERFORM FINISH-TEST.

       TEST-CONNECT.
           PERFORM OPEN-SESSION
           IF DC-WS-OPEN-FLAG NOT = 1
               DISPLAY "websocket-test: session was not opened"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-HANDLE = 0
               DISPLAY "websocket-test: session handle was not set"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-WS-SESSION-HOST) NOT = "gateway.discord.gg"
               DISPLAY "websocket-test: session host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-WS-SESSION-PATH) NOT = "/?v=10"
               DISPLAY "websocket-test: session path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-WS-SESSION-SEC-KEY) = SPACES
               DISPLAY "websocket-test: session key missing"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-HANDSHAKE-REQUEST-LENGTH = 0
               DISPLAY "websocket-test: handshake request missing"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-HANDSHAKE-REQUEST(1:17) NOT = "GET /?v=10 HTTP/1"
               DISPLAY "websocket-test: handshake request prefix mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-HANDSHAKE-RESPONSE-LENGTH = 0
               DISPLAY "websocket-test: handshake response missing"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-ENCODE-DECODE.
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 1 TO DC-WS-OPCODE
           MOVE 5 TO DC-WS-PAYLOAD-LENGTH
           MOVE "hello" TO DC-WS-PAYLOAD

           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-BUFFER-LENGTH NOT = 7
               DISPLAY "websocket-test: short frame length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-FIN-FLAG NOT = 1
               DISPLAY "websocket-test: fin flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-OPCODE NOT = 1
               DISPLAY "websocket-test: opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD(1:5) NOT = "hello"
               DISPLAY "websocket-test: payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-MASKED-DECODE.
           INITIALIZE DC-WS-BUFFER
           MOVE 11 TO DC-WS-BUFFER-LENGTH
           MOVE FUNCTION CHAR(130) TO DC-WS-BUFFER-DATA(1:1)
           MOVE FUNCTION CHAR(134) TO DC-WS-BUFFER-DATA(2:1)
           MOVE FUNCTION CHAR(56) TO DC-WS-BUFFER-DATA(3:1)
           MOVE FUNCTION CHAR(251) TO DC-WS-BUFFER-DATA(4:1)
           MOVE FUNCTION CHAR(34) TO DC-WS-BUFFER-DATA(5:1)
           MOVE FUNCTION CHAR(62) TO DC-WS-BUFFER-DATA(6:1)
           MOVE FUNCTION CHAR(128) TO DC-WS-BUFFER-DATA(7:1)
           MOVE FUNCTION CHAR(160) TO DC-WS-BUFFER-DATA(8:1)
           MOVE FUNCTION CHAR(78) TO DC-WS-BUFFER-DATA(9:1)
           MOVE FUNCTION CHAR(82) TO DC-WS-BUFFER-DATA(10:1)
           MOVE FUNCTION CHAR(89) TO DC-WS-BUFFER-DATA(11:1)

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-PAYLOAD(1:5) NOT = "Hello"
               DISPLAY "websocket-test: masked payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-MASKED-ENCODE.
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 1 TO DC-WS-OPCODE
           MOVE 1 TO DC-WS-MASK-FLAG
           MOVE "mask" TO DC-WS-MASK-KEY
           MOVE 5 TO DC-WS-PAYLOAD-LENGTH
           MOVE "hello" TO DC-WS-PAYLOAD

           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION ORD(DC-WS-BUFFER-DATA(2:1)) - 1 NOT = 133
               DISPLAY "websocket-test: masked frame header mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-MASK-FLAG NOT = 1
               DISPLAY "websocket-test: masked frame flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD(1:5) NOT = "hello"
               DISPLAY "websocket-test: masked frame payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-EXTENDED-LENGTH.
           MOVE ALL "A" TO WS-LONG-PAYLOAD
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 2 TO DC-WS-OPCODE
           MOVE 130 TO DC-WS-PAYLOAD-LENGTH
           MOVE WS-LONG-PAYLOAD TO DC-WS-PAYLOAD(1:130)

           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-BUFFER-LENGTH NOT = 134
               DISPLAY "websocket-test: extended frame length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OPCODE NOT = 2
               DISPLAY "websocket-test: extended opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD-LENGTH NOT = 130
               DISPLAY "websocket-test: extended payload length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 130
               IF DC-WS-PAYLOAD(WS-IDX:1) NOT = "A"
                   DISPLAY "websocket-test: extended payload data mismatch"
                   ADD 1 TO WS-FAILURES
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       TEST-LIVE-CONNECT-SEND.
           INITIALIZE DC-WS-REQUEST
           INITIALIZE DC-WS-SESSION
           INITIALIZE DC-HTTP-BUFFER
           MOVE WS-LIVE-HOST TO DC-WS-HOST
           MOVE "/socket" TO DC-WS-PATH
           MOVE "dGhlIHNhbXBsZSBub25jZQ==" TO DC-WS-SEC-KEY
           MOVE WS-LIVE-PORT TO DC-WS-REQUEST-PORT
           MOVE 1 TO DC-WS-REQUEST-LIVE-FLAG

           MOVE SPACES TO WS-ACCEPT
           CALL "DC-WS-BUILD-ACCEPT"
               USING "dGhlIHNhbXBsZSBub25jZQ=="
                     WS-ACCEPT
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 101 Switching Protocols" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Upgrade: websocket" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Connection: Upgrade" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Sec-WebSocket-Accept: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-ACCEPT) DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-LIVE-HOST
                     WS-LIVE-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-WS-CONNECT"
               USING DC-WS-REQUEST DC-WS-SESSION DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-SESSION-LIVE-FLAG NOT = 1
               DISPLAY "websocket-test: live session flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-SESSION-PORT NOT = WS-LIVE-PORT
               DISPLAY "websocket-test: live session port mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-LIVE-HOST
                     WS-LIVE-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:20) NOT = "GET /socket HTTP/1.1"
               DISPLAY "websocket-test: live handshake request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "hello" TO WS-TEXT-PAYLOAD
           CALL "DC-WS-SEND-TEXT"
               USING DC-WS-SESSION WS-TEXT-PAYLOAD DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-LIVE-HOST
                     WS-LIVE-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-HTTP-BUFFER-LENGTH TO DC-WS-BUFFER-LENGTH
           MOVE DC-HTTP-BUFFER-DATA TO DC-WS-BUFFER-DATA
           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-MASK-FLAG NOT = 1
               DISPLAY "websocket-test: live client frame was not masked"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-OPCODE NOT = 1
               DISPLAY "websocket-test: live client opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD(1:5) NOT = "hello"
               DISPLAY "websocket-test: live client payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-TLS-CLOSE"
               USING DC-WS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK.

       TEST-SEND-RECV.
           PERFORM OPEN-SESSION
           MOVE "hello" TO WS-TEXT-PAYLOAD
           CALL "DC-WS-SEND-TEXT"
               USING DC-WS-SESSION WS-TEXT-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OUTBOUND-BUFFER-LENGTH = 0
               DISPLAY "websocket-test: outbound buffer missing"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-RECV"
               USING DC-WS-SESSION DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OPCODE NOT = 1
               DISPLAY "websocket-test: recv opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD(1:5) NOT = "hello"
               DISPLAY "websocket-test: recv payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-PING-PONG.
           PERFORM OPEN-SESSION
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 9 TO DC-WS-OPCODE
           MOVE 2 TO DC-WS-PAYLOAD-LENGTH
           MOVE "hb" TO DC-WS-PAYLOAD(1:2)
           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-WS-BUFFER-LENGTH TO DC-WS-INBOUND-BUFFER-LENGTH
           MOVE DC-WS-BUFFER-DATA TO DC-WS-INBOUND-BUFFER

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-RECV"
               USING DC-WS-SESSION DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OPCODE NOT = 9
               DISPLAY "websocket-test: ping opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD(1:2) NOT = "hb"
               DISPLAY "websocket-test: ping payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-RECV"
               USING DC-WS-SESSION DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OPCODE NOT = 10
               DISPLAY "websocket-test: pong opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD(1:2) NOT = "hb"
               DISPLAY "websocket-test: pong payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-COALESCED-FRAMES.
           PERFORM OPEN-SESSION
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 1 TO DC-WS-OPCODE
           MOVE 3 TO DC-WS-PAYLOAD-LENGTH
           MOVE "one" TO DC-WS-PAYLOAD(1:3)
           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-WS-BUFFER TO WS-FRAME-A

           INITIALIZE DC-WS-FRAME DC-WS-BUFFER
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 1 TO DC-WS-OPCODE
           MOVE 3 TO DC-WS-PAYLOAD-LENGTH
           MOVE "two" TO DC-WS-PAYLOAD(1:3)
           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-WS-BUFFER TO WS-FRAME-B

           COMPUTE DC-WS-INBOUND-BUFFER-LENGTH =
               WS-FRAME-A-LENGTH + WS-FRAME-B-LENGTH
           MOVE WS-FRAME-A-DATA(1:WS-FRAME-A-LENGTH)
               TO DC-WS-INBOUND-BUFFER(1:WS-FRAME-A-LENGTH)
           MOVE WS-FRAME-B-DATA(1:WS-FRAME-B-LENGTH)
               TO DC-WS-INBOUND-BUFFER(
                   WS-FRAME-A-LENGTH + 1:WS-FRAME-B-LENGTH)

           CALL "DC-WS-RECV"
               USING DC-WS-SESSION DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-PAYLOAD(1:3) NOT = "one"
               DISPLAY "websocket-test: first coalesced frame mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-INBOUND-BUFFER-LENGTH NOT = WS-FRAME-B-LENGTH
               DISPLAY "websocket-test: coalesced remainder was lost"
               ADD 1 TO WS-FAILURES
           END-IF
           CALL "DC-WS-RECV"
               USING DC-WS-SESSION DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-PAYLOAD(1:3) NOT = "two"
               DISPLAY "websocket-test: second coalesced frame mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FRAGMENTED-MESSAGE.
           PERFORM OPEN-SESSION
           INITIALIZE DC-WS-FRAME
           MOVE 0 TO DC-WS-FIN-FLAG
           MOVE 1 TO DC-WS-OPCODE
           MOVE 3 TO DC-WS-PAYLOAD-LENGTH
           MOVE "hel" TO DC-WS-PAYLOAD(1:3)
           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-WS-BUFFER TO WS-FRAME-A

           INITIALIZE DC-WS-FRAME DC-WS-BUFFER
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 0 TO DC-WS-OPCODE
           MOVE 2 TO DC-WS-PAYLOAD-LENGTH
           MOVE "lo" TO DC-WS-PAYLOAD(1:2)
           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-WS-BUFFER TO WS-FRAME-B

           COMPUTE DC-WS-INBOUND-BUFFER-LENGTH =
               WS-FRAME-A-LENGTH + WS-FRAME-B-LENGTH
           MOVE WS-FRAME-A-DATA(1:WS-FRAME-A-LENGTH)
               TO DC-WS-INBOUND-BUFFER(1:WS-FRAME-A-LENGTH)
           MOVE WS-FRAME-B-DATA(1:WS-FRAME-B-LENGTH)
               TO DC-WS-INBOUND-BUFFER(
                   WS-FRAME-A-LENGTH + 1:WS-FRAME-B-LENGTH)

           CALL "DC-WS-RECV"
               USING DC-WS-SESSION DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OPCODE NOT = 1 OR DC-WS-FIN-FLAG NOT = 1
               DISPLAY "websocket-test: fragmented metadata mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD-LENGTH NOT = 5
              OR DC-WS-PAYLOAD(1:5) NOT = "hello"
               DISPLAY "websocket-test: fragmented payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CLOSE.
           PERFORM OPEN-SESSION
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 8 TO DC-WS-OPCODE
           MOVE 0 TO DC-WS-PAYLOAD-LENGTH
           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-WS-BUFFER-LENGTH TO DC-WS-INBOUND-BUFFER-LENGTH
           MOVE DC-WS-BUFFER-DATA TO DC-WS-INBOUND-BUFFER

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-RECV"
               USING DC-WS-SESSION DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OPCODE NOT = 8
               DISPLAY "websocket-test: close opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-OPEN-FLAG NOT = 0
               DISPLAY "websocket-test: session did not close"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-EXPLICIT-CLOSE.
           PERFORM OPEN-SESSION
           CALL "DC-WS-CLOSE" USING DC-WS-SESSION DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OPEN-FLAG NOT = 0
               DISPLAY "websocket-test: explicit close left session open"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-OUTBOUND-BUFFER-LENGTH = 0
               DISPLAY "websocket-test: explicit close frame missing"
               ADD 1 TO WS-FAILURES
           END-IF.

       OPEN-SESSION.
           INITIALIZE DC-WS-REQUEST
           INITIALIZE DC-WS-SESSION
           MOVE "gateway.discord.gg" TO DC-WS-HOST
           MOVE "/?v=10" TO DC-WS-PATH
           CALL "DC-WS-CONNECT"
               USING DC-WS-REQUEST DC-WS-SESSION DC-RESULT
           PERFORM CHECK-OK.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "websocket-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "websocket-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "websocket-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM WEBSOCKET-TEST.
