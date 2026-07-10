       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-SCAN.
       *> JP: JSON を検証しながら、位置・長さ・深さを持つ token 列へ分解します。
       *> JP: DOM を作らず、path reader が構造を正確に辿れる情報だけを保持します。
       *> EN: Validates JSON while producing tokens with position, length, and depth.
       *> EN: This keeps enough structure for exact path traversal without building a DOM.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-LENGTH PIC 9(5) COMP-5.
       01 WS-POS PIC 9(5) COMP-5.
       01 WS-START PIC 9(5) COMP-5.
       01 WS-TOKEN-LENGTH PIC 9(5) COMP-5.
       01 WS-DEPTH PIC 9(3) COMP-5.
       01 WS-KIND PIC 9(2) COMP-5.
       01 WS-CHAR PIC X.
       01 WS-NEXT PIC X.
       01 WS-STACK-COUNT PIC 9(3) COMP-5.
       01 WS-STACK OCCURS 128 TIMES PIC X.
       01 WS-DIGIT-COUNT PIC 9(5) COMP-5.
       01 WS-DONE PIC 9.
       01 WS-TOKEN-INDEX PIC 9(5) COMP-5.
       01 WS-ROOT-DONE PIC 9.
       01 WS-SYNTAX-STATE OCCURS 128 TIMES PIC 9.

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       COPY "discord-json.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-BUFFER-IN
           DC-JSON-TOKENS
           DC-RESULT.
       MAIN.
           INITIALIZE DC-JSON-TOKENS
           CALL "DC-RESULT-OK" USING DC-RESULT
           MOVE 8192 TO WS-LENGTH
           PERFORM UNTIL WS-LENGTH = 0
               OR DC-JSON-BUFFER-IN(WS-LENGTH:1) NOT = SPACE
               SUBTRACT 1 FROM WS-LENGTH
           END-PERFORM
           IF WS-LENGTH = 0
               PERFORM JSON-EMPTY-ERROR
               GOBACK
           END-IF

           MOVE 1 TO WS-POS
           MOVE 0 TO WS-DEPTH WS-STACK-COUNT
           PERFORM UNTIL WS-POS > WS-LENGTH
               MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-CHAR
               EVALUATE TRUE
                   WHEN WS-CHAR = SPACE OR X"09" OR X"0A" OR X"0D"
                       ADD 1 TO WS-POS
                   WHEN WS-CHAR = "{"
                       MOVE DC-JT-OBJECT-START TO WS-KIND
                       MOVE 1 TO WS-TOKEN-LENGTH
                       PERFORM EMIT-TOKEN
                       PERFORM PUSH-OBJECT
                       ADD 1 TO WS-POS
                   WHEN WS-CHAR = "["
                       MOVE DC-JT-ARRAY-START TO WS-KIND
                       MOVE 1 TO WS-TOKEN-LENGTH
                       PERFORM EMIT-TOKEN
                       PERFORM PUSH-ARRAY
                       ADD 1 TO WS-POS
                   WHEN WS-CHAR = "}"
                       IF WS-STACK-COUNT = 0
                          OR WS-STACK(WS-STACK-COUNT) NOT = "{"
                           PERFORM JSON-STRUCTURE-ERROR
                           GOBACK
                       END-IF
                       SUBTRACT 1 FROM WS-DEPTH WS-STACK-COUNT
                       MOVE DC-JT-OBJECT-END TO WS-KIND
                       MOVE 1 TO WS-TOKEN-LENGTH
                       PERFORM EMIT-TOKEN
                       ADD 1 TO WS-POS
                   WHEN WS-CHAR = "]"
                       IF WS-STACK-COUNT = 0
                          OR WS-STACK(WS-STACK-COUNT) NOT = "["
                           PERFORM JSON-STRUCTURE-ERROR
                           GOBACK
                       END-IF
                       SUBTRACT 1 FROM WS-DEPTH WS-STACK-COUNT
                       MOVE DC-JT-ARRAY-END TO WS-KIND
                       MOVE 1 TO WS-TOKEN-LENGTH
                       PERFORM EMIT-TOKEN
                       ADD 1 TO WS-POS
                   WHEN WS-CHAR = ":"
                       MOVE DC-JT-COLON TO WS-KIND
                       MOVE 1 TO WS-TOKEN-LENGTH
                       PERFORM EMIT-TOKEN
                       ADD 1 TO WS-POS
                   WHEN WS-CHAR = ","
                       MOVE DC-JT-COMMA TO WS-KIND
                       MOVE 1 TO WS-TOKEN-LENGTH
                       PERFORM EMIT-TOKEN
                       ADD 1 TO WS-POS
                   WHEN WS-CHAR = QUOTE
                       PERFORM SCAN-STRING
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                   WHEN WS-CHAR = "-" OR (WS-CHAR >= "0" AND <= "9")
                       PERFORM SCAN-NUMBER
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                   WHEN OTHER
                       PERFORM SCAN-LITERAL
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
               END-EVALUATE
               IF DC-JT-COUNT > DC-JSON-MAX-TOKENS
                   PERFORM JSON-TOKEN-LIMIT-ERROR
                   GOBACK
               END-IF
           END-PERFORM

           IF WS-STACK-COUNT NOT = 0
               PERFORM JSON-STRUCTURE-ERROR
               GOBACK
           END-IF
           IF DC-JT-COUNT = 0
               PERFORM JSON-EMPTY-ERROR
               GOBACK
           END-IF
           IF DC-JT-KIND(1) NOT = DC-JT-OBJECT-START
              AND DC-JT-KIND(1) NOT = DC-JT-ARRAY-START
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_PARSE" TO DC-ERROR-CODE
               MOVE "JSON root must be an object or array."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           PERFORM VALIDATE-TOKEN-SEQUENCE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       VALIDATE-TOKEN-SEQUENCE.
           MOVE 0 TO WS-STACK-COUNT WS-ROOT-DONE
           PERFORM VARYING WS-TOKEN-INDEX FROM 1 BY 1
               UNTIL WS-TOKEN-INDEX > DC-JT-COUNT
               IF WS-ROOT-DONE = 1
                   PERFORM JSON-SYNTAX-ERROR
                   EXIT PARAGRAPH
               END-IF
               IF WS-STACK-COUNT = 0
                   PERFORM SYNTAX-PUSH-CONTAINER
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       EXIT PARAGRAPH
                   END-IF
               ELSE
                   IF WS-STACK(WS-STACK-COUNT) = "{"
                       PERFORM VALIDATE-OBJECT-TOKEN
                   ELSE
                       PERFORM VALIDATE-ARRAY-TOKEN
                   END-IF
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       EXIT PARAGRAPH
                   END-IF
               END-IF
           END-PERFORM
           IF WS-STACK-COUNT NOT = 0 OR WS-ROOT-DONE NOT = 1
               PERFORM JSON-SYNTAX-ERROR
               EXIT PARAGRAPH
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       VALIDATE-OBJECT-TOKEN.
           EVALUATE WS-SYNTAX-STATE(WS-STACK-COUNT)
               WHEN 0
                   IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-OBJECT-END
                       PERFORM SYNTAX-POP-CONTAINER
                   ELSE
                       IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-STRING
                           MOVE 1 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
                       ELSE
                           PERFORM JSON-SYNTAX-ERROR
                       END-IF
                   END-IF
               WHEN 1
                   IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-COLON
                       MOVE 2 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
                   ELSE
                       PERFORM JSON-SYNTAX-ERROR
                   END-IF
               WHEN 2
                   PERFORM SYNTAX-CONSUME-VALUE
               WHEN 3
                   IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-COMMA
                       MOVE 4 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
                   ELSE
                       IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-OBJECT-END
                           PERFORM SYNTAX-POP-CONTAINER
                       ELSE
                           PERFORM JSON-SYNTAX-ERROR
                       END-IF
                   END-IF
               WHEN 4
                   IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-STRING
                       MOVE 1 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
                   ELSE
                       PERFORM JSON-SYNTAX-ERROR
                   END-IF
           END-EVALUATE.

       VALIDATE-ARRAY-TOKEN.
           EVALUATE WS-SYNTAX-STATE(WS-STACK-COUNT)
               WHEN 0
                   IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-ARRAY-END
                       PERFORM SYNTAX-POP-CONTAINER
                   ELSE
                       PERFORM SYNTAX-CONSUME-VALUE
                   END-IF
               WHEN 3
                   IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-COMMA
                       MOVE 4 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
                   ELSE
                       IF DC-JT-KIND(WS-TOKEN-INDEX) = DC-JT-ARRAY-END
                           PERFORM SYNTAX-POP-CONTAINER
                       ELSE
                           PERFORM JSON-SYNTAX-ERROR
                       END-IF
                   END-IF
               WHEN 4
                   PERFORM SYNTAX-CONSUME-VALUE
               WHEN OTHER
                   PERFORM JSON-SYNTAX-ERROR
           END-EVALUATE.

       SYNTAX-CONSUME-VALUE.
           EVALUATE DC-JT-KIND(WS-TOKEN-INDEX)
               WHEN DC-JT-OBJECT-START
                   MOVE 2 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
                   PERFORM SYNTAX-PUSH-CONTAINER
               WHEN DC-JT-ARRAY-START
                   MOVE 2 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
                   PERFORM SYNTAX-PUSH-CONTAINER
               WHEN DC-JT-STRING
                   MOVE 3 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
               WHEN DC-JT-NUMBER
                   MOVE 3 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
               WHEN DC-JT-TRUE
                   MOVE 3 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
               WHEN DC-JT-FALSE
                   MOVE 3 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
               WHEN DC-JT-NULL
                   MOVE 3 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
               WHEN OTHER
                   PERFORM JSON-SYNTAX-ERROR
           END-EVALUATE.

       SYNTAX-PUSH-CONTAINER.
           IF WS-STACK-COUNT >= 128
               PERFORM JSON-DEPTH-ERROR
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-STACK-COUNT
           EVALUATE DC-JT-KIND(WS-TOKEN-INDEX)
               WHEN DC-JT-OBJECT-START
                   MOVE "{" TO WS-STACK(WS-STACK-COUNT)
               WHEN DC-JT-ARRAY-START
                   MOVE "[" TO WS-STACK(WS-STACK-COUNT)
               WHEN OTHER
                   PERFORM JSON-SYNTAX-ERROR
                   EXIT PARAGRAPH
           END-EVALUATE
           MOVE 0 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
           CALL "DC-RESULT-OK" USING DC-RESULT.

       SYNTAX-POP-CONTAINER.
           SUBTRACT 1 FROM WS-STACK-COUNT
           IF WS-STACK-COUNT = 0
               MOVE 1 TO WS-ROOT-DONE
           ELSE
               IF WS-SYNTAX-STATE(WS-STACK-COUNT) NOT = 2
                  AND WS-SYNTAX-STATE(WS-STACK-COUNT) NOT = 4
                   PERFORM JSON-SYNTAX-ERROR
                   EXIT PARAGRAPH
               END-IF
               MOVE 3 TO WS-SYNTAX-STATE(WS-STACK-COUNT)
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       PUSH-OBJECT.
           IF WS-STACK-COUNT >= 128
               PERFORM JSON-DEPTH-ERROR
               GOBACK
           END-IF
           ADD 1 TO WS-STACK-COUNT WS-DEPTH
           MOVE "{" TO WS-STACK(WS-STACK-COUNT).

       PUSH-ARRAY.
           IF WS-STACK-COUNT >= 128
               PERFORM JSON-DEPTH-ERROR
               GOBACK
           END-IF
           ADD 1 TO WS-STACK-COUNT WS-DEPTH
           MOVE "[" TO WS-STACK(WS-STACK-COUNT).

       SCAN-STRING.
           MOVE WS-POS TO WS-START
           ADD 1 TO WS-POS
           MOVE 0 TO WS-DONE
           PERFORM UNTIL WS-POS > WS-LENGTH OR WS-DONE = 1
               MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-CHAR
               IF WS-CHAR = QUOTE
                   ADD 1 TO WS-POS
                   MOVE 1 TO WS-DONE
               ELSE
                   IF WS-CHAR = X"5C"
                       ADD 1 TO WS-POS
                       IF WS-POS > WS-LENGTH
                           PERFORM JSON-STRING-ERROR
                           EXIT PERFORM
                       END-IF
                       MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-NEXT
                       IF WS-NEXT = "u"
                           PERFORM VALIDATE-UNICODE-ESCAPE
                       ELSE
                           IF WS-NEXT NOT = QUOTE
                              AND WS-NEXT NOT = X"5C"
                              AND WS-NEXT NOT = "/"
                              AND WS-NEXT NOT = "b"
                              AND WS-NEXT NOT = "f"
                              AND WS-NEXT NOT = "n"
                              AND WS-NEXT NOT = "r"
                              AND WS-NEXT NOT = "t"
                               PERFORM JSON-STRING-ERROR
                               EXIT PERFORM
                           END-IF
                           ADD 1 TO WS-POS
                       END-IF
                   ELSE
                       IF FUNCTION ORD(WS-CHAR) < 33
                           PERFORM JSON-STRING-ERROR
                           EXIT PERFORM
                       END-IF
                       ADD 1 TO WS-POS
                   END-IF
               END-IF
           END-PERFORM
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-DONE = 0
               PERFORM JSON-STRING-ERROR
               EXIT PARAGRAPH
           END-IF
           COMPUTE WS-TOKEN-LENGTH = WS-POS - WS-START
           MOVE WS-START TO WS-POS
           MOVE DC-JT-STRING TO WS-KIND
           PERFORM EMIT-TOKEN
           ADD WS-TOKEN-LENGTH TO WS-POS
           CALL "DC-RESULT-OK" USING DC-RESULT.

       VALIDATE-UNICODE-ESCAPE.
           ADD 1 TO WS-POS
           PERFORM VARYING WS-DIGIT-COUNT FROM 1 BY 1
               UNTIL WS-DIGIT-COUNT > 4
               IF WS-POS > WS-LENGTH
                   PERFORM JSON-STRING-ERROR
                   EXIT PERFORM
               END-IF
               MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-NEXT
               IF NOT (WS-NEXT >= "0" AND <= "9")
                  AND NOT (WS-NEXT >= "A" AND <= "F")
                  AND NOT (WS-NEXT >= "a" AND <= "f")
                   PERFORM JSON-STRING-ERROR
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-POS
           END-PERFORM.

       SCAN-NUMBER.
           MOVE WS-POS TO WS-START
           IF WS-CHAR = "-"
               ADD 1 TO WS-POS
               IF WS-POS > WS-LENGTH
                   PERFORM JSON-NUMBER-ERROR
                   EXIT PARAGRAPH
               END-IF
           END-IF
           MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-CHAR
           IF WS-CHAR = "0"
               ADD 1 TO WS-POS
           ELSE
               IF WS-CHAR < "1" OR > "9"
                   PERFORM JSON-NUMBER-ERROR
                   EXIT PARAGRAPH
               END-IF
               PERFORM UNTIL WS-POS > WS-LENGTH
                   MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-CHAR
                   IF WS-CHAR >= "0" AND <= "9"
                       ADD 1 TO WS-POS
                   ELSE
                       EXIT PERFORM
                   END-IF
               END-PERFORM
           END-IF
           IF WS-POS <= WS-LENGTH
               AND DC-JSON-BUFFER-IN(WS-POS:1) = "."
               ADD 1 TO WS-POS
               MOVE 0 TO WS-DIGIT-COUNT
               PERFORM UNTIL WS-POS > WS-LENGTH
                   MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-CHAR
                   IF WS-CHAR >= "0" AND <= "9"
                       ADD 1 TO WS-DIGIT-COUNT WS-POS
                   ELSE
                       EXIT PERFORM
                   END-IF
               END-PERFORM
               IF WS-DIGIT-COUNT = 0
                   PERFORM JSON-NUMBER-ERROR
                   EXIT PARAGRAPH
               END-IF
           END-IF
           IF WS-POS <= WS-LENGTH
              AND (DC-JSON-BUFFER-IN(WS-POS:1) = "e"
              OR DC-JSON-BUFFER-IN(WS-POS:1) = "E")
               ADD 1 TO WS-POS
               IF WS-POS <= WS-LENGTH
                  AND (DC-JSON-BUFFER-IN(WS-POS:1) = "+"
                  OR DC-JSON-BUFFER-IN(WS-POS:1) = "-")
                   ADD 1 TO WS-POS
               END-IF
               MOVE 0 TO WS-DIGIT-COUNT
               PERFORM UNTIL WS-POS > WS-LENGTH
                   MOVE DC-JSON-BUFFER-IN(WS-POS:1) TO WS-CHAR
                   IF WS-CHAR >= "0" AND <= "9"
                       ADD 1 TO WS-DIGIT-COUNT WS-POS
                   ELSE
                       EXIT PERFORM
                   END-IF
               END-PERFORM
               IF WS-DIGIT-COUNT = 0
                   PERFORM JSON-NUMBER-ERROR
                   EXIT PARAGRAPH
               END-IF
           END-IF
           COMPUTE WS-TOKEN-LENGTH = WS-POS - WS-START
           MOVE WS-START TO WS-POS
           MOVE DC-JT-NUMBER TO WS-KIND
           PERFORM EMIT-TOKEN
           ADD WS-TOKEN-LENGTH TO WS-POS
           CALL "DC-RESULT-OK" USING DC-RESULT.

       SCAN-LITERAL.
           MOVE WS-POS TO WS-START
           EVALUATE TRUE
               WHEN WS-POS + 3 <= WS-LENGTH
                  AND DC-JSON-BUFFER-IN(WS-POS:4) = "true"
                   MOVE DC-JT-TRUE TO WS-KIND
                   MOVE 4 TO WS-TOKEN-LENGTH
               WHEN WS-POS + 4 <= WS-LENGTH
                  AND DC-JSON-BUFFER-IN(WS-POS:5) = "false"
                   MOVE DC-JT-FALSE TO WS-KIND
                   MOVE 5 TO WS-TOKEN-LENGTH
               WHEN WS-POS + 3 <= WS-LENGTH
                  AND DC-JSON-BUFFER-IN(WS-POS:4) = "null"
                   MOVE DC-JT-NULL TO WS-KIND
                   MOVE 4 TO WS-TOKEN-LENGTH
               WHEN OTHER
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_JSON_TOKEN" TO DC-ERROR-CODE
                   MOVE "Unexpected character in JSON input."
                       TO DC-ERROR-MESSAGE
                   EXIT PARAGRAPH
           END-EVALUATE
           PERFORM EMIT-TOKEN
           ADD WS-TOKEN-LENGTH TO WS-POS
           CALL "DC-RESULT-OK" USING DC-RESULT.

       EMIT-TOKEN.
           IF DC-JT-COUNT >= DC-JSON-MAX-TOKENS
               ADD 1 TO DC-JT-COUNT
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO DC-JT-COUNT
           MOVE WS-KIND TO DC-JT-KIND(DC-JT-COUNT)
           MOVE WS-POS TO DC-JT-START(DC-JT-COUNT)
           MOVE WS-TOKEN-LENGTH TO DC-JT-LENGTH(DC-JT-COUNT)
           MOVE WS-DEPTH TO DC-JT-DEPTH(DC-JT-COUNT).

       JSON-EMPTY-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_PARSE" TO DC-ERROR-CODE
           MOVE "JSON buffer is empty." TO DC-ERROR-MESSAGE.
       JSON-STRUCTURE-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_STRUCTURE" TO DC-ERROR-CODE
           MOVE "JSON object or array delimiters are unbalanced."
               TO DC-ERROR-MESSAGE.
       JSON-DEPTH-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_DEPTH" TO DC-ERROR-CODE
           MOVE "JSON nesting exceeds 128 levels." TO DC-ERROR-MESSAGE.
       JSON-TOKEN-LIMIT-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_TOKEN_LIMIT" TO DC-ERROR-CODE
           MOVE "JSON input exceeds the 1024 token limit."
               TO DC-ERROR-MESSAGE.
       JSON-STRING-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_STRING" TO DC-ERROR-CODE
           MOVE "JSON string contains an invalid escape or terminator."
               TO DC-ERROR-MESSAGE.
       JSON-NUMBER-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_NUMBER" TO DC-ERROR-CODE
           MOVE "JSON number has invalid syntax." TO DC-ERROR-MESSAGE.
       JSON-SYNTAX-ERROR.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_JSON_SYNTAX" TO DC-ERROR-CODE
           MOVE "JSON token sequence does not follow JSON grammar."
               TO DC-ERROR-MESSAGE.
       END PROGRAM DC-JSON-SCAN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-TOKENIZE.
       *> JP: 既存 API の token count 契約を保つ scanner wrapper です。
       *> EN: Scanner wrapper that preserves the original token-count API.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-json.cpy".
       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       01 DC-JSON-TOKEN-COUNT PIC 9(5) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-BUFFER-IN
           DC-JSON-TOKEN-COUNT
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-JSON-TOKEN-COUNT
           CALL "DC-JSON-SCAN"
               USING DC-JSON-BUFFER-IN DC-JSON-TOKENS DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-OK
               MOVE DC-JT-COUNT TO DC-JSON-TOKEN-COUNT
           END-IF
           GOBACK.
       END PROGRAM DC-JSON-TOKENIZE.
