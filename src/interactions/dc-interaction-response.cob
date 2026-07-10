       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ESCAPE-TEXT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TEXT-IN PIC X(2000).
       01 WS-IN-LEN PIC 9(5) COMP-5.
       01 WS-IDX PIC 9(5) COMP-5.
       01 WS-OUT-POS PIC 9(5) COMP-5.
       01 WS-CHAR PIC X.

       LINKAGE SECTION.
       01 DC-TEXT-IN PIC X(2000).
       01 DC-TEXT-OUT PIC X(4096).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TEXT-IN
           DC-TEXT-OUT
           DC-RESULT.
       MAIN.
      *> JP: reply content に混ざる quote や改行を JSON 文字列向けに逃がします。
      *> EN: Escape quotes, backslashes, and control characters for JSON string output.
           MOVE SPACES TO DC-TEXT-OUT
           MOVE FUNCTION TRIM(DC-TEXT-IN) TO WS-TEXT-IN
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-TEXT-IN TRAILING))
               TO WS-IN-LEN
           MOVE 1 TO WS-OUT-POS
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-IN-LEN
               MOVE WS-TEXT-IN(WS-IDX:1) TO WS-CHAR
               EVALUATE WS-CHAR
                   WHEN QUOTE
                       STRING
                           "\" DELIMITED BY SIZE
                           QUOTE DELIMITED BY SIZE
                           INTO DC-TEXT-OUT
                           WITH POINTER WS-OUT-POS
                       END-STRING
                   WHEN "\"
                       STRING
                           "\" DELIMITED BY SIZE
                           "\" DELIMITED BY SIZE
                           INTO DC-TEXT-OUT
                           WITH POINTER WS-OUT-POS
                       END-STRING
                   WHEN X"0A"
                       STRING
                           "\" DELIMITED BY SIZE
                           "n" DELIMITED BY SIZE
                           INTO DC-TEXT-OUT
                           WITH POINTER WS-OUT-POS
                       END-STRING
                   WHEN X"0D"
                       STRING
                           "\" DELIMITED BY SIZE
                           "r" DELIMITED BY SIZE
                           INTO DC-TEXT-OUT
                           WITH POINTER WS-OUT-POS
                       END-STRING
                   WHEN X"09"
                       STRING
                           "\" DELIMITED BY SIZE
                           "t" DELIMITED BY SIZE
                           INTO DC-TEXT-OUT
                           WITH POINTER WS-OUT-POS
                       END-STRING
                   WHEN OTHER
                       MOVE WS-CHAR TO DC-TEXT-OUT(WS-OUT-POS:1)
                       ADD 1 TO WS-OUT-POS
               END-EVALUATE
           END-PERFORM
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ESCAPE-TEXT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-REPLY.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ESCAPED-CONTENT PIC X(4096).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-REPLY-CONTENT PIC X(2000).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-REPLY-CONTENT
           DC-REPLY-PAYLOAD
           DC-RESULT.
      MAIN.
      *> JP: Discord callback 用の通常メッセージ(type=4)を組み立てます。
      *> EN: Build a normal Discord callback message payload (type=4).
           MOVE SPACES TO WS-ESCAPED-CONTENT
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-REPLY-CONTENT
                     WS-ESCAPED-CONTENT
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "type" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":4," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "data" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "content" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-CONTENT) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-REPLY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-EPHEMERAL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ESCAPED-CONTENT PIC X(4096).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-REPLY-CONTENT PIC X(2000).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-REPLY-CONTENT
           DC-REPLY-PAYLOAD
           DC-RESULT.
      MAIN.
      *> JP: flags=64 を付けた ephemeral reply を組み立てます。
      *> EN: Build an ephemeral reply by attaching flags=64.
           MOVE SPACES TO WS-ESCAPED-CONTENT
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-REPLY-CONTENT
                     WS-ESCAPED-CONTENT
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "type" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":4," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "data" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "content" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-CONTENT) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "flags" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":64}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-EPHEMERAL.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-DEFERRED.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-DEFERRED-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-DEFERRED-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: すぐ本文を返さず ACK だけ返す deferred response(type=5)です。
      *> EN: Build a deferred response (type=5) that ACKs without message content yet.
           MOVE SPACES TO DC-DEFERRED-PAYLOAD
           MOVE '{"type":5}' TO DC-DEFERRED-PAYLOAD
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-DEFERRED.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-FOLLOWUP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ESCAPED-CONTENT PIC X(4096).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-REPLY-CONTENT PIC X(2000).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-REPLY-CONTENT
           DC-REPLY-PAYLOAD
           DC-RESULT.
      MAIN.
      *> JP: follow-up webhook 用なので callback envelope を持たず content だけを返します。
      *> EN: Follow-up webhooks do not use the callback envelope, so only content is emitted.
           MOVE SPACES TO WS-ESCAPED-CONTENT
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-REPLY-CONTENT
                     WS-ESCAPED-CONTENT
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{"
               QUOTE
               "content"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-CONTENT)
               QUOTE
               "}"
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-FOLLOWUP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-CHOICES-INIT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-interaction-choice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION-CHOICES
           DC-RESULT.
       MAIN.
      *> JP: autocomplete choice table を空に戻す明示的な初期化 helper です。
      *> EN: Explicit initializer that resets the autocomplete choice table.
           INITIALIZE DC-INTERACTION-CHOICES
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-CHOICES-INIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-CHOICES-ADD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-interaction-choice.cpy".
       01 DC-CHOICE-NAME-IN PIC X(100).
       01 DC-CHOICE-VALUE-IN PIC X(100).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION-CHOICES
           DC-CHOICE-NAME-IN
           DC-CHOICE-VALUE-IN
           DC-RESULT.
       MAIN.
      *> JP: autocomplete choice を 1 件追加します。
      *> EN: Append one autocomplete choice entry.
           IF FUNCTION TRIM(DC-CHOICE-NAME-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Autocomplete choice name is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-CHOICE-VALUE-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Autocomplete choice value is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF DC-IA-CHOICE-COUNT >= DC-IA-CHOICES-MAX
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Autocomplete choices exceeded the supported limit."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           ADD 1 TO DC-IA-CHOICE-COUNT
           MOVE DC-CHOICE-NAME-IN
               TO DC-IA-CHOICE-NAME(DC-IA-CHOICE-COUNT)
           MOVE DC-CHOICE-VALUE-IN
               TO DC-IA-CHOICE-VALUE(DC-IA-CHOICE-COUNT)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-CHOICES-ADD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-CHOICES-TO-JSON.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-JSON-POS PIC 9(5) COMP-5.
       01 WS-OVERFLOW-FLAG PIC 9.
       01 WS-ESCAPE-IN PIC X(2000).
       01 WS-ESCAPED-NAME PIC X(4096).
       01 WS-ESCAPED-VALUE PIC X(4096).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       COPY "discord-interaction-choice.cpy".
       01 DC-CHOICES-JSON PIC X(4096).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION-CHOICES
           DC-CHOICES-JSON
           DC-RESULT.
       MAIN.
      *> JP: 構造化した autocomplete choices を安定した JSON 配列へ変換します。
      *> EN: Convert structured autocomplete choices into a stable JSON array.
           MOVE SPACES TO DC-CHOICES-JSON
           MOVE 1 TO WS-JSON-POS
           MOVE 0 TO WS-OVERFLOW-FLAG

           STRING "[" DELIMITED BY SIZE
               INTO DC-CHOICES-JSON
               WITH POINTER WS-JSON-POS
               ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
           END-STRING

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-IA-CHOICE-COUNT
                   OR DC-STATUS-CODE = DC-STATUS-ERROR
               IF WS-IDX > 1
                   STRING "," DELIMITED BY SIZE
                       INTO DC-CHOICES-JSON
                       WITH POINTER WS-JSON-POS
                       ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
                   END-STRING
               END-IF

               MOVE SPACES TO WS-ESCAPE-IN
               MOVE DC-IA-CHOICE-NAME(WS-IDX) TO WS-ESCAPE-IN
               MOVE SPACES TO WS-ESCAPED-NAME
               CALL "DC-INTERACTION-ESCAPE-TEXT"
                   USING WS-ESCAPE-IN
                         WS-ESCAPED-NAME
                         WS-ESCAPE-RESULT
               IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   EXIT PERFORM
               END-IF

               MOVE SPACES TO WS-ESCAPE-IN
               MOVE DC-IA-CHOICE-VALUE(WS-IDX) TO WS-ESCAPE-IN
               MOVE SPACES TO WS-ESCAPED-VALUE
               CALL "DC-INTERACTION-ESCAPE-TEXT"
                   USING WS-ESCAPE-IN
                         WS-ESCAPED-VALUE
                         WS-ESCAPE-RESULT
               IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   EXIT PERFORM
               END-IF

               STRING
                   '{"name":"' DELIMITED BY SIZE
                   FUNCTION TRIM(WS-ESCAPED-NAME) DELIMITED BY SIZE
                   '","value":"' DELIMITED BY SIZE
                   FUNCTION TRIM(WS-ESCAPED-VALUE) DELIMITED BY SIZE
                   '"}' DELIMITED BY SIZE
                   INTO DC-CHOICES-JSON
                   WITH POINTER WS-JSON-POS
                   ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
               END-STRING
           END-PERFORM
           IF DC-STATUS-CODE = DC-STATUS-ERROR
               GOBACK
           END-IF

           STRING "]" DELIMITED BY SIZE
               INTO DC-CHOICES-JSON
               WITH POINTER WS-JSON-POS
               ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
           END-STRING

           IF WS-OVERFLOW-FLAG = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Autocomplete choices JSON exceeded the buffer."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-CHOICES-TO-JSON.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-AUTO.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-CHOICES-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CHOICES-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: raw JSON choices 断片から autocomplete response(type=8)を組み立てます。
      *> EN: Build an autocomplete response (type=8) from a raw JSON choices fragment.
           IF FUNCTION TRIM(DC-CHOICES-JSON) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Autocomplete choices JSON is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               '{"type":8,"data":{"choices":' DELIMITED BY SIZE
               FUNCTION TRIM(DC-CHOICES-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-AUTO.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-BUILD-AUTO.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CHOICES-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-interaction-choice.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION-CHOICES
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: 構造化 choices table から schema-safe な autocomplete payload を作ります。
      *> EN: Build a schema-safe autocomplete payload from the structured choice table.
           MOVE SPACES TO WS-CHOICES-JSON
           CALL "DC-IA-CHOICES-TO-JSON"
               USING DC-INTERACTION-CHOICES
                     WS-CHOICES-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-BUILD-AUTO"
               USING WS-CHOICES-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-BUILD-AUTO.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-BUILD-EMBED.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE-IN PIC X(2000).
       01 WS-ESCAPED-TITLE PIC X(4096).
       01 WS-ESCAPED-DESC PIC X(4096).
       01 WS-COLOR-TEXT PIC Z(10).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-EMBED-TITLE PIC X(128).
       01 DC-EMBED-DESC PIC X(2000).
       01 DC-EMBED-COLOR PIC 9(10) COMP-5.
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-EMBED-TITLE
           DC-EMBED-DESC
           DC-EMBED-COLOR
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: schema-safe な単一 embed reply を組み立てます。
      *> EN: Build a schema-safe single-embed reply payload.
           IF FUNCTION TRIM(DC-EMBED-TITLE) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Embed title is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-EMBED-DESC) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Embed description is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-TITLE-IN
           MOVE FUNCTION TRIM(DC-EMBED-TITLE) TO WS-TITLE-IN
           MOVE SPACES TO WS-ESCAPED-TITLE
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING WS-TITLE-IN
                     WS-ESCAPED-TITLE
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-ESCAPED-DESC
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-EMBED-DESC
                     WS-ESCAPED-DESC
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-EMBED-COLOR TO WS-COLOR-TEXT
           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{"
               QUOTE
               "type"
               QUOTE
               ":4,"
               QUOTE
               "data"
               QUOTE
               ":{"
               QUOTE
               "embeds"
               QUOTE
               ":[{"
               QUOTE
               "title"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-TITLE)
               QUOTE
               ","
               QUOTE
               "description"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-DESC)
               QUOTE
               ","
               QUOTE
               "color"
               QUOTE
               ":"
               FUNCTION TRIM(WS-COLOR-TEXT)
               "}]}}"
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-BUILD-EMBED.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-BUILD-ECOMP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE-IN PIC X(2000).
       01 WS-ESCAPED-TITLE PIC X(4096).
       01 WS-ESCAPED-DESC PIC X(4096).
       01 WS-COLOR-TEXT PIC Z(10).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-EMBED-TITLE PIC X(128).
       01 DC-EMBED-DESC PIC X(2000).
       01 DC-EMBED-COLOR PIC 9(10) COMP-5.
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-EMBED-TITLE
           DC-EMBED-DESC
           DC-EMBED-COLOR
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: 単一 embed と component row をまとめた reply を返します。
      *> EN: Build a reply payload that combines one embed and a component row.
           IF FUNCTION TRIM(DC-COMPONENTS-JSON) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Component JSON is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           CALL "DC-IA-BUILD-EMBED"
               USING DC-EMBED-TITLE
                     DC-EMBED-DESC
                     DC-EMBED-COLOR
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE SPACES TO WS-TITLE-IN
           MOVE FUNCTION TRIM(DC-EMBED-TITLE) TO WS-TITLE-IN
           MOVE SPACES TO WS-ESCAPED-TITLE
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING WS-TITLE-IN
                     WS-ESCAPED-TITLE
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE SPACES TO WS-ESCAPED-DESC
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-EMBED-DESC
                     WS-ESCAPED-DESC
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE DC-EMBED-COLOR TO WS-COLOR-TEXT

           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{"
               QUOTE
               "type"
               QUOTE
               ":4,"
               QUOTE
               "data"
               QUOTE
               ":{"
               QUOTE
               "embeds"
               QUOTE
               ":[{"
               QUOTE
               "title"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-TITLE)
               QUOTE
               ","
               QUOTE
               "description"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-DESC)
               QUOTE
               ","
               QUOTE
               "color"
               QUOTE
               ":"
               FUNCTION TRIM(WS-COLOR-TEXT)
               "}],"
               QUOTE
               "components"
               QUOTE
               ":"
               FUNCTION TRIM(DC-COMPONENTS-JSON)
               "}}"
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-BUILD-ECOMP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-BUILD-UEMB.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE-IN PIC X(2000).
       01 WS-ESCAPED-TITLE PIC X(4096).
       01 WS-ESCAPED-DESC PIC X(4096).
       01 WS-COLOR-TEXT PIC Z(10).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-EMBED-TITLE PIC X(128).
       01 DC-EMBED-DESC PIC X(2000).
       01 DC-EMBED-COLOR PIC 9(10) COMP-5.
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-EMBED-TITLE
           DC-EMBED-DESC
           DC-EMBED-COLOR
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: 既存メッセージを単一 embed で更新する payload を返します。
      *> EN: Build a message-update payload that replaces the current message with one embed.
           IF FUNCTION TRIM(DC-EMBED-TITLE) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Embed title is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-EMBED-DESC) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Embed description is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-TITLE-IN
           MOVE FUNCTION TRIM(DC-EMBED-TITLE) TO WS-TITLE-IN
           MOVE SPACES TO WS-ESCAPED-TITLE
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING WS-TITLE-IN
                     WS-ESCAPED-TITLE
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE SPACES TO WS-ESCAPED-DESC
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-EMBED-DESC
                     WS-ESCAPED-DESC
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE DC-EMBED-COLOR TO WS-COLOR-TEXT

           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{"
               QUOTE
               "type"
               QUOTE
               ":7,"
               QUOTE
               "data"
               QUOTE
               ":{"
               QUOTE
               "embeds"
               QUOTE
               ":[{"
               QUOTE
               "title"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-TITLE)
               QUOTE
               ","
               QUOTE
               "description"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-DESC)
               QUOTE
               ","
               QUOTE
               "color"
               QUOTE
               ":"
               FUNCTION TRIM(WS-COLOR-TEXT)
               "}]}}"
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-BUILD-UEMB.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-BUILD-UECMP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE-IN PIC X(2000).
       01 WS-ESCAPED-TITLE PIC X(4096).
       01 WS-ESCAPED-DESC PIC X(4096).
       01 WS-COLOR-TEXT PIC Z(10).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-EMBED-TITLE PIC X(128).
       01 DC-EMBED-DESC PIC X(2000).
       01 DC-EMBED-COLOR PIC 9(10) COMP-5.
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-EMBED-TITLE
           DC-EMBED-DESC
           DC-EMBED-COLOR
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: 既存メッセージを embed と components ごと更新する payload を返します。
      *> EN: Build a message-update payload that replaces both embeds and components.
           IF FUNCTION TRIM(DC-COMPONENTS-JSON) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Component JSON is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           CALL "DC-IA-BUILD-UEMB"
               USING DC-EMBED-TITLE
                     DC-EMBED-DESC
                     DC-EMBED-COLOR
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE SPACES TO WS-TITLE-IN
           MOVE FUNCTION TRIM(DC-EMBED-TITLE) TO WS-TITLE-IN
           MOVE SPACES TO WS-ESCAPED-TITLE
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING WS-TITLE-IN
                     WS-ESCAPED-TITLE
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE SPACES TO WS-ESCAPED-DESC
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-EMBED-DESC
                     WS-ESCAPED-DESC
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE DC-EMBED-COLOR TO WS-COLOR-TEXT

           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{"
               QUOTE
               "type"
               QUOTE
               ":7,"
               QUOTE
               "data"
               QUOTE
               ":{"
               QUOTE
               "embeds"
               QUOTE
               ":[{"
               QUOTE
               "title"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-TITLE)
               QUOTE
               ","
               QUOTE
               "description"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(WS-ESCAPED-DESC)
               QUOTE
               ","
               QUOTE
               "color"
               QUOTE
               ":"
               FUNCTION TRIM(WS-COLOR-TEXT)
               "}],"
               QUOTE
               "components"
               QUOTE
               ":"
               FUNCTION TRIM(DC-COMPONENTS-JSON)
               "}}"
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-BUILD-UECMP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-UPDATE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ESCAPED-CONTENT PIC X(4096).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-REPLY-CONTENT PIC X(2000).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-REPLY-CONTENT
           DC-REPLY-PAYLOAD
           DC-RESULT.
      MAIN.
      *> JP: 既存メッセージを書き換える component update(type=7) を組み立てます。
      *> EN: Build a component update payload (type=7) that edits the existing message.
           MOVE SPACES TO WS-ESCAPED-CONTENT
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-REPLY-CONTENT
                     WS-ESCAPED-CONTENT
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "type" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":7," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "data" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "content" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-CONTENT) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-UPDATE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IA-BUILD-UPDATE-COMP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ESCAPED-CONTENT PIC X(4096).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-REPLY-CONTENT PIC X(2000).
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-REPLY-CONTENT
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: type=7 update に components 断片も載せ、ボタンの有効/無効をまとめて更新します。
      *> EN: Build a type=7 update that also replaces the component tree.
           IF FUNCTION TRIM(DC-COMPONENTS-JSON) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Component JSON is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-ESCAPED-CONTENT
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-REPLY-CONTENT
                     WS-ESCAPED-CONTENT
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "type" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":7," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "data" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "content" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-CONTENT) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "components" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(DC-COMPONENTS-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IA-BUILD-UPDATE-COMP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-COMPONENT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ESCAPED-CONTENT PIC X(4096).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       01 DC-REPLY-CONTENT PIC X(2000).
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-REPLY-CONTENT
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
      MAIN.
      *> JP: components は高水準構造ではなく raw JSON 断片をそのまま受け取ります。
      *> EN: components are accepted as a raw JSON fragment rather than a higher-level structure.
           IF FUNCTION TRIM(DC-COMPONENTS-JSON) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Component JSON is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-ESCAPED-CONTENT
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING DC-REPLY-CONTENT
                     WS-ESCAPED-CONTENT
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "type" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":4," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "data" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "content" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-CONTENT) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "components" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(DC-COMPONENTS-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-COMPONENT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-MODAL.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-CUSTOM-ID PIC X(128).
       01 DC-TITLE PIC X(128).
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CUSTOM-ID
           DC-TITLE
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: Modal は type=9 で返し、custom_id / title / components をそのまま埋め込みます。
      *> EN: Modals are returned as type=9 with custom_id, title, and components embedded.
           IF FUNCTION TRIM(DC-CUSTOM-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Modal custom id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-TITLE) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Modal title is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-COMPONENTS-JSON) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Modal components JSON is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "type" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":9," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "data" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "custom_id" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-CUSTOM-ID) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "title" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-TITLE) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "components" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(DC-COMPONENTS-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-MODAL.
