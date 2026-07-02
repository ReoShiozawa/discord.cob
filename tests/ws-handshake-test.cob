       IDENTIFICATION DIVISION.
       PROGRAM-ID. WS-HANDSHAKE-TEST.
       *> JP: WebSocket handshake helper 群の request/accept 検証を行うテストです。
       *> JP: upgrade 前段の文字列処理が崩れないことを確認します。
       *> EN: Test that verifies request/accept behavior of the WebSocket-handshake helpers.
       *> EN: It confirms that the string handling before upgrade remains correct.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-ACCEPT PIC X(64).
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-BUILD-REQUEST
           PERFORM TEST-BUILD-ACCEPT
           PERFORM TEST-VALIDATE-RESPONSE
           PERFORM FINISH-TEST.

       TEST-BUILD-REQUEST.
           INITIALIZE DC-WS-REQUEST
           MOVE "gateway.discord.gg" TO DC-WS-HOST
           MOVE "/?v=10&encoding=json" TO DC-WS-PATH
           MOVE "dGhlIHNhbXBsZSBub25jZQ==" TO DC-WS-SEC-KEY
           CALL "DC-WS-BUILD-HANDSHAKE-REQUEST"
               USING DC-WS-REQUEST DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-BUFFER-DATA(1:3) NOT = "GET"
               DISPLAY "ws-handshake-test: request line mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-WS-SEC-KEY)
               NOT = "dGhlIHNhbXBsZSBub25jZQ=="
               DISPLAY "ws-handshake-test: request key mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-ACCEPT.
           MOVE SPACES TO WS-ACCEPT
           CALL "DC-WS-BUILD-ACCEPT"
               USING "dGhlIHNhbXBsZSBub25jZQ=="
                     WS-ACCEPT
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-ACCEPT)
               NOT = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="
               DISPLAY "ws-handshake-test: accept mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VALIDATE-RESPONSE.
           INITIALIZE DC-WS-REQUEST
           MOVE "gateway.discord.gg" TO DC-WS-HOST
           MOVE "/?v=10&encoding=json" TO DC-WS-PATH
           MOVE "dGhlIHNhbXBsZSBub25jZQ==" TO DC-WS-SEC-KEY
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 101 Switching Protocols" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Upgrade: websocket" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Connection: Upgrade" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo="
                   DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           CALL "DC-HTTP-PARSE-RESPONSE"
               USING WS-RAW-RESPONSE DC-HTTP-RESPONSE DC-RESULT
           PERFORM CHECK-OK
           CALL "DC-WS-VALIDATE-HS-RESPONSE"
               USING DC-WS-REQUEST DC-HTTP-RESPONSE DC-RESULT
           PERFORM CHECK-OK.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "ws-handshake-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "ws-handshake-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "ws-handshake-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM WS-HANDSHAKE-TEST.
