       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-ENCODE-FRAME.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FIRST-BYTE PIC 9(4) COMP-5.
       01 WS-SECOND-BYTE PIC 9(4) COMP-5.
       01 WS-HEADER-LENGTH PIC 9(4) COMP-5.
       01 WS-HIGH-BYTE PIC 9(4) COMP-5.
       01 WS-LOW-BYTE PIC 9(4) COMP-5.

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
               MOVE FUNCTION CHAR(WS-SECOND-BYTE + 1)
                   TO DC-WS-BUFFER-DATA(2:1)
               MOVE 2 TO WS-HEADER-LENGTH
           ELSE
               MOVE FUNCTION CHAR(127)
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

           IF WS-HEADER-LENGTH + DC-WS-PAYLOAD-LENGTH > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "Encoded WebSocket frame would exceed the buffer."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-WS-PAYLOAD-LENGTH > 0
               MOVE DC-WS-PAYLOAD(1:DC-WS-PAYLOAD-LENGTH)
                   TO DC-WS-BUFFER-DATA(
                       WS-HEADER-LENGTH + 1:DC-WS-PAYLOAD-LENGTH)
           END-IF
           COMPUTE DC-WS-BUFFER-LENGTH =
               WS-HEADER-LENGTH + DC-WS-PAYLOAD-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-WS-ENCODE-FRAME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-DECODE-FRAME.

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

           IF WS-FIRST-BYTE >= 128
               MOVE 1 TO DC-WS-FIN-FLAG
               SUBTRACT 128 FROM WS-FIRST-BYTE
           END-IF
           COMPUTE DC-WS-OPCODE = FUNCTION MOD(WS-FIRST-BYTE, 16)

           IF WS-SECOND-BYTE >= 128
               MOVE 1 TO WS-MASK-FLAG
               SUBTRACT 128 FROM WS-SECOND-BYTE
           ELSE
               MOVE 0 TO WS-MASK-FLAG
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
               PERFORM XOR-BYTES
               MOVE FUNCTION CHAR(WS-MIXED-BYTE + 1)
                   TO DC-WS-PAYLOAD(WS-IDX:1)
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       XOR-BYTES.
           MOVE 0 TO WS-MIXED-BYTE
           MOVE WS-DATA-BYTE TO WS-DATA-WORK
           MOVE WS-MASK-BYTE TO WS-MASK-WORK
           MOVE 128 TO WS-BIT-VALUE
           PERFORM CHECK-CURRENT-BIT
           MOVE 64 TO WS-BIT-VALUE
           PERFORM CHECK-CURRENT-BIT
           MOVE 32 TO WS-BIT-VALUE
           PERFORM CHECK-CURRENT-BIT
           MOVE 16 TO WS-BIT-VALUE
           PERFORM CHECK-CURRENT-BIT
           MOVE 8 TO WS-BIT-VALUE
           PERFORM CHECK-CURRENT-BIT
           MOVE 4 TO WS-BIT-VALUE
           PERFORM CHECK-CURRENT-BIT
           MOVE 2 TO WS-BIT-VALUE
           PERFORM CHECK-CURRENT-BIT
           MOVE 1 TO WS-BIT-VALUE
           PERFORM CHECK-CURRENT-BIT.

       CHECK-CURRENT-BIT.
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

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-REQUEST
           DC-WS-SESSION
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-WS-OPEN-FLAG
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "WebSocket transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-WS-CONNECT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-SEND-TEXT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       01 DC-WS-TEXT-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-SESSION
           DC-WS-TEXT-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "WebSocket send is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-WS-SEND-TEXT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-RECV.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-SESSION
           DC-WS-FRAME
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "WebSocket receive is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-WS-RECV.
