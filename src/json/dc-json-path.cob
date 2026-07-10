       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-LOCATE-PATH.
       *> JP: token の深さを使い、同名キーや配列を取り違えずに値位置を返します。
       *> JP: path は $.object.key と $.items[0].name の両形式を扱います。
       *> EN: Uses token depth to locate values without confusing nested duplicate keys.
       *> EN: Paths support both $.object.key and $.items[0].name forms.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-json.cpy".
       01 WS-PATH-LENGTH PIC 9(4) COMP-5.
       01 WS-PATH-POS PIC 9(4) COMP-5.
       01 WS-CURRENT-TOKEN PIC 9(5) COMP-5.
       01 WS-INDEX PIC 9(5) COMP-5.
       01 WS-NEXT-INDEX PIC 9(5) COMP-5.
       01 WS-CONTAINER-DEPTH PIC 9(3) COMP-5.
       01 WS-KEY PIC X(128).
       01 WS-KEY-LENGTH PIC 9(4) COMP-5.
       01 WS-RAW-KEY-LENGTH PIC 9(5) COMP-5.
       01 WS-RAW-KEY-START PIC 9(5) COMP-5.
       01 WS-ARRAY-INDEX PIC 9(5) COMP-5.
       01 WS-CHILD-INDEX PIC 9(5) COMP-5.
       01 WS-FOUND-FLAG PIC 9.
       01 WS-EXPECT-VALUE PIC 9.
       01 WS-CHAR PIC X.

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       01 DC-JSON-PATH-IN PIC X(128).
       01 DC-JSON-VALUE-POS PIC 9(5) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-BUFFER-IN
           DC-JSON-PATH-IN
           DC-JSON-VALUE-POS
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-JSON-VALUE-POS
           CALL "DC-JSON-SCAN"
               USING DC-JSON-BUFFER-IN DC-JSON-TOKENS DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE 128 TO WS-PATH-LENGTH
           PERFORM UNTIL WS-PATH-LENGTH = 0
               OR DC-JSON-PATH-IN(WS-PATH-LENGTH:1) NOT = SPACE
               SUBTRACT 1 FROM WS-PATH-LENGTH
           END-PERFORM
           IF WS-PATH-LENGTH = 0 OR DC-JSON-PATH-IN(1:1) NOT = "$"
               PERFORM PATH-SYNTAX-ERROR
               GOBACK
           END-IF

           MOVE 1 TO WS-CURRENT-TOKEN
           MOVE 2 TO WS-PATH-POS
           PERFORM UNTIL WS-PATH-POS > WS-PATH-LENGTH
               MOVE DC-JSON-PATH-IN(WS-PATH-POS:1) TO WS-CHAR
               EVALUATE WS-CHAR
                   WHEN "."
                       PERFORM READ-KEY-SEGMENT
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                       PERFORM FIND-OBJECT-MEMBER
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                   WHEN "["
                       PERFORM READ-ARRAY-INDEX
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                       PERFORM FIND-ARRAY-ELEMENT
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                   WHEN OTHER
                       PERFORM PATH-SYNTAX-ERROR
                       GOBACK
               END-EVALUATE
           END-PERFORM

           MOVE DC-JT-START(WS-CURRENT-TOKEN) TO DC-JSON-VALUE-POS
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       READ-KEY-SEGMENT.
           ADD 1 TO WS-PATH-POS
           MOVE SPACES TO WS-KEY
           MOVE 0 TO WS-KEY-LENGTH
           PERFORM UNTIL WS-PATH-POS > WS-PATH-LENGTH
               OR DC-JSON-PATH-IN(WS-PATH-POS:1) = "."
               OR DC-JSON-PATH-IN(WS-PATH-POS:1) = "["
               IF WS-KEY-LENGTH >= 128
                   PERFORM PATH-SYNTAX-ERROR
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-KEY-LENGTH
               MOVE DC-JSON-PATH-IN(WS-PATH-POS:1)
                   TO WS-KEY(WS-KEY-LENGTH:1)
               ADD 1 TO WS-PATH-POS
           END-PERFORM
           IF WS-KEY-LENGTH = 0
               PERFORM PATH-SYNTAX-ERROR
               EXIT PARAGRAPH
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       FIND-OBJECT-MEMBER.
           IF DC-JT-KIND(WS-CURRENT-TOKEN) NOT = DC-JT-OBJECT-START
               PERFORM PATH-TYPE-ERROR
               EXIT PARAGRAPH
           END-IF
           MOVE DC-JT-DEPTH(WS-CURRENT-TOKEN) TO WS-CONTAINER-DEPTH
           COMPUTE WS-INDEX = WS-CURRENT-TOKEN + 1
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM UNTIL WS-INDEX > DC-JT-COUNT OR WS-FOUND-FLAG = 1
               IF DC-JT-KIND(WS-INDEX) = DC-JT-OBJECT-END
                  AND DC-JT-DEPTH(WS-INDEX) = WS-CONTAINER-DEPTH
                   EXIT PERFORM
               END-IF
               COMPUTE WS-NEXT-INDEX = WS-INDEX + 1
               IF DC-JT-KIND(WS-INDEX) = DC-JT-STRING
                  AND DC-JT-DEPTH(WS-INDEX) = WS-CONTAINER-DEPTH + 1
                  AND WS-NEXT-INDEX <= DC-JT-COUNT
                  AND DC-JT-KIND(WS-NEXT-INDEX) = DC-JT-COLON
                   COMPUTE WS-RAW-KEY-START = DC-JT-START(WS-INDEX) + 1
                   COMPUTE WS-RAW-KEY-LENGTH = DC-JT-LENGTH(WS-INDEX) - 2
                   IF WS-RAW-KEY-LENGTH = WS-KEY-LENGTH
                      AND DC-JSON-BUFFER-IN(
                          WS-RAW-KEY-START:WS-RAW-KEY-LENGTH)
                          = WS-KEY(1:WS-KEY-LENGTH)
                       COMPUTE WS-CURRENT-TOKEN = WS-INDEX + 2
                       IF WS-CURRENT-TOKEN > DC-JT-COUNT
                           PERFORM PATH-SYNTAX-ERROR
                           EXIT PARAGRAPH
                       END-IF
                       MOVE 1 TO WS-FOUND-FLAG
                   END-IF
               END-IF
               ADD 1 TO WS-INDEX
           END-PERFORM
           IF WS-FOUND-FLAG = 0
               PERFORM PATH-NOT-FOUND
               EXIT PARAGRAPH
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       READ-ARRAY-INDEX.
           ADD 1 TO WS-PATH-POS
           MOVE 0 TO WS-ARRAY-INDEX WS-FOUND-FLAG
           PERFORM UNTIL WS-PATH-POS > WS-PATH-LENGTH
               MOVE DC-JSON-PATH-IN(WS-PATH-POS:1) TO WS-CHAR
               IF WS-CHAR >= "0" AND <= "9"
                   COMPUTE WS-ARRAY-INDEX = WS-ARRAY-INDEX * 10
                       + FUNCTION NUMVAL(WS-CHAR)
                   MOVE 1 TO WS-FOUND-FLAG
                   ADD 1 TO WS-PATH-POS
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM
           IF WS-FOUND-FLAG = 0
              OR WS-PATH-POS > WS-PATH-LENGTH
              OR DC-JSON-PATH-IN(WS-PATH-POS:1) NOT = "]"
               PERFORM PATH-SYNTAX-ERROR
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-PATH-POS
           CALL "DC-RESULT-OK" USING DC-RESULT.

       FIND-ARRAY-ELEMENT.
           IF DC-JT-KIND(WS-CURRENT-TOKEN) NOT = DC-JT-ARRAY-START
               PERFORM PATH-TYPE-ERROR
               EXIT PARAGRAPH
           END-IF
           MOVE DC-JT-DEPTH(WS-CURRENT-TOKEN) TO WS-CONTAINER-DEPTH
           COMPUTE WS-INDEX = WS-CURRENT-TOKEN + 1
           MOVE 0 TO WS-CHILD-INDEX WS-FOUND-FLAG
           MOVE 1 TO WS-EXPECT-VALUE
           PERFORM UNTIL WS-INDEX > DC-JT-COUNT OR WS-FOUND-FLAG = 1
               IF DC-JT-KIND(WS-INDEX) = DC-JT-ARRAY-END
                  AND DC-JT-DEPTH(WS-INDEX) = WS-CONTAINER-DEPTH
                   EXIT PERFORM
               END-IF
               IF DC-JT-DEPTH(WS-INDEX) = WS-CONTAINER-DEPTH + 1
                   IF DC-JT-KIND(WS-INDEX) = DC-JT-COMMA
                       MOVE 1 TO WS-EXPECT-VALUE
                   ELSE
                       IF WS-EXPECT-VALUE = 1
                          AND DC-JT-KIND(WS-INDEX) NOT = DC-JT-COLON
                          AND DC-JT-KIND(WS-INDEX) NOT = DC-JT-OBJECT-END
                          AND DC-JT-KIND(WS-INDEX) NOT = DC-JT-ARRAY-END
                           IF WS-CHILD-INDEX = WS-ARRAY-INDEX
                               MOVE WS-INDEX TO WS-CURRENT-TOKEN
                               MOVE 1 TO WS-FOUND-FLAG
                           ELSE
                               ADD 1 TO WS-CHILD-INDEX
                               MOVE 0 TO WS-EXPECT-VALUE
                           END-IF
                       END-IF
                   END-IF
               END-IF
               ADD 1 TO WS-INDEX
           END-PERFORM
           IF WS-FOUND-FLAG = 0
               PERFORM PATH-NOT-FOUND
               EXIT PARAGRAPH
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       PATH-SYNTAX-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_PATH" TO DC-ERROR-CODE
           MOVE "JSON path syntax is invalid." TO DC-ERROR-MESSAGE.
       PATH-TYPE-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_PATH_TYPE" TO DC-ERROR-CODE
           MOVE "JSON path traverses a value of the wrong type."
               TO DC-ERROR-MESSAGE.
       PATH-NOT-FOUND.
           MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_NOT_FOUND" TO DC-ERROR-CODE
           MOVE "JSON path was not found." TO DC-ERROR-MESSAGE.
       END PROGRAM DC-JSON-LOCATE-PATH.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-GET-STRING.
       *> JP: path で選んだ JSON string を UTF-8 へ unescape して返します。
       *> EN: Returns the selected JSON string unescaped as UTF-8.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VALUE-POS PIC 9(5) COMP-5.
       01 WS-POS PIC 9(5) COMP-5.
       01 WS-OUT-POS PIC 9(5) COMP-5.
       01 WS-CHAR PIC X.
       01 WS-ESCAPE PIC X.
       01 WS-CODEPOINT PIC 9(8) COMP-5.
       01 WS-LOW-CODEPOINT PIC 9(8) COMP-5.
       01 WS-HEX-VALUE PIC 9(8) COMP-5.
       01 WS-HEX-DIGIT PIC 9(3) COMP-5.
       01 WS-IDX PIC 9(3) COMP-5.
       01 WS-BYTE PIC 9(3) COMP-5.
       01 WS-UNICODE-FLAG PIC 9.
       01 WS-QUOTIENT PIC 9(8) COMP-5.

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       01 DC-JSON-PATH-IN PIC X(128).
       01 DC-JSON-OUT-VALUE PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-BUFFER-IN DC-JSON-PATH-IN
           DC-JSON-OUT-VALUE DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-JSON-OUT-VALUE
           CALL "DC-JSON-LOCATE-PATH"
               USING DC-JSON-BUFFER-IN DC-JSON-PATH-IN
                     WS-VALUE-POS DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF DC-JSON-BUFFER-IN(WS-VALUE-POS:1) NOT = QUOTE
               PERFORM STRING-TYPE-ERROR
               GOBACK
           END-IF

           COMPUTE WS-POS = WS-VALUE-POS + 1
           MOVE 1 TO WS-OUT-POS
           PERFORM UNTIL WS-POS > 8192
               MOVE 0 TO WS-UNICODE-FLAG
               MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-CHAR
               IF WS-CHAR = QUOTE
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
               IF WS-CHAR = X"5C"
                   ADD 1 TO WS-POS
                   MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-ESCAPE
                   EVALUATE WS-ESCAPE
                       WHEN QUOTE MOVE QUOTE TO WS-CHAR
                       WHEN X"5C" MOVE X"5C" TO WS-CHAR
                       WHEN "/" MOVE "/" TO WS-CHAR
                       WHEN "b" MOVE X"08" TO WS-CHAR
                       WHEN "f" MOVE X"0C" TO WS-CHAR
                       WHEN "n" MOVE X"0A" TO WS-CHAR
                       WHEN "r" MOVE X"0D" TO WS-CHAR
                       WHEN "t" MOVE X"09" TO WS-CHAR
                       WHEN "u"
                           MOVE 1 TO WS-UNICODE-FLAG
                           ADD 1 TO WS-POS
                           PERFORM READ-HEX-CODEPOINT
                           IF DC-STATUS-CODE NOT = DC-STATUS-OK
                               GOBACK
                           END-IF
                           IF WS-CODEPOINT >= 55296 AND <= 56319
                              AND WS-POS + 1 <= 8192
                              AND DC-JSON-BUFFER-IN(WS-POS:2) = X"5C75"
                               ADD 2 TO WS-POS
                               MOVE WS-CODEPOINT TO WS-HEX-VALUE
                               PERFORM READ-HEX-CODEPOINT
                               MOVE WS-CODEPOINT TO WS-LOW-CODEPOINT
                               IF WS-LOW-CODEPOINT >= 56320 AND <= 57343
                                   COMPUTE WS-CODEPOINT = 65536
                                       + ((WS-HEX-VALUE - 55296) * 1024)
                                       + (WS-LOW-CODEPOINT - 56320)
                               ELSE
                                   PERFORM STRING-ESCAPE-ERROR
                                   GOBACK
                               END-IF
                           END-IF
                           PERFORM WRITE-UTF8
                           IF DC-STATUS-CODE NOT = DC-STATUS-OK
                               GOBACK
                           END-IF
                       WHEN OTHER
                           PERFORM STRING-ESCAPE-ERROR
                           GOBACK
                   END-EVALUATE
               END-IF
               IF WS-UNICODE-FLAG = 0
                   PERFORM WRITE-CHAR
                   ADD 1 TO WS-POS
               END-IF
           END-PERFORM
           PERFORM STRING-ESCAPE-ERROR
           GOBACK.

       READ-HEX-CODEPOINT.
           MOVE 0 TO WS-CODEPOINT
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 4
               MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-CHAR
               EVALUATE TRUE
                   WHEN WS-CHAR >= "0" AND <= "9"
                       COMPUTE WS-HEX-DIGIT = FUNCTION ORD(WS-CHAR)
                           - FUNCTION ORD("0")
                   WHEN WS-CHAR >= "A" AND <= "F"
                       COMPUTE WS-HEX-DIGIT = FUNCTION ORD(WS-CHAR)
                           - FUNCTION ORD("A") + 10
                   WHEN WS-CHAR >= "a" AND <= "f"
                       COMPUTE WS-HEX-DIGIT = FUNCTION ORD(WS-CHAR)
                           - FUNCTION ORD("a") + 10
                   WHEN OTHER
                       PERFORM STRING-ESCAPE-ERROR
                       EXIT PARAGRAPH
               END-EVALUATE
               COMPUTE WS-CODEPOINT = WS-CODEPOINT * 16 + WS-HEX-DIGIT
               ADD 1 TO WS-POS
           END-PERFORM
           CALL "DC-RESULT-OK" USING DC-RESULT.

       WRITE-UTF8.
           EVALUATE TRUE
               WHEN WS-CODEPOINT <= 127
                   MOVE WS-CODEPOINT TO WS-BYTE
                   PERFORM WRITE-BYTE
               WHEN WS-CODEPOINT <= 2047
                   COMPUTE WS-QUOTIENT = WS-CODEPOINT / 64
                   COMPUTE WS-BYTE = 192 + WS-QUOTIENT
                   PERFORM WRITE-BYTE
                   COMPUTE WS-BYTE = 128 + FUNCTION MOD(WS-CODEPOINT, 64)
                   PERFORM WRITE-BYTE
               WHEN WS-CODEPOINT <= 65535
                   COMPUTE WS-QUOTIENT = WS-CODEPOINT / 4096
                   COMPUTE WS-BYTE = 224 + WS-QUOTIENT
                   PERFORM WRITE-BYTE
                   COMPUTE WS-QUOTIENT = WS-CODEPOINT / 64
                   COMPUTE WS-BYTE = 128
                       + FUNCTION MOD(WS-QUOTIENT, 64)
                   PERFORM WRITE-BYTE
                   COMPUTE WS-BYTE = 128 + FUNCTION MOD(WS-CODEPOINT, 64)
                   PERFORM WRITE-BYTE
               WHEN WS-CODEPOINT <= 1114111
                   COMPUTE WS-QUOTIENT = WS-CODEPOINT / 262144
                   COMPUTE WS-BYTE = 240 + WS-QUOTIENT
                   PERFORM WRITE-BYTE
                   COMPUTE WS-QUOTIENT = WS-CODEPOINT / 4096
                   COMPUTE WS-BYTE = 128
                       + FUNCTION MOD(WS-QUOTIENT, 64)
                   PERFORM WRITE-BYTE
                   COMPUTE WS-QUOTIENT = WS-CODEPOINT / 64
                   COMPUTE WS-BYTE = 128
                       + FUNCTION MOD(WS-QUOTIENT, 64)
                   PERFORM WRITE-BYTE
                   COMPUTE WS-BYTE = 128 + FUNCTION MOD(WS-CODEPOINT, 64)
                   PERFORM WRITE-BYTE
               WHEN OTHER
                   PERFORM STRING-ESCAPE-ERROR
           END-EVALUATE.

       WRITE-BYTE.
           MOVE FUNCTION CHAR(WS-BYTE + 1) TO WS-CHAR
           PERFORM WRITE-CHAR.
       WRITE-CHAR.
           IF WS-OUT-POS > 512
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_VALUE_TOO_LONG" TO DC-ERROR-CODE
               MOVE "Decoded JSON string exceeds 512 bytes."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           MOVE WS-CHAR TO DC-JSON-OUT-VALUE(WS-OUT-POS:1)
           ADD 1 TO WS-OUT-POS.
       STRING-TYPE-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_TYPE" TO DC-ERROR-CODE
           MOVE "JSON value is not a string." TO DC-ERROR-MESSAGE.
       STRING-ESCAPE-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_STRING" TO DC-ERROR-CODE
           MOVE "JSON string contains an invalid escape."
               TO DC-ERROR-MESSAGE.
       END PROGRAM DC-JSON-GET-STRING.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-GET-NUMBER.
       *> JP: path で選んだ JSON number を整数として返します。
       *> EN: Returns the selected JSON number as an integer.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VALUE-POS PIC 9(5) COMP-5.
       01 WS-END-POS PIC 9(5) COMP-5.
       01 WS-NUMBER-LENGTH PIC 9(5) COMP-5.
       01 WS-NUMBER-TEXT PIC X(64).
       01 WS-CHAR PIC X.

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       01 DC-JSON-PATH-IN PIC X(128).
       01 DC-JSON-OUT-NUMBER PIC S9(18) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-BUFFER-IN DC-JSON-PATH-IN
           DC-JSON-OUT-NUMBER DC-RESULT.
       MAIN.
           MOVE 0 TO DC-JSON-OUT-NUMBER
           MOVE SPACES TO WS-NUMBER-TEXT
           CALL "DC-JSON-LOCATE-PATH"
               USING DC-JSON-BUFFER-IN DC-JSON-PATH-IN
                     WS-VALUE-POS DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE WS-VALUE-POS TO WS-END-POS
           PERFORM UNTIL WS-END-POS > 8192
               MOVE DC-JSON-BUFFER-IN(WS-END-POS:1) TO WS-CHAR
               IF (WS-CHAR >= "0" AND <= "9") OR WS-CHAR = "-"
                   ADD 1 TO WS-END-POS
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM
           COMPUTE WS-NUMBER-LENGTH = WS-END-POS - WS-VALUE-POS
           IF WS-NUMBER-LENGTH = 0 OR > 64
               PERFORM NUMBER-TYPE-ERROR
               GOBACK
           END-IF
           MOVE DC-JSON-BUFFER-IN(WS-VALUE-POS:WS-NUMBER-LENGTH)
               TO WS-NUMBER-TEXT(1:WS-NUMBER-LENGTH)
           COMPUTE DC-JSON-OUT-NUMBER = FUNCTION NUMVAL(WS-NUMBER-TEXT)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       NUMBER-TYPE-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_TYPE" TO DC-ERROR-CODE
           MOVE "JSON value is not an integer." TO DC-ERROR-MESSAGE.
       END PROGRAM DC-JSON-GET-NUMBER.
