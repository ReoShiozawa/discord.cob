       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-VALIDATE.
       *> JP: JSON 文字列の妥当性確認を担う入口です。
       *> JP: 深い意味解釈より先に「読み進めてよい形か」を判断する土台になります。
       *> EN: Entry point responsible for validating JSON text.
       *> EN: It provides the foundation that answers whether the input is safe to parse further.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(5) COMP-5.
       01 WS-CHAR PIC X.

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-JSON-BUFFER-IN DC-RESULT.
       MAIN.
           MOVE 1 TO WS-IDX
           PERFORM UNTIL WS-IDX > 8192
               OR DC-JSON-BUFFER-IN(WS-IDX:1) NOT = SPACE
               ADD 1 TO WS-IDX
           END-PERFORM

           IF WS-IDX > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_PARSE" TO DC-ERROR-CODE
               MOVE "JSON buffer is empty." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-JSON-BUFFER-IN(WS-IDX:1) TO WS-CHAR
           IF WS-CHAR = "{" OR WS-CHAR = "["
               CALL "DC-RESULT-OK" USING DC-RESULT
           ELSE
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_PARSE" TO DC-ERROR-CODE
               MOVE "JSON must start with an object or array."
                   TO DC-ERROR-MESSAGE
           END-IF
           GOBACK.
       END PROGRAM DC-JSON-VALIDATE.
