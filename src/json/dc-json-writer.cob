       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-ESCAPE.
       *> JP: 固定長文字列を JSON string content として安全に escape します。
       *> EN: Safely escapes a fixed-width value for use as JSON string content.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IN-LENGTH PIC 9(5) COMP-5.
       01 WS-IN-POS PIC 9(5) COMP-5.
       01 WS-OUT-POS PIC 9(5) COMP-5.
       01 WS-CHAR PIC X.
       01 WS-BYTE PIC 9(4) COMP-5.
       01 WS-HIGH PIC 9(3) COMP-5.
       01 WS-LOW PIC 9(3) COMP-5.
       01 WS-HEX-DIGITS PIC X(16) VALUE "0123456789ABCDEF".

       LINKAGE SECTION.
       01 DC-JSON-ESCAPE-IN PIC X(512).
       01 DC-JSON-ESCAPE-OUT PIC X(4096).
       01 DC-JSON-ESCAPE-LENGTH PIC 9(5) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-ESCAPE-IN DC-JSON-ESCAPE-OUT
           DC-JSON-ESCAPE-LENGTH DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-JSON-ESCAPE-OUT
           MOVE 0 TO DC-JSON-ESCAPE-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           MOVE 512 TO WS-IN-LENGTH
           PERFORM UNTIL WS-IN-LENGTH = 0
               OR DC-JSON-ESCAPE-IN(WS-IN-LENGTH:1) NOT = SPACE
               SUBTRACT 1 FROM WS-IN-LENGTH
           END-PERFORM
           MOVE 1 TO WS-OUT-POS
           PERFORM VARYING WS-IN-POS FROM 1 BY 1
               UNTIL WS-IN-POS > WS-IN-LENGTH
               MOVE DC-JSON-ESCAPE-IN(WS-IN-POS:1) TO WS-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-CHAR) - 1
               EVALUATE WS-CHAR
                   WHEN QUOTE
                       PERFORM WRITE-BACKSLASH
                       MOVE QUOTE TO WS-CHAR
                       PERFORM WRITE-CHAR
                   WHEN X"5C"
                       PERFORM WRITE-BACKSLASH
                       MOVE X"5C" TO WS-CHAR
                       PERFORM WRITE-CHAR
                   WHEN X"08"
                       PERFORM WRITE-BACKSLASH
                       MOVE "b" TO WS-CHAR
                       PERFORM WRITE-CHAR
                   WHEN X"0C"
                       PERFORM WRITE-BACKSLASH
                       MOVE "f" TO WS-CHAR
                       PERFORM WRITE-CHAR
                   WHEN X"0A"
                       PERFORM WRITE-BACKSLASH
                       MOVE "n" TO WS-CHAR
                       PERFORM WRITE-CHAR
                   WHEN X"0D"
                       PERFORM WRITE-BACKSLASH
                       MOVE "r" TO WS-CHAR
                       PERFORM WRITE-CHAR
                   WHEN X"09"
                       PERFORM WRITE-BACKSLASH
                       MOVE "t" TO WS-CHAR
                       PERFORM WRITE-CHAR
                   WHEN OTHER
                       IF WS-BYTE < 32
                           PERFORM WRITE-UNICODE-CONTROL
                       ELSE
                           PERFORM WRITE-CHAR
                       END-IF
               END-EVALUATE
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-PERFORM
           COMPUTE DC-JSON-ESCAPE-LENGTH = WS-OUT-POS - 1
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       WRITE-BACKSLASH.
           MOVE X"5C" TO WS-CHAR
           PERFORM WRITE-CHAR.
       WRITE-UNICODE-CONTROL.
           MOVE X"5C" TO WS-CHAR
           PERFORM WRITE-CHAR
           MOVE "u" TO WS-CHAR
           PERFORM WRITE-CHAR
           MOVE "0" TO WS-CHAR
           PERFORM WRITE-CHAR
           PERFORM WRITE-CHAR
           COMPUTE WS-HIGH = WS-BYTE / 16
           COMPUTE WS-LOW = FUNCTION MOD(WS-BYTE, 16)
           MOVE WS-HEX-DIGITS(WS-HIGH + 1:1) TO WS-CHAR
           PERFORM WRITE-CHAR
           MOVE WS-HEX-DIGITS(WS-LOW + 1:1) TO WS-CHAR
           PERFORM WRITE-CHAR.
       WRITE-CHAR.
           IF WS-OUT-POS > 4096
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_OUTPUT_TOO_LONG" TO DC-ERROR-CODE
               MOVE "Escaped JSON string exceeds 4096 bytes."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           MOVE WS-CHAR TO DC-JSON-ESCAPE-OUT(WS-OUT-POS:1)
           ADD 1 TO WS-OUT-POS.
       END PROGRAM DC-JSON-ESCAPE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-WRITE-STRING.
       *> JP: key/value の両方を escape して単一 property object を生成します。
       *> EN: Escapes both key and value and builds a single-property object.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-KEY-IN PIC X(512).
       01 WS-KEY-OUT PIC X(4096).
       01 WS-KEY-LENGTH PIC 9(5) COMP-5.
       01 WS-VALUE-OUT PIC X(4096).
       01 WS-VALUE-LENGTH PIC 9(5) COMP-5.
       01 WS-TOTAL-LENGTH PIC 9(5) COMP-5.

       LINKAGE SECTION.
       01 DC-JSON-KEY-IN PIC X(128).
       01 DC-JSON-VALUE-IN PIC X(512).
       01 DC-JSON-OUT PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-KEY-IN DC-JSON-VALUE-IN DC-JSON-OUT DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-JSON-OUT WS-KEY-IN
           MOVE DC-JSON-KEY-IN TO WS-KEY-IN(1:128)
           CALL "DC-JSON-ESCAPE"
               USING WS-KEY-IN WS-KEY-OUT WS-KEY-LENGTH DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           CALL "DC-JSON-ESCAPE"
               USING DC-JSON-VALUE-IN WS-VALUE-OUT
                     WS-VALUE-LENGTH DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           COMPUTE WS-TOTAL-LENGTH =
               WS-KEY-LENGTH + WS-VALUE-LENGTH + 7
           IF WS-TOTAL-LENGTH > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_OUTPUT_TOO_LONG" TO DC-ERROR-CODE
               MOVE "JSON object exceeds the output buffer."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               WS-KEY-OUT(1:WS-KEY-LENGTH) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               WS-VALUE-OUT(1:WS-VALUE-LENGTH) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "}" DELIMITED BY SIZE
               INTO DC-JSON-OUT
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-JSON-WRITE-STRING.
