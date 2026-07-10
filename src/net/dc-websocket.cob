       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-ENCODE-FRAME.
       *> JP: WebSocket frame の encode/decode と接続 send/recv の helper 群です。
       *> JP: Gateway/Voice 両方の WS session が共有する wire-format 処理を担います。
       *> EN: Helpers for WebSocket frame encoding/decoding and connection send/recv.
       *> EN: They provide the shared wire-format behavior used by both Gateway and Voice WS sessions.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FIRST-BYTE PIC 9(4) COMP-5.
       01 WS-SECOND-BYTE PIC 9(4) COMP-5.
       01 WS-HEADER-LENGTH PIC 9(4) COMP-5.
       01 WS-HIGH-BYTE PIC 9(4) COMP-5.
       01 WS-LOW-BYTE PIC 9(4) COMP-5.
       01 WS-IDX PIC 9(5) COMP-5.
       01 WS-MASK-IDX PIC 9(4) COMP-5.
       01 WS-MASK-CHAR PIC X.
       01 WS-DATA-CHAR PIC X.
       01 WS-DATA-BYTE PIC 9(4) COMP-5.
       01 WS-MASK-BYTE PIC 9(4) COMP-5.
       01 WS-MIXED-BYTE PIC 9(4) COMP-5.
       01 WS-BIT-VALUE PIC 9(4) COMP-5.
       01 WS-DATA-WORK PIC 9(4) COMP-5.
       01 WS-MASK-WORK PIC 9(4) COMP-5.
       01 WS-DATA-HAS-BIT PIC 9.
       01 WS-MASK-HAS-BIT PIC 9.

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-FRAME
           DC-WS-BUFFER
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-WS-BUFFER-DATA
           MOVE 0 TO DC-WS-BUFFER-LENGTH

           IF DC-WS-PAYLOAD-LENGTH < 0 OR DC-WS-PAYLOAD-LENGTH > 65535
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "WebSocket frame payload length is unsupported."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-WS-OPCODE TO WS-FIRST-BYTE
           IF DC-WS-FIN-FLAG = 1
               ADD 128 TO WS-FIRST-BYTE
           END-IF
           MOVE FUNCTION CHAR(WS-FIRST-BYTE + 1)
               TO DC-WS-BUFFER-DATA(1:1)

           IF DC-WS-PAYLOAD-LENGTH <= 125
               MOVE DC-WS-PAYLOAD-LENGTH TO WS-SECOND-BYTE
               IF DC-WS-MASK-FLAG = 1
                   ADD 128 TO WS-SECOND-BYTE
               END-IF
               MOVE FUNCTION CHAR(WS-SECOND-BYTE + 1)
                   TO DC-WS-BUFFER-DATA(2:1)
               MOVE 2 TO WS-HEADER-LENGTH
           ELSE
               MOVE 126 TO WS-SECOND-BYTE
               IF DC-WS-MASK-FLAG = 1
                   ADD 128 TO WS-SECOND-BYTE
               END-IF
               MOVE FUNCTION CHAR(WS-SECOND-BYTE + 1)
                   TO DC-WS-BUFFER-DATA(2:1)
               COMPUTE WS-HIGH-BYTE =
                   FUNCTION INTEGER(DC-WS-PAYLOAD-LENGTH / 256)
               COMPUTE WS-LOW-BYTE =
                   DC-WS-PAYLOAD-LENGTH - (WS-HIGH-BYTE * 256)
               MOVE FUNCTION CHAR(WS-HIGH-BYTE + 1)
                   TO DC-WS-BUFFER-DATA(3:1)
               MOVE FUNCTION CHAR(WS-LOW-BYTE + 1)
                   TO DC-WS-BUFFER-DATA(4:1)
               MOVE 4 TO WS-HEADER-LENGTH
           END-IF

           IF DC-WS-MASK-FLAG = 1
               IF WS-HEADER-LENGTH + 4 + DC-WS-PAYLOAD-LENGTH > 8192
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
                   MOVE "Encoded WebSocket frame would exceed the buffer."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
               MOVE DC-WS-MASK-KEY TO DC-WS-BUFFER-DATA(
                   WS-HEADER-LENGTH + 1:4)
               ADD 4 TO WS-HEADER-LENGTH
           ELSE
               IF WS-HEADER-LENGTH + DC-WS-PAYLOAD-LENGTH > 8192
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
                   MOVE "Encoded WebSocket frame would exceed the buffer."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

           IF DC-WS-PAYLOAD-LENGTH > 0
               IF DC-WS-MASK-FLAG = 1
                   PERFORM VARYING WS-IDX FROM 1 BY 1
                       UNTIL WS-IDX > DC-WS-PAYLOAD-LENGTH
                       COMPUTE WS-MASK-IDX =
                           FUNCTION MOD(WS-IDX - 1, 4) + 1
                       MOVE DC-WS-MASK-KEY(WS-MASK-IDX:1)
                           TO WS-MASK-CHAR
                       MOVE DC-WS-PAYLOAD(WS-IDX:1) TO WS-DATA-CHAR
                       COMPUTE WS-DATA-BYTE =
                           FUNCTION ORD(WS-DATA-CHAR) - 1
                       COMPUTE WS-MASK-BYTE =
                           FUNCTION ORD(WS-MASK-CHAR) - 1
                       PERFORM ENCODE-XOR-BYTES
                       MOVE FUNCTION CHAR(WS-MIXED-BYTE + 1)
                           TO DC-WS-BUFFER-DATA(
                               WS-HEADER-LENGTH + WS-IDX:1)
                   END-PERFORM
               ELSE
                   MOVE DC-WS-PAYLOAD(1:DC-WS-PAYLOAD-LENGTH)
                       TO DC-WS-BUFFER-DATA(
                           WS-HEADER-LENGTH + 1:DC-WS-PAYLOAD-LENGTH)
               END-IF
           END-IF
           COMPUTE DC-WS-BUFFER-LENGTH =
               WS-HEADER-LENGTH + DC-WS-PAYLOAD-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       ENCODE-XOR-BYTES.
           MOVE 0 TO WS-MIXED-BYTE
           MOVE WS-DATA-BYTE TO WS-DATA-WORK
           MOVE WS-MASK-BYTE TO WS-MASK-WORK
           MOVE 128 TO WS-BIT-VALUE
           PERFORM ENCODE-CHECK-CURRENT-BIT
           MOVE 64 TO WS-BIT-VALUE
           PERFORM ENCODE-CHECK-CURRENT-BIT
           MOVE 32 TO WS-BIT-VALUE
           PERFORM ENCODE-CHECK-CURRENT-BIT
           MOVE 16 TO WS-BIT-VALUE
           PERFORM ENCODE-CHECK-CURRENT-BIT
           MOVE 8 TO WS-BIT-VALUE
           PERFORM ENCODE-CHECK-CURRENT-BIT
           MOVE 4 TO WS-BIT-VALUE
           PERFORM ENCODE-CHECK-CURRENT-BIT
           MOVE 2 TO WS-BIT-VALUE
           PERFORM ENCODE-CHECK-CURRENT-BIT
           MOVE 1 TO WS-BIT-VALUE
           PERFORM ENCODE-CHECK-CURRENT-BIT.

       ENCODE-CHECK-CURRENT-BIT.
           IF WS-DATA-WORK >= WS-BIT-VALUE
               MOVE 1 TO WS-DATA-HAS-BIT
               SUBTRACT WS-BIT-VALUE FROM WS-DATA-WORK
           ELSE
               MOVE 0 TO WS-DATA-HAS-BIT
           END-IF
           IF WS-MASK-WORK >= WS-BIT-VALUE
               MOVE 1 TO WS-MASK-HAS-BIT
               SUBTRACT WS-BIT-VALUE FROM WS-MASK-WORK
           ELSE
               MOVE 0 TO WS-MASK-HAS-BIT
           END-IF
           IF WS-DATA-HAS-BIT NOT = WS-MASK-HAS-BIT
               ADD WS-BIT-VALUE TO WS-MIXED-BYTE
           END-IF.
       END PROGRAM DC-WS-ENCODE-FRAME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-DECODE-FRAME.
       *> JP: WebSocket frame の encode/decode と接続 send/recv の helper 群です。
       *> JP: Gateway/Voice 両方の WS session が共有する wire-format 処理を担います。
       *> EN: Helpers for WebSocket frame encoding/decoding and connection send/recv.
       *> EN: They provide the shared wire-format behavior used by both Gateway and Voice WS sessions.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FIRST-BYTE PIC 9(4) COMP-5.
       01 WS-SECOND-BYTE PIC 9(4) COMP-5.
       01 WS-PAYLOAD-LENGTH PIC 9(9) COMP-5.
       01 WS-MASK-FLAG PIC 9.
       01 WS-HEADER-LENGTH PIC 9(4) COMP-5.
       01 WS-PAYLOAD-START PIC 9(5) COMP-5.
       01 WS-IDX PIC 9(5) COMP-5.
       01 WS-MASK-IDX PIC 9(4) COMP-5.
       01 WS-MASK-CHAR PIC X.
       01 WS-DATA-CHAR PIC X.
       01 WS-DATA-BYTE PIC 9(4) COMP-5.
       01 WS-MASK-BYTE PIC 9(4) COMP-5.
       01 WS-MIXED-BYTE PIC 9(4) COMP-5.
       01 WS-BIT-VALUE PIC 9(4) COMP-5.
       01 WS-DATA-WORK PIC 9(4) COMP-5.
       01 WS-MASK-WORK PIC 9(4) COMP-5.
       01 WS-DATA-HAS-BIT PIC 9.
       01 WS-MASK-HAS-BIT PIC 9.
       01 WS-MASK-KEY.
          05 WS-MASK-KEY-BYTE OCCURS 4 TIMES PIC X.

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-BUFFER
           DC-WS-FRAME
           DC-RESULT.
       MAIN.
           INITIALIZE DC-WS-FRAME
           IF DC-WS-BUFFER-LENGTH < 2
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "WebSocket frame is shorter than the header."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           COMPUTE WS-FIRST-BYTE =
               FUNCTION ORD(DC-WS-BUFFER-DATA(1:1)) - 1
           COMPUTE WS-SECOND-BYTE =
               FUNCTION ORD(DC-WS-BUFFER-DATA(2:1)) - 1

           IF FUNCTION MOD(WS-FIRST-BYTE, 128) >= 64
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET_PROTOCOL" TO DC-ERROR-CODE
               MOVE "WebSocket reserved bits must be zero."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-FIRST-BYTE >= 128
               MOVE 1 TO DC-WS-FIN-FLAG
               SUBTRACT 128 FROM WS-FIRST-BYTE
           END-IF
           COMPUTE DC-WS-OPCODE = FUNCTION MOD(WS-FIRST-BYTE, 16)

           IF DC-WS-OPCODE NOT = 0 AND NOT = 1 AND NOT = 2
              AND NOT = 8 AND NOT = 9 AND NOT = 10
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET_PROTOCOL" TO DC-ERROR-CODE
               MOVE "WebSocket opcode is reserved or unsupported."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-SECOND-BYTE >= 128
               MOVE 1 TO WS-MASK-FLAG
               MOVE 1 TO DC-WS-MASK-FLAG
               SUBTRACT 128 FROM WS-SECOND-BYTE
           ELSE
               MOVE 0 TO WS-MASK-FLAG
               MOVE 0 TO DC-WS-MASK-FLAG
           END-IF

           EVALUATE WS-SECOND-BYTE
               WHEN 126
                   IF DC-WS-BUFFER-LENGTH < 4
                       MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                       MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
                       MOVE "Extended WebSocket length is truncated."
                           TO DC-ERROR-MESSAGE
                       GOBACK
                   END-IF
                   COMPUTE WS-PAYLOAD-LENGTH =
                       ((FUNCTION ORD(DC-WS-BUFFER-DATA(3:1)) - 1) * 256)
                       + (FUNCTION ORD(DC-WS-BUFFER-DATA(4:1)) - 1)
                   MOVE 4 TO WS-HEADER-LENGTH
               WHEN 127
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
                   MOVE "64-bit WebSocket lengths are not supported yet."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               WHEN OTHER
                   MOVE WS-SECOND-BYTE TO WS-PAYLOAD-LENGTH
                   MOVE 2 TO WS-HEADER-LENGTH
           END-EVALUATE

           IF DC-WS-OPCODE >= 8
              AND (DC-WS-FIN-FLAG NOT = 1 OR WS-PAYLOAD-LENGTH > 125)
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET_PROTOCOL" TO DC-ERROR-CODE
               MOVE "WebSocket control frames must be final and <= 125 bytes."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-MASK-FLAG = 1
               IF DC-WS-BUFFER-LENGTH < WS-HEADER-LENGTH + 4
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
                   MOVE "Masked WebSocket frame is missing its mask key."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
               MOVE DC-WS-BUFFER-DATA(WS-HEADER-LENGTH + 1:4)
                   TO WS-MASK-KEY
               MOVE DC-WS-BUFFER-DATA(WS-HEADER-LENGTH + 1:4)
                   TO DC-WS-MASK-KEY
               ADD 4 TO WS-HEADER-LENGTH
           END-IF

           COMPUTE WS-PAYLOAD-START = WS-HEADER-LENGTH + 1
           IF WS-PAYLOAD-START + WS-PAYLOAD-LENGTH - 1
               > DC-WS-BUFFER-LENGTH
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "WebSocket frame payload is truncated."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE WS-PAYLOAD-LENGTH TO DC-WS-PAYLOAD-LENGTH
           IF WS-PAYLOAD-LENGTH > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "Decoded WebSocket frame exceeds payload buffer."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-MASK-FLAG = 0
               IF WS-PAYLOAD-LENGTH > 0
                   MOVE DC-WS-BUFFER-DATA(WS-PAYLOAD-START:WS-PAYLOAD-LENGTH)
                       TO DC-WS-PAYLOAD(1:WS-PAYLOAD-LENGTH)
               END-IF
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-PAYLOAD-LENGTH
               COMPUTE WS-MASK-IDX = FUNCTION MOD(WS-IDX - 1, 4) + 1
               MOVE WS-MASK-KEY-BYTE(WS-MASK-IDX) TO WS-MASK-CHAR
               MOVE DC-WS-BUFFER-DATA(WS-PAYLOAD-START + WS-IDX - 1:1)
                   TO WS-DATA-CHAR
               COMPUTE WS-DATA-BYTE = FUNCTION ORD(WS-DATA-CHAR) - 1
               COMPUTE WS-MASK-BYTE = FUNCTION ORD(WS-MASK-CHAR) - 1
               PERFORM DECODE-XOR-BYTES
               MOVE FUNCTION CHAR(WS-MIXED-BYTE + 1)
                   TO DC-WS-PAYLOAD(WS-IDX:1)
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       DECODE-XOR-BYTES.
           MOVE 0 TO WS-MIXED-BYTE
           MOVE WS-DATA-BYTE TO WS-DATA-WORK
           MOVE WS-MASK-BYTE TO WS-MASK-WORK
           MOVE 128 TO WS-BIT-VALUE
           PERFORM DECODE-CHECK-CURRENT-BIT
           MOVE 64 TO WS-BIT-VALUE
           PERFORM DECODE-CHECK-CURRENT-BIT
           MOVE 32 TO WS-BIT-VALUE
           PERFORM DECODE-CHECK-CURRENT-BIT
           MOVE 16 TO WS-BIT-VALUE
           PERFORM DECODE-CHECK-CURRENT-BIT
           MOVE 8 TO WS-BIT-VALUE
           PERFORM DECODE-CHECK-CURRENT-BIT
           MOVE 4 TO WS-BIT-VALUE
           PERFORM DECODE-CHECK-CURRENT-BIT
           MOVE 2 TO WS-BIT-VALUE
           PERFORM DECODE-CHECK-CURRENT-BIT
           MOVE 1 TO WS-BIT-VALUE
           PERFORM DECODE-CHECK-CURRENT-BIT.

       DECODE-CHECK-CURRENT-BIT.
           IF WS-DATA-WORK >= WS-BIT-VALUE
               MOVE 1 TO WS-DATA-HAS-BIT
               SUBTRACT WS-BIT-VALUE FROM WS-DATA-WORK
           ELSE
               MOVE 0 TO WS-DATA-HAS-BIT
           END-IF
           IF WS-MASK-WORK >= WS-BIT-VALUE
               MOVE 1 TO WS-MASK-HAS-BIT
               SUBTRACT WS-BIT-VALUE FROM WS-MASK-WORK
           ELSE
               MOVE 0 TO WS-MASK-HAS-BIT
           END-IF
           IF WS-DATA-HAS-BIT NOT = WS-MASK-HAS-BIT
               ADD WS-BIT-VALUE TO WS-MIXED-BYTE
           END-IF.
       END PROGRAM DC-WS-DECODE-FRAME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-CONNECT.
       *> JP: WebSocket frame の encode/decode と接続 send/recv の helper 群です。
       *> JP: Gateway/Voice 両方の WS session が共有する wire-format 処理を担います。
       *> EN: Helpers for WebSocket frame encoding/decoding and connection send/recv.
       *> EN: They provide the shared wire-format behavior used by both Gateway and Voice WS sessions.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-HANDSHAKE-BUFFER.
          05 WS-HANDSHAKE-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 WS-HANDSHAKE-BUFFER-DATA PIC X(8192).
       01 WS-HTTP-RESPONSE.
          05 WS-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 WS-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 WS-HTTP-RAW-HEADERS PIC X(4096).
          05 WS-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 WS-HTTP-RESPONSE-BODY PIC X(8192).
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-ACCEPT PIC X(64).
       01 WS-TLS-HANDLE PIC 9(10) COMP-5.
       01 WS-WS-PORT PIC 9(5) COMP-5 VALUE 443.
       01 WS-COPY-LEN PIC 9(9) COMP-5.
       01 WS-TRANSPORT-BUFFER.
          05 WS-TRANSPORT-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 WS-TRANSPORT-BUFFER-DATA PIC X(16384).
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-ERROR-CODE PIC X(64).
          05 WS-CLEANUP-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-REQUEST
           DC-WS-SESSION
           DC-RESULT.
       MAIN.
           INITIALIZE DC-WS-SESSION
           MOVE 0 TO WS-TLS-HANDLE
           MOVE 443 TO WS-WS-PORT

           IF FUNCTION TRIM(DC-WS-HOST) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "WebSocket host is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-WS-PATH) = SPACES
               MOVE "/" TO DC-WS-PATH
           END-IF

           IF DC-WS-REQUEST-PORT > 0
               MOVE DC-WS-REQUEST-PORT TO WS-WS-PORT
           END-IF

           CALL "DC-WS-BUILD-HANDSHAKE-REQUEST"
               USING DC-WS-REQUEST
                     WS-HANDSHAKE-BUFFER
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE DC-WS-HOST TO DC-WS-SESSION-HOST
           MOVE DC-WS-PATH TO DC-WS-SESSION-PATH
           MOVE DC-WS-SEC-KEY TO DC-WS-SESSION-SEC-KEY
           MOVE WS-WS-PORT TO DC-WS-SESSION-PORT
           MOVE WS-HANDSHAKE-BUFFER-LENGTH
               TO DC-WS-HANDSHAKE-REQUEST-LENGTH
           MOVE WS-HANDSHAKE-BUFFER-DATA TO DC-WS-HANDSHAKE-REQUEST

           CALL "DC-WS-BUILD-ACCEPT"
               USING DC-WS-SEC-KEY(1:24)
                     WS-ACCEPT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF DC-WS-REQUEST-LIVE-FLAG = 1
               CALL "DC-TLS-CONNECT"
                   USING DC-WS-HOST
                         WS-WS-PORT
                         WS-TLS-HANDLE
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF

               MOVE 0 TO WS-TRANSPORT-BUFFER-LENGTH
               MOVE SPACES TO WS-TRANSPORT-BUFFER-DATA
               MOVE WS-HANDSHAKE-BUFFER-LENGTH
                   TO WS-TRANSPORT-BUFFER-LENGTH
               MOVE WS-HANDSHAKE-BUFFER-DATA TO WS-TRANSPORT-BUFFER-DATA
               CALL "DC-TLS-SEND"
                   USING WS-TLS-HANDLE
                         WS-TRANSPORT-BUFFER
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   CALL "DC-TLS-CLOSE"
                       USING WS-TLS-HANDLE
                             WS-CLEANUP-RESULT
                   GOBACK
               END-IF

               CALL "DC-TLS-RECV"
                   USING WS-TLS-HANDLE
                         WS-TRANSPORT-BUFFER
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   CALL "DC-TLS-CLOSE"
                       USING WS-TLS-HANDLE
                             WS-CLEANUP-RESULT
                   GOBACK
               END-IF

               MOVE SPACES TO WS-RAW-RESPONSE
               MOVE WS-TRANSPORT-BUFFER-LENGTH TO WS-COPY-LEN
               IF WS-COPY-LEN > 8192
                   MOVE 8192 TO WS-COPY-LEN
               END-IF
               IF WS-COPY-LEN > 0
                   MOVE WS-TRANSPORT-BUFFER-DATA(1:WS-COPY-LEN)
                       TO WS-RAW-RESPONSE(1:WS-COPY-LEN)
               END-IF

               CALL "DC-HTTP-PARSE-RESPONSE"
                   USING WS-RAW-RESPONSE
                         WS-HTTP-RESPONSE
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   CALL "DC-TLS-CLOSE"
                       USING WS-TLS-HANDLE
                             WS-CLEANUP-RESULT
                   GOBACK
               END-IF

               CALL "DC-WS-VALIDATE-HS-RESPONSE"
                   USING DC-WS-REQUEST
                         WS-HTTP-RESPONSE
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   CALL "DC-TLS-CLOSE"
                       USING WS-TLS-HANDLE
                             WS-CLEANUP-RESULT
                   GOBACK
               END-IF

               MOVE WS-TLS-HANDLE TO DC-WS-HANDLE
               MOVE 1 TO DC-WS-OPEN-FLAG
               MOVE 0 TO DC-WS-LOOPBACK-FLAG
               MOVE 1 TO DC-WS-SESSION-LIVE-FLAG
               MOVE WS-COPY-LEN TO DC-WS-HANDSHAKE-RESPONSE-LENGTH
               MOVE WS-RAW-RESPONSE TO DC-WS-HANDSHAKE-RESPONSE
               IF WS-HTTP-RESPONSE-BODY-LENGTH > 0
                   MOVE WS-HTTP-RESPONSE-BODY-LENGTH
                       TO DC-WS-INBOUND-BUFFER-LENGTH
                   MOVE WS-HTTP-RESPONSE-BODY
                       TO DC-WS-INBOUND-BUFFER
               END-IF
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

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

           CALL "DC-HTTP-PARSE-RESPONSE"
               USING WS-RAW-RESPONSE
                     WS-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-WS-VALIDATE-HS-RESPONSE"
               USING DC-WS-REQUEST
                     WS-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE 1 TO DC-WS-HANDLE
           MOVE 1 TO DC-WS-OPEN-FLAG
           MOVE 1 TO DC-WS-LOOPBACK-FLAG
           MOVE 0 TO DC-WS-SESSION-LIVE-FLAG
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-WS-HANDSHAKE-RESPONSE-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-WS-HANDSHAKE-RESPONSE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-WS-CONNECT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-SEND-TEXT.
       *> JP: WebSocket frame の encode/decode と接続 send/recv の helper 群です。
       *> JP: Gateway/Voice 両方の WS session が共有する wire-format 処理を担います。
       *> EN: Helpers for WebSocket frame encoding/decoding and connection send/recv.
       *> EN: They provide the shared wire-format behavior used by both Gateway and Voice WS sessions.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TEXT-LENGTH PIC 9(9) COMP-5.
       01 WS-FRAME-BUILD.
          05 WS-FRAME-FIN-FLAG PIC 9.
          05 WS-FRAME-OPCODE PIC 9(2) COMP-5.
          05 WS-FRAME-MASK-FLAG PIC 9.
          05 WS-FRAME-MASK-KEY PIC X(4).
          05 WS-FRAME-PAYLOAD-LENGTH PIC 9(9) COMP-5.
          05 WS-FRAME-PAYLOAD PIC X(8192).
       01 WS-FRAME-BUFFER.
          05 WS-FRAME-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 WS-FRAME-BUFFER-DATA PIC X(8192).
       01 WS-MASK-SEED PIC X(4) VALUE "mask".
       01 WS-TRANSPORT-BUFFER.
          05 WS-TRANSPORT-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 WS-TRANSPORT-BUFFER-DATA PIC X(16384).

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       01 DC-WS-TEXT-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-SESSION
           DC-WS-TEXT-PAYLOAD
           DC-RESULT.
       MAIN.
           IF DC-WS-OPEN-FLAG NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "WebSocket session is not open."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-WS-SESSION-LIVE-FLAG NOT = 1
              AND DC-WS-OUTBOUND-BUFFER-LENGTH > 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET_QUEUE_FULL" TO DC-ERROR-CODE
               MOVE "WebSocket outbound buffer is busy."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE FUNCTION LENGTH(FUNCTION TRIM(DC-WS-TEXT-PAYLOAD TRAILING))
               TO WS-TEXT-LENGTH

           INITIALIZE WS-FRAME-BUILD
           MOVE 1 TO WS-FRAME-FIN-FLAG
           MOVE 1 TO WS-FRAME-OPCODE
           MOVE WS-TEXT-LENGTH TO WS-FRAME-PAYLOAD-LENGTH
           IF DC-WS-SESSION-LIVE-FLAG = 1
               MOVE 1 TO WS-FRAME-MASK-FLAG
               IF DC-WS-SESSION-SEC-KEY(1:4) NOT = SPACES
                   MOVE DC-WS-SESSION-SEC-KEY(1:4) TO WS-MASK-SEED
               END-IF
               MOVE WS-MASK-SEED TO WS-FRAME-MASK-KEY
           END-IF
           IF WS-TEXT-LENGTH > 0
               MOVE DC-WS-TEXT-PAYLOAD(1:WS-TEXT-LENGTH)
                   TO WS-FRAME-PAYLOAD(1:WS-TEXT-LENGTH)
           END-IF

           CALL "DC-WS-ENCODE-FRAME"
               USING WS-FRAME-BUILD
                     WS-FRAME-BUFFER
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF DC-WS-SESSION-LIVE-FLAG = 1
               MOVE WS-FRAME-BUFFER-LENGTH TO WS-TRANSPORT-BUFFER-LENGTH
               MOVE WS-FRAME-BUFFER-DATA TO WS-TRANSPORT-BUFFER-DATA
               CALL "DC-TLS-SEND"
                   USING DC-WS-HANDLE
                         WS-TRANSPORT-BUFFER
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               MOVE 0 TO DC-WS-OUTBOUND-BUFFER-LENGTH
               MOVE SPACES TO DC-WS-OUTBOUND-BUFFER
           ELSE
               MOVE WS-FRAME-BUFFER-LENGTH TO DC-WS-OUTBOUND-BUFFER-LENGTH
               MOVE WS-FRAME-BUFFER-DATA TO DC-WS-OUTBOUND-BUFFER
           END-IF
           MOVE 1 TO DC-WS-LAST-OPCODE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-WS-SEND-TEXT.


       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-RECV.
       *> JP: transport chunk を蓄積し、1 個の完全な WebSocket message を返します。
       *> JP: 複数 frame、分割受信、continuation、途中の control frame を扱います。
       *> EN: Accumulates transport chunks and returns one complete WebSocket message.
       *> EN: Handles coalesced frames, partial reads, continuation, and control frames.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RAW-FRAME.
          05 WS-RAW-LENGTH PIC 9(9) COMP-5.
          05 WS-RAW-DATA PIC X(8192).
       01 WS-TRANSPORT-BUFFER.
          05 WS-TRANSPORT-LENGTH PIC 9(9) COMP-5.
          05 WS-TRANSPORT-DATA PIC X(16384).
       01 WS-REMAINDER PIC X(8192).
       01 WS-FIRST-BYTE PIC 9(4) COMP-5.
       01 WS-SECOND-BYTE PIC 9(4) COMP-5.
       01 WS-LENGTH-CODE PIC 9(4) COMP-5.
       01 WS-HEADER-LENGTH PIC 9(4) COMP-5.
       01 WS-FRAME-LENGTH PIC 9(9) COMP-5.
       01 WS-PAYLOAD-LENGTH PIC 9(9) COMP-5.
       01 WS-REMAINDER-LENGTH PIC 9(9) COMP-5.
       01 WS-COPY-LENGTH PIC 9(9) COMP-5.
       01 WS-NEED-MORE PIC 9.
       01 WS-DONE PIC 9.
       01 WS-FRAGMENT-ACTIVE PIC 9.
       01 WS-FRAGMENT-OPCODE PIC 9(2) COMP-5.
       01 WS-FRAGMENT-LENGTH PIC 9(9) COMP-5.
       01 WS-FRAGMENT-PAYLOAD PIC X(8192).
       01 WS-DECODED-FRAME.
          05 WS-DECODED-FIN PIC 9.
          05 WS-DECODED-OPCODE PIC 9(2) COMP-5.
          05 WS-DECODED-MASK PIC 9.
          05 WS-DECODED-MASK-KEY PIC X(4).
          05 WS-DECODED-LENGTH PIC 9(9) COMP-5.
          05 WS-DECODED-PAYLOAD PIC X(8192).
       01 WS-CONTROL-FRAME.
          05 WS-CONTROL-FIN PIC 9.
          05 WS-CONTROL-OPCODE PIC 9(2) COMP-5.
          05 WS-CONTROL-MASK PIC 9.
          05 WS-CONTROL-MASK-KEY PIC X(4).
          05 WS-CONTROL-LENGTH PIC 9(9) COMP-5.
          05 WS-CONTROL-PAYLOAD PIC X(8192).
       01 WS-CONTROL-BUFFER.
          05 WS-CONTROL-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 WS-CONTROL-BUFFER-DATA PIC X(8192).
       01 WS-MASK-SEED PIC X(4) VALUE "mask".
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-CODE PIC X(64).
          05 WS-CLEANUP-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-SESSION DC-WS-FRAME DC-RESULT.
       MAIN.
           INITIALIZE DC-WS-FRAME
           MOVE 0 TO WS-DONE WS-FRAGMENT-ACTIVE WS-FRAGMENT-LENGTH
           MOVE SPACES TO WS-FRAGMENT-PAYLOAD

           IF DC-WS-OPEN-FLAG NOT = 1
               PERFORM SESSION-CLOSED-ERROR
               GOBACK
           END-IF

           PERFORM UNTIL WS-DONE = 1
               PERFORM READ-COMPLETE-FRAME
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               INITIALIZE WS-DECODED-FRAME
               CALL "DC-WS-DECODE-FRAME"
                   USING WS-RAW-FRAME WS-DECODED-FRAME DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               PERFORM APPLY-DECODED-FRAME
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-PERFORM

           MOVE DC-WS-OPCODE TO DC-WS-LAST-OPCODE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       READ-COMPLETE-FRAME.
           MOVE 1 TO WS-NEED-MORE
           PERFORM UNTIL WS-NEED-MORE = 0
               IF DC-WS-INBOUND-BUFFER-LENGTH < 2
                   PERFORM APPEND-TRANSPORT-CHUNK
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       EXIT PARAGRAPH
                   END-IF
               ELSE
                   COMPUTE WS-FIRST-BYTE = FUNCTION ORD(
                       DC-WS-INBOUND-BUFFER(1:1)) - 1
                   COMPUTE WS-SECOND-BYTE = FUNCTION ORD(
                       DC-WS-INBOUND-BUFFER(2:1)) - 1
                   COMPUTE WS-LENGTH-CODE =
                       FUNCTION MOD(WS-SECOND-BYTE, 128)
                   EVALUATE WS-LENGTH-CODE
                       WHEN 126
                           IF DC-WS-INBOUND-BUFFER-LENGTH < 4
                               PERFORM APPEND-TRANSPORT-CHUNK
                               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                                   EXIT PARAGRAPH
                               END-IF
                           ELSE
                               COMPUTE WS-PAYLOAD-LENGTH =
                                   ((FUNCTION ORD(
                                       DC-WS-INBOUND-BUFFER(3:1)) - 1) * 256)
                                   + (FUNCTION ORD(
                                       DC-WS-INBOUND-BUFFER(4:1)) - 1)
                               MOVE 4 TO WS-HEADER-LENGTH
                               PERFORM CHECK-FRAME-COMPLETE
                           END-IF
                       WHEN 127
                           PERFORM FRAME-SIZE-ERROR
                           EXIT PARAGRAPH
                       WHEN OTHER
                           MOVE WS-LENGTH-CODE TO WS-PAYLOAD-LENGTH
                           MOVE 2 TO WS-HEADER-LENGTH
                           PERFORM CHECK-FRAME-COMPLETE
                   END-EVALUATE
               END-IF
           END-PERFORM

           MOVE SPACES TO WS-RAW-DATA WS-REMAINDER
           MOVE WS-FRAME-LENGTH TO WS-RAW-LENGTH
           MOVE DC-WS-INBOUND-BUFFER(1:WS-FRAME-LENGTH)
               TO WS-RAW-DATA(1:WS-FRAME-LENGTH)
           COMPUTE WS-REMAINDER-LENGTH =
               DC-WS-INBOUND-BUFFER-LENGTH - WS-FRAME-LENGTH
           IF WS-REMAINDER-LENGTH > 0
               MOVE DC-WS-INBOUND-BUFFER(
                   WS-FRAME-LENGTH + 1:WS-REMAINDER-LENGTH)
                   TO WS-REMAINDER(1:WS-REMAINDER-LENGTH)
           END-IF
           MOVE SPACES TO DC-WS-INBOUND-BUFFER
           MOVE WS-REMAINDER-LENGTH TO DC-WS-INBOUND-BUFFER-LENGTH
           IF WS-REMAINDER-LENGTH > 0
               MOVE WS-REMAINDER(1:WS-REMAINDER-LENGTH)
                   TO DC-WS-INBOUND-BUFFER(1:WS-REMAINDER-LENGTH)
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       CHECK-FRAME-COMPLETE.
           IF WS-SECOND-BYTE >= 128
               ADD 4 TO WS-HEADER-LENGTH
           END-IF
           COMPUTE WS-FRAME-LENGTH =
               WS-HEADER-LENGTH + WS-PAYLOAD-LENGTH
           IF WS-FRAME-LENGTH > 8192
               PERFORM FRAME-SIZE-ERROR
               EXIT PARAGRAPH
           END-IF
           IF DC-WS-INBOUND-BUFFER-LENGTH < WS-FRAME-LENGTH
               PERFORM APPEND-TRANSPORT-CHUNK
           ELSE
               MOVE 0 TO WS-NEED-MORE
               CALL "DC-RESULT-OK" USING DC-RESULT
           END-IF.

       APPEND-TRANSPORT-CHUNK.
           IF DC-WS-SESSION-LIVE-FLAG = 1
               INITIALIZE WS-TRANSPORT-BUFFER
               CALL "DC-TLS-RECV"
                   USING DC-WS-HANDLE WS-TRANSPORT-BUFFER DC-RESULT
               IF DC-STATUS-CODE = DC-STATUS-EOF
                   PERFORM CLOSE-TRANSPORT
                   EXIT PARAGRAPH
               END-IF
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   EXIT PARAGRAPH
               END-IF
               IF DC-WS-INBOUND-BUFFER-LENGTH + WS-TRANSPORT-LENGTH
                   > 8192
                   PERFORM FRAME-SIZE-ERROR
                   EXIT PARAGRAPH
               END-IF
               IF WS-TRANSPORT-LENGTH > 0
                   MOVE WS-TRANSPORT-DATA(1:WS-TRANSPORT-LENGTH)
                       TO DC-WS-INBOUND-BUFFER(
                           DC-WS-INBOUND-BUFFER-LENGTH + 1:
                           WS-TRANSPORT-LENGTH)
                   ADD WS-TRANSPORT-LENGTH
                       TO DC-WS-INBOUND-BUFFER-LENGTH
               END-IF
               CALL "DC-RESULT-OK" USING DC-RESULT
               EXIT PARAGRAPH
           END-IF

           IF DC-WS-LOOPBACK-FLAG = 1
              AND DC-WS-OUTBOUND-BUFFER-LENGTH > 0
               IF DC-WS-INBOUND-BUFFER-LENGTH
                   + DC-WS-OUTBOUND-BUFFER-LENGTH > 8192
                   PERFORM FRAME-SIZE-ERROR
                   EXIT PARAGRAPH
               END-IF
               MOVE DC-WS-OUTBOUND-BUFFER(
                   1:DC-WS-OUTBOUND-BUFFER-LENGTH)
                   TO DC-WS-INBOUND-BUFFER(
                       DC-WS-INBOUND-BUFFER-LENGTH + 1:
                       DC-WS-OUTBOUND-BUFFER-LENGTH)
               ADD DC-WS-OUTBOUND-BUFFER-LENGTH
                   TO DC-WS-INBOUND-BUFFER-LENGTH
               MOVE 0 TO DC-WS-OUTBOUND-BUFFER-LENGTH
               MOVE SPACES TO DC-WS-OUTBOUND-BUFFER
               CALL "DC-RESULT-OK" USING DC-RESULT
               EXIT PARAGRAPH
           END-IF

           IF DC-WS-INBOUND-BUFFER-LENGTH = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "No inbound WebSocket frame is available."
                   TO DC-ERROR-MESSAGE
           ELSE
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET_INCOMPLETE" TO DC-ERROR-CODE
               MOVE "WebSocket frame is incomplete."
                   TO DC-ERROR-MESSAGE
           END-IF.

       APPLY-DECODED-FRAME.
           EVALUATE WS-DECODED-OPCODE
               WHEN 8
                   MOVE WS-DECODED-FRAME TO DC-WS-FRAME
                   PERFORM CLOSE-TRANSPORT
                   MOVE 1 TO WS-DONE
                   CALL "DC-RESULT-OK" USING DC-RESULT
               WHEN 9
                   PERFORM SEND-PONG
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       EXIT PARAGRAPH
                   END-IF
                   IF WS-FRAGMENT-ACTIVE = 0
                       MOVE WS-DECODED-FRAME TO DC-WS-FRAME
                       MOVE 1 TO WS-DONE
                   END-IF
               WHEN 10
                   IF WS-FRAGMENT-ACTIVE = 0
                       MOVE WS-DECODED-FRAME TO DC-WS-FRAME
                       MOVE 1 TO WS-DONE
                   END-IF
                   CALL "DC-RESULT-OK" USING DC-RESULT
               WHEN 0
                   IF WS-FRAGMENT-ACTIVE NOT = 1
                       PERFORM FRAGMENT-PROTOCOL-ERROR
                       EXIT PARAGRAPH
                   END-IF
                   PERFORM APPEND-FRAGMENT-PAYLOAD
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       EXIT PARAGRAPH
                   END-IF
                   IF WS-DECODED-FIN = 1
                       PERFORM COMPLETE-FRAGMENT
                   END-IF
               WHEN 1
                   PERFORM START-OR-COMPLETE-DATA
               WHEN 2
                   PERFORM START-OR-COMPLETE-DATA
           END-EVALUATE.

       START-OR-COMPLETE-DATA.
           IF WS-FRAGMENT-ACTIVE = 1
               PERFORM FRAGMENT-PROTOCOL-ERROR
               EXIT PARAGRAPH
           END-IF
           IF WS-DECODED-FIN = 1
               MOVE WS-DECODED-FRAME TO DC-WS-FRAME
               MOVE 1 TO WS-DONE
               CALL "DC-RESULT-OK" USING DC-RESULT
           ELSE
               MOVE 1 TO WS-FRAGMENT-ACTIVE
               MOVE WS-DECODED-OPCODE TO WS-FRAGMENT-OPCODE
               MOVE 0 TO WS-FRAGMENT-LENGTH
               MOVE SPACES TO WS-FRAGMENT-PAYLOAD
               PERFORM APPEND-FRAGMENT-PAYLOAD
           END-IF.

       APPEND-FRAGMENT-PAYLOAD.
           IF WS-FRAGMENT-LENGTH + WS-DECODED-LENGTH > 8192
               PERFORM FRAME-SIZE-ERROR
               EXIT PARAGRAPH
           END-IF
           IF WS-DECODED-LENGTH > 0
               MOVE WS-DECODED-PAYLOAD(1:WS-DECODED-LENGTH)
                   TO WS-FRAGMENT-PAYLOAD(
                       WS-FRAGMENT-LENGTH + 1:WS-DECODED-LENGTH)
               ADD WS-DECODED-LENGTH TO WS-FRAGMENT-LENGTH
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       COMPLETE-FRAGMENT.
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE WS-FRAGMENT-OPCODE TO DC-WS-OPCODE
           MOVE WS-FRAGMENT-LENGTH TO DC-WS-PAYLOAD-LENGTH
           IF WS-FRAGMENT-LENGTH > 0
               MOVE WS-FRAGMENT-PAYLOAD(1:WS-FRAGMENT-LENGTH)
                   TO DC-WS-PAYLOAD(1:WS-FRAGMENT-LENGTH)
           END-IF
           MOVE 0 TO WS-FRAGMENT-ACTIVE
           MOVE 1 TO WS-DONE
           CALL "DC-RESULT-OK" USING DC-RESULT.

       SEND-PONG.
           INITIALIZE WS-CONTROL-FRAME WS-CONTROL-BUFFER
           MOVE 1 TO WS-CONTROL-FIN
           MOVE 10 TO WS-CONTROL-OPCODE
           MOVE WS-DECODED-LENGTH TO WS-CONTROL-LENGTH
           IF WS-DECODED-LENGTH > 0
               MOVE WS-DECODED-PAYLOAD(1:WS-DECODED-LENGTH)
                   TO WS-CONTROL-PAYLOAD(1:WS-DECODED-LENGTH)
           END-IF
           IF DC-WS-SESSION-LIVE-FLAG = 1
               MOVE 1 TO WS-CONTROL-MASK
               IF DC-WS-SESSION-SEC-KEY(1:4) NOT = SPACES
                   MOVE DC-WS-SESSION-SEC-KEY(1:4) TO WS-MASK-SEED
               END-IF
               MOVE WS-MASK-SEED TO WS-CONTROL-MASK-KEY
           END-IF
           CALL "DC-WS-ENCODE-FRAME"
               USING WS-CONTROL-FRAME WS-CONTROL-BUFFER DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           IF DC-WS-SESSION-LIVE-FLAG = 1
               MOVE WS-CONTROL-BUFFER-LENGTH TO WS-TRANSPORT-LENGTH
               MOVE WS-CONTROL-BUFFER-DATA TO WS-TRANSPORT-DATA
               CALL "DC-TLS-SEND"
                   USING DC-WS-HANDLE WS-TRANSPORT-BUFFER DC-RESULT
           ELSE
               IF DC-WS-OUTBOUND-BUFFER-LENGTH = 0
                   MOVE WS-CONTROL-BUFFER-LENGTH
                       TO DC-WS-OUTBOUND-BUFFER-LENGTH
                   MOVE WS-CONTROL-BUFFER-DATA
                       TO DC-WS-OUTBOUND-BUFFER
                   CALL "DC-RESULT-OK" USING DC-RESULT
               ELSE
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_WEBSOCKET_QUEUE_FULL" TO DC-ERROR-CODE
                   MOVE "WebSocket control-frame queue is busy."
                       TO DC-ERROR-MESSAGE
               END-IF
           END-IF.

       CLOSE-TRANSPORT.
           IF DC-WS-SESSION-LIVE-FLAG = 1
               CALL "DC-TLS-CLOSE"
                   USING DC-WS-HANDLE WS-CLEANUP-RESULT
           END-IF
           MOVE 0 TO DC-WS-OPEN-FLAG
           MOVE 0 TO DC-WS-LOOPBACK-FLAG
           MOVE 0 TO DC-WS-SESSION-LIVE-FLAG.
       SESSION-CLOSED-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_CLOSED" TO DC-ERROR-CODE
           MOVE "WebSocket session is not open." TO DC-ERROR-MESSAGE.
       FRAME-SIZE-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_SIZE" TO DC-ERROR-CODE
           MOVE "WebSocket frame or message exceeds 8192 bytes."
               TO DC-ERROR-MESSAGE.
       FRAGMENT-PROTOCOL-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_PROTOCOL" TO DC-ERROR-CODE
           MOVE "WebSocket continuation sequence is invalid."
               TO DC-ERROR-MESSAGE.
       END PROGRAM DC-WS-RECV.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-CLOSE.
       *> JP: normal closure frame を送信し、transport と session を閉じます。
       *> EN: Sends a normal-closure frame and closes transport and session state.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CLOSE-FRAME.
          05 WS-CLOSE-FIN PIC 9 VALUE 1.
          05 WS-CLOSE-OPCODE PIC 9(2) COMP-5 VALUE 8.
          05 WS-CLOSE-MASK PIC 9.
          05 WS-CLOSE-MASK-KEY PIC X(4).
          05 WS-CLOSE-LENGTH PIC 9(9) COMP-5 VALUE 2.
          05 WS-CLOSE-PAYLOAD PIC X(8192).
       01 WS-CLOSE-BUFFER.
          05 WS-CLOSE-BUFFER-LENGTH PIC 9(9) COMP-5.
          05 WS-CLOSE-BUFFER-DATA PIC X(8192).
       01 WS-TRANSPORT-BUFFER.
          05 WS-TRANSPORT-LENGTH PIC 9(9) COMP-5.
          05 WS-TRANSPORT-DATA PIC X(16384).
       01 WS-CLEANUP-RESULT.
          05 WS-CLEANUP-STATUS PIC S9(9) COMP-5.
          05 WS-CLEANUP-CODE PIC X(64).
          05 WS-CLEANUP-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-WS-SESSION DC-RESULT.
       MAIN.
           IF DC-WS-OPEN-FLAG NOT = 1
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF
           MOVE FUNCTION CHAR(4) TO WS-CLOSE-PAYLOAD(1:1)
           MOVE FUNCTION CHAR(233) TO WS-CLOSE-PAYLOAD(2:1)
           IF DC-WS-SESSION-LIVE-FLAG = 1
               MOVE 1 TO WS-CLOSE-MASK
               IF DC-WS-SESSION-SEC-KEY(1:4) = SPACES
                   MOVE "mask" TO WS-CLOSE-MASK-KEY
               ELSE
                   MOVE DC-WS-SESSION-SEC-KEY(1:4) TO WS-CLOSE-MASK-KEY
               END-IF
           END-IF
           CALL "DC-WS-ENCODE-FRAME"
               USING WS-CLOSE-FRAME WS-CLOSE-BUFFER DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF DC-WS-SESSION-LIVE-FLAG = 1
               MOVE WS-CLOSE-BUFFER-LENGTH TO WS-TRANSPORT-LENGTH
               MOVE WS-CLOSE-BUFFER-DATA TO WS-TRANSPORT-DATA
               CALL "DC-TLS-SEND"
                   USING DC-WS-HANDLE WS-TRANSPORT-BUFFER DC-RESULT
               CALL "DC-TLS-CLOSE"
                   USING DC-WS-HANDLE WS-CLEANUP-RESULT
           ELSE
               MOVE WS-CLOSE-BUFFER-LENGTH
                   TO DC-WS-OUTBOUND-BUFFER-LENGTH
               MOVE WS-CLOSE-BUFFER-DATA TO DC-WS-OUTBOUND-BUFFER
           END-IF
           MOVE 0 TO DC-WS-OPEN-FLAG DC-WS-LOOPBACK-FLAG
               DC-WS-SESSION-LIVE-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-WS-CLOSE.
