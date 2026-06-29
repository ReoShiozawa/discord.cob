       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-GENERATE-KEY.

	       DATA DIVISION.
	       WORKING-STORAGE SECTION.
	       01 WS-DATE-TIME PIC X(21).
	       01 WS-RAW-KEY PIC X(16).
	       01 WS-RAW-KEY-LEN PIC 9(4) COMP-5 VALUE 16.
	       01 WS-IDX PIC 9(4) COMP-5.
	       01 WS-SRC-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-WS-SEC-KEY-OUT PIC X(64).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-WS-SEC-KEY-OUT DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-WS-SEC-KEY-OUT
           MOVE FUNCTION CURRENT-DATE TO WS-DATE-TIME
           MOVE ALL "0" TO WS-RAW-KEY
           MOVE 1 TO WS-SRC-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 16
               PERFORM UNTIL WS-SRC-IDX > 21
                   OR WS-DATE-TIME(WS-SRC-IDX:1) >= "0"
                   AND WS-DATE-TIME(WS-SRC-IDX:1) <= "9"
                   ADD 1 TO WS-SRC-IDX
               END-PERFORM
               IF WS-SRC-IDX > 21
                   MOVE "0" TO WS-RAW-KEY(WS-IDX:1)
               ELSE
                   MOVE WS-DATE-TIME(WS-SRC-IDX:1)
                       TO WS-RAW-KEY(WS-IDX:1)
                   ADD 1 TO WS-SRC-IDX
               END-IF
           END-PERFORM
	           CALL "DC-BASE64-ENCODE"
	               USING WS-RAW-KEY
	                     WS-RAW-KEY-LEN
	                     DC-WS-SEC-KEY-OUT
	                     DC-RESULT
           GOBACK.
       END PROGRAM DC-WS-GENERATE-KEY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-BUILD-HANDSHAKE-REQUEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-REQUEST-LINE PIC X(1024).
       01 WS-HOST-LINE PIC X(512).
       01 WS-HOST-VALUE PIC X(512).
       01 WS-KEY-LINE PIC X(128).
       01 WS-PORT-TEXT PIC 9(5).

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-REQUEST
           DC-WS-BUFFER
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-WS-SEC-KEY) = SPACES
               CALL "DC-WS-GENERATE-KEY"
                   USING DC-WS-SEC-KEY DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           MOVE SPACES TO WS-REQUEST-LINE
           MOVE SPACES TO WS-HOST-LINE
           MOVE SPACES TO WS-HOST-VALUE
           MOVE SPACES TO WS-KEY-LINE
           MOVE SPACES TO DC-WS-BUFFER-DATA

           STRING
               "GET " DELIMITED BY SIZE
               FUNCTION TRIM(DC-WS-PATH) DELIMITED BY SIZE
               " HTTP/1.1" DELIMITED BY SIZE
               INTO WS-REQUEST-LINE
           END-STRING
           IF DC-WS-REQUEST-PORT > 0
              AND DC-WS-REQUEST-PORT NOT = 443
               MOVE DC-WS-REQUEST-PORT TO WS-PORT-TEXT
               STRING
                   FUNCTION TRIM(DC-WS-HOST) DELIMITED BY SIZE
                   ":" DELIMITED BY SIZE
                   FUNCTION TRIM(WS-PORT-TEXT) DELIMITED BY SIZE
                   INTO WS-HOST-VALUE
               END-STRING
           ELSE
               MOVE DC-WS-HOST TO WS-HOST-VALUE
           END-IF
           STRING
               "Host: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-HOST-VALUE) DELIMITED BY SIZE
               INTO WS-HOST-LINE
           END-STRING
           STRING
               "Sec-WebSocket-Key: " DELIMITED BY SIZE
               FUNCTION TRIM(DC-WS-SEC-KEY) DELIMITED BY SIZE
               INTO WS-KEY-LINE
           END-STRING

           STRING
               FUNCTION TRIM(WS-REQUEST-LINE) DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               FUNCTION TRIM(WS-HOST-LINE) DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Upgrade: websocket" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Connection: Upgrade" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               FUNCTION TRIM(WS-KEY-LINE) DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Sec-WebSocket-Version: 13" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               INTO DC-WS-BUFFER-DATA
           END-STRING

           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(DC-WS-BUFFER-DATA TRAILING))
               TO DC-WS-BUFFER-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-WS-BUILD-HANDSHAKE-REQUEST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-BUILD-ACCEPT.

       DATA DIVISION.
	       WORKING-STORAGE SECTION.
	       01 WS-SOURCE PIC X(128).
	       01 WS-DIGEST PIC X(20).
	       01 WS-SOURCE-LEN PIC 9(4) COMP-5.
	       01 WS-DIGEST-LEN PIC 9(4) COMP-5 VALUE 20.

       LINKAGE SECTION.
	       01 DC-WS-SEC-KEY-IN PIC X(24).
       01 DC-WS-ACCEPT-OUT PIC X(64).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-SEC-KEY-IN
           DC-WS-ACCEPT-OUT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO WS-SOURCE
           MOVE SPACES TO WS-DIGEST
           MOVE SPACES TO DC-WS-ACCEPT-OUT

           STRING
               FUNCTION TRIM(DC-WS-SEC-KEY-IN) DELIMITED BY SIZE
               "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
                   DELIMITED BY SIZE
               INTO WS-SOURCE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-SOURCE TRAILING))
               TO WS-SOURCE-LEN

           CALL "DC-SHA1-DIGEST"
               USING WS-SOURCE
                     WS-SOURCE-LEN
                     WS-DIGEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

	           CALL "DC-BASE64-ENCODE"
	               USING WS-DIGEST
	                     WS-DIGEST-LEN
	                     DC-WS-ACCEPT-OUT
	                     DC-RESULT
           GOBACK.
       END PROGRAM DC-WS-BUILD-ACCEPT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-WS-VALIDATE-HS-RESPONSE.

	       DATA DIVISION.
	       WORKING-STORAGE SECTION.
	       01 WS-EXPECTED-ACCEPT PIC X(64).
	       01 WS-HEADER-VALUE PIC X(512).
	       01 WS-REQUEST-KEY PIC X(24).

       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-WS-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           IF DC-HTTP-STATUS-CODE NOT = 101
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "WebSocket handshake response did not return 101."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-RAW-HEADERS
                     "Upgrade"
                     WS-HEADER-VALUE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION UPPER-CASE(FUNCTION TRIM(WS-HEADER-VALUE))
               NOT = "WEBSOCKET"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "Handshake response Upgrade header was invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-RAW-HEADERS
                     "Connection"
                     WS-HEADER-VALUE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
	           IF FUNCTION UPPER-CASE(FUNCTION TRIM(WS-HEADER-VALUE))
	               NOT = "UPGRADE"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "Handshake response Connection header was invalid."
                   TO DC-ERROR-MESSAGE
	               GOBACK
	           END-IF
	           MOVE DC-WS-SEC-KEY(1:24) TO WS-REQUEST-KEY

	           CALL "DC-WS-BUILD-ACCEPT"
	               USING WS-REQUEST-KEY
	                     WS-EXPECTED-ACCEPT
	                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-RAW-HEADERS
                     "Sec-WebSocket-Accept"
                     WS-HEADER-VALUE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(WS-HEADER-VALUE)
               NOT = FUNCTION TRIM(WS-EXPECTED-ACCEPT)
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "Handshake response Sec-WebSocket-Accept was invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-WS-VALIDATE-HS-RESPONSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-BASE64-ENCODE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ALPHABET PIC X(64)
           VALUE
           "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".
       01 WS-OUT-IDX PIC 9(5) COMP-5.
       01 WS-IN-IDX PIC 9(5) COMP-5.
       01 WS-B1 PIC 9(4) COMP-5.
       01 WS-B2 PIC 9(4) COMP-5.
       01 WS-B3 PIC 9(4) COMP-5.
       01 WS-I1 PIC 9(4) COMP-5.
	       01 WS-I2 PIC 9(4) COMP-5.
	       01 WS-I3 PIC 9(4) COMP-5.
	       01 WS-I4 PIC 9(4) COMP-5.
	       01 WS-OUTPUT-LEN PIC 9(5) COMP-5.

       LINKAGE SECTION.
       01 DC-B64-INPUT PIC X(8192).
       01 DC-B64-INPUT-LEN PIC 9(9) COMP-5.
       01 DC-B64-OUTPUT PIC X(8192).
       COPY "discord-result.cpy".

	       PROCEDURE DIVISION USING
	           DC-B64-INPUT
	           DC-B64-INPUT-LEN
	           DC-B64-OUTPUT
	           DC-RESULT.
	       MAIN.
	           MOVE 1 TO WS-IN-IDX
	           MOVE 1 TO WS-OUT-IDX

	           IF DC-B64-INPUT-LEN < 0 OR DC-B64-INPUT-LEN > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
               MOVE "Base64 input length was invalid."
	                   TO DC-ERROR-MESSAGE
	               GOBACK
	           END-IF
	           COMPUTE WS-OUTPUT-LEN =
	               FUNCTION INTEGER((DC-B64-INPUT-LEN + 2) / 3) * 4
	           IF WS-OUTPUT-LEN > 0
	               MOVE ALL " " TO DC-B64-OUTPUT(1:WS-OUTPUT-LEN)
	           END-IF

	           PERFORM UNTIL WS-IN-IDX > DC-B64-INPUT-LEN
               COMPUTE WS-B1 = FUNCTION ORD(DC-B64-INPUT(WS-IN-IDX:1)) - 1
               IF WS-IN-IDX + 1 <= DC-B64-INPUT-LEN
                   COMPUTE WS-B2 =
                       FUNCTION ORD(DC-B64-INPUT(WS-IN-IDX + 1:1)) - 1
               ELSE
                   MOVE 0 TO WS-B2
               END-IF
               IF WS-IN-IDX + 2 <= DC-B64-INPUT-LEN
                   COMPUTE WS-B3 =
                       FUNCTION ORD(DC-B64-INPUT(WS-IN-IDX + 2:1)) - 1
               ELSE
                   MOVE 0 TO WS-B3
               END-IF

               COMPUTE WS-I1 = FUNCTION INTEGER(WS-B1 / 4)
               COMPUTE WS-I2 = FUNCTION MOD(WS-B1, 4) * 16
                   + FUNCTION INTEGER(WS-B2 / 16)
               COMPUTE WS-I3 = FUNCTION MOD(WS-B2, 16) * 4
                   + FUNCTION INTEGER(WS-B3 / 64)
               COMPUTE WS-I4 = FUNCTION MOD(WS-B3, 64)

               MOVE WS-ALPHABET(WS-I1 + 1:1) TO DC-B64-OUTPUT(WS-OUT-IDX:1)
               MOVE WS-ALPHABET(WS-I2 + 1:1)
                   TO DC-B64-OUTPUT(WS-OUT-IDX + 1:1)

               IF WS-IN-IDX + 1 <= DC-B64-INPUT-LEN
                   MOVE WS-ALPHABET(WS-I3 + 1:1)
                       TO DC-B64-OUTPUT(WS-OUT-IDX + 2:1)
               ELSE
                   MOVE "=" TO DC-B64-OUTPUT(WS-OUT-IDX + 2:1)
               END-IF

               IF WS-IN-IDX + 2 <= DC-B64-INPUT-LEN
                   MOVE WS-ALPHABET(WS-I4 + 1:1)
                       TO DC-B64-OUTPUT(WS-OUT-IDX + 3:1)
               ELSE
                   MOVE "=" TO DC-B64-OUTPUT(WS-OUT-IDX + 3:1)
               END-IF

               ADD 3 TO WS-IN-IDX
               ADD 4 TO WS-OUT-IDX
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-BASE64-ENCODE.

	       IDENTIFICATION DIVISION.
	       PROGRAM-ID. DC-SHA1-DIGEST.

	       DATA DIVISION.
	       WORKING-STORAGE SECTION.
	       01 WS-MESSAGE-BITS PIC X(1024).
	       01 WS-LENGTH-BITS PIC X(64).
	       01 WS-DIGEST-BITS PIC X(160).
	       01 WS-BYTE-BITS PIC X(8).
	       01 WS-H0 PIC X(32).
	       01 WS-H1 PIC X(32).
	       01 WS-H2 PIC X(32).
	       01 WS-H3 PIC X(32).
	       01 WS-H4 PIC X(32).
	       01 WS-A PIC X(32).
	       01 WS-B PIC X(32).
	       01 WS-C PIC X(32).
	       01 WS-D PIC X(32).
	       01 WS-E PIC X(32).
	       01 WS-F PIC X(32).
	       01 WS-K PIC X(32).
	       01 WS-TEMP PIC X(32).
	       01 WS-WORK-1 PIC X(32).
	       01 WS-WORK-2 PIC X(32).
	       01 WS-WORK-3 PIC X(32).
	       01 WS-WORK-4 PIC X(32).
	       01 WS-ROL-IN PIC X(32).
	       01 WS-ROL-SHIFT PIC 9(4) COMP-5.
	       01 WS-ROL-OUT PIC X(32).
	       01 WS-BLOCK-IDX PIC 9(4) COMP-5.
	       01 WS-BYTE-IDX PIC 9(4) COMP-5.
	       01 WS-WORD-IDX PIC 9(4) COMP-5.
	       01 WS-ROUND-IDX PIC 9(4) COMP-5.
	       01 WS-BIT-IDX PIC 9(4) COMP-5.
	       01 WS-BLOCK-COUNT PIC 9(4) COMP-5.
	       01 WS-TOTAL-BITS PIC 9(5) COMP-5.
	       01 WS-MESSAGE-LEN-BITS PIC 9(18) COMP-5.
	       01 WS-NUMERIC-WORK PIC 9(18) COMP-5.
	       01 WS-CARRY PIC 9.
	       01 WS-SUM PIC 9.
	       01 WS-BIT-TOTAL PIC 9.
	       01 WS-CHAR-VALUE PIC X.
	       01 WS-DIGEST-BYTE-OFFSET PIC 9(4) COMP-5.
	       01 WS-WORDS.
	          05 WS-WORD OCCURS 80 TIMES PIC X(32).

	       LINKAGE SECTION.
	       01 DC-SHA1-INPUT PIC X(128).
	       01 DC-SHA1-INPUT-LEN PIC 9(9) COMP-5.
	       01 DC-SHA1-DIGEST-OUT PIC X(20).
	       COPY "discord-result.cpy".

	       PROCEDURE DIVISION USING
	           DC-SHA1-INPUT
	           DC-SHA1-INPUT-LEN
	           DC-SHA1-DIGEST-OUT
	           DC-RESULT.
	       MAIN.
	           MOVE LOW-VALUE TO DC-SHA1-DIGEST-OUT
	           IF DC-SHA1-INPUT-LEN < 0 OR DC-SHA1-INPUT-LEN > 119
	               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
	               MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
	               MOVE "SHA1 helper currently supports inputs up to 119 bytes."
	                   TO DC-ERROR-MESSAGE
	               GOBACK
	           END-IF

	           MOVE ALL "0" TO WS-MESSAGE-BITS
	           MOVE ALL "0" TO WS-LENGTH-BITS
	           MOVE "01100111010001010010001100000001" TO WS-H0
	           MOVE "11101111110011011010101110001001" TO WS-H1
	           MOVE "10011000101110101101110011111110" TO WS-H2
	           MOVE "00010000001100100101010001110110" TO WS-H3
	           MOVE "11000011110100101110000111110000" TO WS-H4

	           PERFORM VARYING WS-BYTE-IDX FROM 1 BY 1
	               UNTIL WS-BYTE-IDX > DC-SHA1-INPUT-LEN
	               MOVE FUNCTION BIT-OF(DC-SHA1-INPUT(WS-BYTE-IDX:1))
	                   TO WS-BYTE-BITS
	               MOVE WS-BYTE-BITS
	                   TO WS-MESSAGE-BITS(
	                       ((WS-BYTE-IDX - 1) * 8) + 1:8)
	           END-PERFORM

	           COMPUTE WS-MESSAGE-LEN-BITS = DC-SHA1-INPUT-LEN * 8
	           IF DC-SHA1-INPUT-LEN <= 55
	               MOVE 512 TO WS-TOTAL-BITS
	               MOVE 1 TO WS-BLOCK-COUNT
	           ELSE
	               MOVE 1024 TO WS-TOTAL-BITS
	               MOVE 2 TO WS-BLOCK-COUNT
	           END-IF

	           MOVE "1"
	               TO WS-MESSAGE-BITS(WS-MESSAGE-LEN-BITS + 1:1)
	           PERFORM BUILD-LENGTH-BITS
	           MOVE WS-LENGTH-BITS
	               TO WS-MESSAGE-BITS(WS-TOTAL-BITS - 63:64)

	           PERFORM VARYING WS-BLOCK-IDX FROM 0 BY 1
	               UNTIL WS-BLOCK-IDX >= WS-BLOCK-COUNT
	               PERFORM BUILD-WORDS
	               PERFORM EXPAND-WORDS
	               PERFORM PROCESS-BLOCK
	           END-PERFORM

	           PERFORM WRITE-DIGEST
	           CALL "DC-RESULT-OK" USING DC-RESULT
	           GOBACK.

	       BUILD-LENGTH-BITS.
	           MOVE ALL "0" TO WS-LENGTH-BITS
	           MOVE WS-MESSAGE-LEN-BITS TO WS-NUMERIC-WORK
	           PERFORM VARYING WS-BIT-IDX FROM 64 BY -1
	               UNTIL WS-BIT-IDX < 1
	               IF FUNCTION MOD(WS-NUMERIC-WORK, 2) = 1
	                   MOVE "1" TO WS-LENGTH-BITS(WS-BIT-IDX:1)
	               ELSE
	                   MOVE "0" TO WS-LENGTH-BITS(WS-BIT-IDX:1)
	               END-IF
	               COMPUTE WS-NUMERIC-WORK =
	                   FUNCTION INTEGER(WS-NUMERIC-WORK / 2)
	           END-PERFORM.

	       BUILD-WORDS.
	           PERFORM VARYING WS-WORD-IDX FROM 1 BY 1 UNTIL WS-WORD-IDX > 80
	               MOVE ALL "0" TO WS-WORD(WS-WORD-IDX)
	           END-PERFORM
	           PERFORM VARYING WS-WORD-IDX FROM 1 BY 1 UNTIL WS-WORD-IDX > 16
	               MOVE WS-MESSAGE-BITS(
	                   (WS-BLOCK-IDX * 512) + ((WS-WORD-IDX - 1) * 32) + 1:32)
	                   TO WS-WORD(WS-WORD-IDX)
	           END-PERFORM.

	       EXPAND-WORDS.
	           PERFORM VARYING WS-WORD-IDX FROM 17 BY 1 UNTIL WS-WORD-IDX > 80
	               MOVE WS-WORD(WS-WORD-IDX - 3) TO WS-WORK-1
	               MOVE WS-WORD(WS-WORD-IDX - 8) TO WS-WORK-2
	               PERFORM XOR32
	               MOVE WS-TEMP TO WS-WORK-1
	               MOVE WS-WORD(WS-WORD-IDX - 14) TO WS-WORK-2
	               PERFORM XOR32
	               MOVE WS-TEMP TO WS-WORK-1
	               MOVE WS-WORD(WS-WORD-IDX - 16) TO WS-WORK-2
	               PERFORM XOR32
	               MOVE WS-TEMP TO WS-ROL-IN
	               MOVE 1 TO WS-ROL-SHIFT
	               PERFORM ROL32
	               MOVE WS-ROL-OUT TO WS-WORD(WS-WORD-IDX)
	           END-PERFORM.

	       PROCESS-BLOCK.
	           MOVE WS-H0 TO WS-A
	           MOVE WS-H1 TO WS-B
	           MOVE WS-H2 TO WS-C
	           MOVE WS-H3 TO WS-D
	           MOVE WS-H4 TO WS-E

	           PERFORM VARYING WS-ROUND-IDX FROM 1 BY 1 UNTIL WS-ROUND-IDX > 80
	               EVALUATE TRUE
	                   WHEN WS-ROUND-IDX <= 20
	                       MOVE WS-B TO WS-WORK-1
	                       MOVE WS-C TO WS-WORK-2
	                       MOVE WS-D TO WS-WORK-3
	                       PERFORM CH32
	                       MOVE "01011010100000100111100110011001"
	                           TO WS-K
	                   WHEN WS-ROUND-IDX <= 40
	                       MOVE WS-B TO WS-WORK-1
	                       MOVE WS-C TO WS-WORK-2
	                       MOVE WS-D TO WS-WORK-3
	                       PERFORM XOR3-32
	                       MOVE "01101110110110011110101110100001"
	                           TO WS-K
	                   WHEN WS-ROUND-IDX <= 60
	                       MOVE WS-B TO WS-WORK-1
	                       MOVE WS-C TO WS-WORK-2
	                       MOVE WS-D TO WS-WORK-3
	                       PERFORM MAJ32
	                       MOVE "10001111000110111011110011011100"
	                           TO WS-K
	                   WHEN OTHER
	                       MOVE WS-B TO WS-WORK-1
	                       MOVE WS-C TO WS-WORK-2
	                       MOVE WS-D TO WS-WORK-3
	                       PERFORM XOR3-32
	                       MOVE "11001010011000101100000111010110"
	                           TO WS-K
	               END-EVALUATE

	               MOVE WS-A TO WS-ROL-IN
	               MOVE 5 TO WS-ROL-SHIFT
	               PERFORM ROL32
	               MOVE WS-ROL-OUT TO WS-WORK-1
	               MOVE WS-F TO WS-WORK-2
	               PERFORM ADD32
	               MOVE WS-TEMP TO WS-WORK-1
	               MOVE WS-E TO WS-WORK-2
	               PERFORM ADD32
	               MOVE WS-TEMP TO WS-WORK-1
	               MOVE WS-K TO WS-WORK-2
	               PERFORM ADD32
	               MOVE WS-TEMP TO WS-WORK-1
	               MOVE WS-WORD(WS-ROUND-IDX) TO WS-WORK-2
	               PERFORM ADD32
	               MOVE WS-D TO WS-E
	               MOVE WS-C TO WS-D
	               MOVE WS-B TO WS-ROL-IN
	               MOVE 30 TO WS-ROL-SHIFT
	               PERFORM ROL32
	               MOVE WS-ROL-OUT TO WS-C
	               MOVE WS-A TO WS-B
	               MOVE WS-TEMP TO WS-A
	           END-PERFORM

	           MOVE WS-H0 TO WS-WORK-1
	           MOVE WS-A TO WS-WORK-2
	           PERFORM ADD32
	           MOVE WS-TEMP TO WS-H0
	           MOVE WS-H1 TO WS-WORK-1
	           MOVE WS-B TO WS-WORK-2
	           PERFORM ADD32
	           MOVE WS-TEMP TO WS-H1
	           MOVE WS-H2 TO WS-WORK-1
	           MOVE WS-C TO WS-WORK-2
	           PERFORM ADD32
	           MOVE WS-TEMP TO WS-H2
	           MOVE WS-H3 TO WS-WORK-1
	           MOVE WS-D TO WS-WORK-2
	           PERFORM ADD32
	           MOVE WS-TEMP TO WS-H3
	           MOVE WS-H4 TO WS-WORK-1
	           MOVE WS-E TO WS-WORK-2
	           PERFORM ADD32
	           MOVE WS-TEMP TO WS-H4.

	       ROL32.
	           IF WS-ROL-SHIFT = 0
	               MOVE WS-ROL-IN TO WS-ROL-OUT
	           ELSE
	               STRING
	                   WS-ROL-IN(WS-ROL-SHIFT + 1:32 - WS-ROL-SHIFT)
	                       DELIMITED BY SIZE
	                   WS-ROL-IN(1:WS-ROL-SHIFT) DELIMITED BY SIZE
	                   INTO WS-ROL-OUT
	               END-STRING
	           END-IF.

	       XOR32.
	           MOVE ALL "0" TO WS-TEMP
	           PERFORM VARYING WS-BIT-IDX FROM 1 BY 1 UNTIL WS-BIT-IDX > 32
	               IF WS-WORK-1(WS-BIT-IDX:1) = WS-WORK-2(WS-BIT-IDX:1)
	                   MOVE "0" TO WS-TEMP(WS-BIT-IDX:1)
	               ELSE
	                   MOVE "1" TO WS-TEMP(WS-BIT-IDX:1)
	               END-IF
	           END-PERFORM.

	       XOR3-32.
	           MOVE WS-WORK-1 TO WS-WORK-4
	           MOVE WS-WORK-2 TO WS-WORK-1
	           MOVE WS-WORK-3 TO WS-WORK-2
	           PERFORM XOR32
	           MOVE WS-TEMP TO WS-WORK-1
	           MOVE WS-WORK-4 TO WS-WORK-2
	           PERFORM XOR32
	           MOVE WS-TEMP TO WS-F.

	       CH32.
	           MOVE ALL "0" TO WS-F
	           PERFORM VARYING WS-BIT-IDX FROM 1 BY 1 UNTIL WS-BIT-IDX > 32
	               IF WS-WORK-1(WS-BIT-IDX:1) = "1"
	                   MOVE WS-WORK-2(WS-BIT-IDX:1) TO WS-F(WS-BIT-IDX:1)
	               ELSE
	                   MOVE WS-WORK-3(WS-BIT-IDX:1) TO WS-F(WS-BIT-IDX:1)
	               END-IF
	           END-PERFORM.

	       MAJ32.
	           MOVE ALL "0" TO WS-F
	           PERFORM VARYING WS-BIT-IDX FROM 1 BY 1 UNTIL WS-BIT-IDX > 32
	               MOVE 0 TO WS-BIT-TOTAL
	               IF WS-WORK-1(WS-BIT-IDX:1) = "1"
	                   ADD 1 TO WS-BIT-TOTAL
	               END-IF
	               IF WS-WORK-2(WS-BIT-IDX:1) = "1"
	                   ADD 1 TO WS-BIT-TOTAL
	               END-IF
	               IF WS-WORK-3(WS-BIT-IDX:1) = "1"
	                   ADD 1 TO WS-BIT-TOTAL
	               END-IF
	               IF WS-BIT-TOTAL >= 2
	                   MOVE "1" TO WS-F(WS-BIT-IDX:1)
	               ELSE
	                   MOVE "0" TO WS-F(WS-BIT-IDX:1)
	               END-IF
	           END-PERFORM.

	       ADD32.
	           MOVE ALL "0" TO WS-TEMP
	           MOVE 0 TO WS-CARRY
	           PERFORM VARYING WS-BIT-IDX FROM 32 BY -1 UNTIL WS-BIT-IDX < 1
	               MOVE 0 TO WS-SUM
	               IF WS-WORK-1(WS-BIT-IDX:1) = "1"
	                   ADD 1 TO WS-SUM
	               END-IF
	               IF WS-WORK-2(WS-BIT-IDX:1) = "1"
	                   ADD 1 TO WS-SUM
	               END-IF
	               ADD WS-CARRY TO WS-SUM
	               IF FUNCTION MOD(WS-SUM, 2) = 1
	                   MOVE "1" TO WS-TEMP(WS-BIT-IDX:1)
	               ELSE
	                   MOVE "0" TO WS-TEMP(WS-BIT-IDX:1)
	               END-IF
	               IF WS-SUM >= 2
	                   MOVE 1 TO WS-CARRY
	               ELSE
	                   MOVE 0 TO WS-CARRY
	               END-IF
	           END-PERFORM.

	       WRITE-DIGEST.
	           MOVE SPACES TO WS-DIGEST-BITS
	           MOVE WS-H0 TO WS-DIGEST-BITS(1:32)
	           MOVE WS-H1 TO WS-DIGEST-BITS(33:32)
	           MOVE WS-H2 TO WS-DIGEST-BITS(65:32)
	           MOVE WS-H3 TO WS-DIGEST-BITS(97:32)
	           MOVE WS-H4 TO WS-DIGEST-BITS(129:32)
	           PERFORM VARYING WS-BYTE-IDX FROM 1 BY 1 UNTIL WS-BYTE-IDX > 20
	               COMPUTE WS-DIGEST-BYTE-OFFSET = ((WS-BYTE-IDX - 1) * 8) + 1
	               MOVE FUNCTION BIT-TO-CHAR(
	                   WS-DIGEST-BITS(WS-DIGEST-BYTE-OFFSET:8))
	                   TO WS-CHAR-VALUE
	               MOVE WS-CHAR-VALUE TO DC-SHA1-DIGEST-OUT(WS-BYTE-IDX:1)
	           END-PERFORM.
	       END PROGRAM DC-SHA1-DIGEST.
