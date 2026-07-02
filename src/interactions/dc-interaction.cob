       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-GET-OPTION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FOUND-FLAG PIC 9.

       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       01 DC-OPTION-NAME-IN PIC X(64).
       01 DC-OPTION-VALUE-OUT PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION
           DC-OPTION-NAME-IN
           DC-OPTION-VALUE-OUT
           DC-RESULT.
       MAIN.
           *> JP: Slash command option は parse 時に固定長テーブルへ平坦化されており、
           *> JP: ここではその小さな表を前から線形探索するだけです。
           *> EN: Slash command options are flattened into a fixed-size table
           *> EN: during parsing, so this helper only performs a small linear scan.
           *>
           *> JP: option 不在は空文字ではなく NOT-FOUND として返し、
           *> JP: handler 側で必須/任意の扱いを分けられるようにしています。
           *> EN: Missing options return NOT-FOUND rather than an empty string so
           *> EN: handlers can distinguish required vs optional behavior.
           MOVE SPACES TO DC-OPTION-VALUE-OUT
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-COMMAND-OPTION-COUNT
                  OR WS-FOUND-FLAG = 1
               IF FUNCTION TRIM(DC-COMMAND-OPTION-NAME(WS-IDX))
                   = FUNCTION TRIM(DC-OPTION-NAME-IN)
                   MOVE DC-COMMAND-OPTION-VALUE(WS-IDX)
                       TO DC-OPTION-VALUE-OUT
                   MOVE 1 TO WS-FOUND-FLAG
               END-IF
           END-PERFORM
           IF WS-FOUND-FLAG = 1
               CALL "DC-RESULT-OK" USING DC-RESULT
           ELSE
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_OPTION" TO DC-ERROR-CODE
               MOVE "Interaction option was not found."
                   TO DC-ERROR-MESSAGE
           END-IF
           GOBACK.
       END PROGRAM DC-INTERACTION-GET-OPTION.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-GET-VALUE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FOUND-FLAG PIC 9.

       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       01 DC-VALUE-NAME-IN PIC X(128).
       01 DC-VALUE-OUT PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION
           DC-VALUE-NAME-IN
           DC-VALUE-OUT
           DC-RESULT.
       MAIN.
           *> JP: select menu / modal input の値も同じく平坦テーブル化されているため、
           *> JP: custom_id などのキーで直接 lookup できます。
           *> EN: Select-menu and modal-input values are flattened the same way,
           *> EN: allowing direct lookup by keys such as custom_id.
           *>
           *> JP: command option helper と API 形をそろえ、interaction 種別ごとの
           *> JP: 呼び分け以外は contributor が迷わないようにしています。
           *> EN: The API shape mirrors the command-option helper so contributors
           *> EN: only need to care about which interaction bucket they are reading.
           MOVE SPACES TO DC-VALUE-OUT
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-INTERACTION-VALUE-COUNT
                  OR WS-FOUND-FLAG = 1
               IF FUNCTION TRIM(DC-INTERACTION-VALUE-NAME(WS-IDX))
                   = FUNCTION TRIM(DC-VALUE-NAME-IN)
                   MOVE DC-INTERACTION-VALUE-TEXT(WS-IDX)
                       TO DC-VALUE-OUT
                   MOVE 1 TO WS-FOUND-FLAG
               END-IF
           END-PERFORM
           IF WS-FOUND-FLAG = 1
               CALL "DC-RESULT-OK" USING DC-RESULT
           ELSE
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_VALUE" TO DC-ERROR-CODE
               MOVE "Interaction value was not found."
                   TO DC-ERROR-MESSAGE
           END-IF
           GOBACK.
       END PROGRAM DC-INTERACTION-GET-VALUE.
