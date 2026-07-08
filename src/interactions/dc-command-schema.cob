       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-COMMAND-SCHEMA-INIT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-command-schema.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-COMMAND-SCHEMA
           DC-RESULT.
       MAIN.
           *> JP: schema を空の状態へ戻す明示的な初期化 helper です。
           *> JP: add 系 helper はこの初期化済み構造を前提に追記していきます。
           *> EN: Explicit initializer that resets the schema to an empty state.
           *> EN: The add helpers append on top of this initialized structure.
           INITIALIZE DC-COMMAND-SCHEMA
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-COMMAND-SCHEMA-INIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-COMMAND-SCHEMA-ADD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-command-schema.cpy".
       01 DC-SCHEMA-NAME-IN PIC X(32).
       01 DC-SCHEMA-DESC-IN PIC X(100).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-COMMAND-SCHEMA
           DC-SCHEMA-NAME-IN
           DC-SCHEMA-DESC-IN
           DC-RESULT.
       MAIN.
           *> JP: name/description を持つ chat-input command を 1 件追記します。
           *> JP: type は Discord の CHAT_INPUT (1) に固定し、option は後から
           *> JP: DC-COMMAND-SCHEMA-ADD-OPTION で直前の command に足します。
           *> EN: Append one chat-input command with a name and description.
           *> EN: The type is pinned to Discord's CHAT_INPUT (1); options are added
           *> EN: to the most recent command via DC-COMMAND-SCHEMA-ADD-OPTION.
           IF FUNCTION TRIM(DC-SCHEMA-NAME-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Slash command name is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-SCHEMA-DESC-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Slash command description is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF DC-SCHEMA-COMMAND-COUNT >= DC-SCHEMA-MAX-COMMANDS
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema cannot hold more commands."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           ADD 1 TO DC-SCHEMA-COMMAND-COUNT
           MOVE DC-SCHEMA-NAME-IN
               TO DC-SCHEMA-COMMAND-NAME(DC-SCHEMA-COMMAND-COUNT)
           MOVE 1 TO DC-SCHEMA-COMMAND-TYPE(DC-SCHEMA-COMMAND-COUNT)
           MOVE DC-SCHEMA-DESC-IN
               TO DC-SCHEMA-COMMAND-DESC(DC-SCHEMA-COMMAND-COUNT)
           MOVE 0 TO DC-SCHEMA-OPTION-COUNT(DC-SCHEMA-COMMAND-COUNT)

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-COMMAND-SCHEMA-ADD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-COMMAND-SCHEMA-ADD-OPTION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMMAND-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       COPY "discord-command-schema.cpy".
       01 DC-SCHEMA-NAME-IN PIC X(32).
       01 DC-SCHEMA-TYPE-IN PIC 9(4) COMP-5.
       01 DC-SCHEMA-DESC-IN PIC X(100).
       01 DC-SCHEMA-REQUIRED-IN PIC 9(4) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-COMMAND-SCHEMA
           DC-SCHEMA-NAME-IN
           DC-SCHEMA-TYPE-IN
           DC-SCHEMA-DESC-IN
           DC-SCHEMA-REQUIRED-IN
           DC-RESULT.
       MAIN.
           *> JP: 直前に追加した command へ option を 1 件追記します。
           *> JP: type は Discord の option type (3=string, 4=integer など) を
           *> JP: そのまま受け取り、required は 0/1 で指定します。
           *> EN: Append one option to the most recently added command.
           *> EN: The type takes Discord option types directly (3=string,
           *> EN: 4=integer, ...) and required is passed as 0 or 1.
           IF DC-SCHEMA-COMMAND-COUNT = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Add a command before adding options."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-SCHEMA-NAME-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Slash command option name is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-SCHEMA-DESC-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Slash command option description is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF DC-SCHEMA-TYPE-IN < 1 OR DC-SCHEMA-TYPE-IN > 11
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Slash command option type is not supported."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-SCHEMA-COMMAND-COUNT TO WS-COMMAND-IDX
           IF DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX)
               >= DC-SCHEMA-MAX-OPTIONS
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema cannot hold more options."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           ADD 1 TO DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX)
           MOVE DC-SCHEMA-NAME-IN
               TO DC-SCHEMA-OPTION-NAME(WS-COMMAND-IDX,
                   DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX))
           MOVE DC-SCHEMA-TYPE-IN
               TO DC-SCHEMA-OPTION-TYPE(WS-COMMAND-IDX,
                   DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX))
           MOVE DC-SCHEMA-DESC-IN
               TO DC-SCHEMA-OPTION-DESC(WS-COMMAND-IDX,
                   DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX))
           IF DC-SCHEMA-REQUIRED-IN = 0
               MOVE 0 TO DC-SCHEMA-OPTION-REQUIRED(WS-COMMAND-IDX,
                   DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX))
           ELSE
               MOVE 1 TO DC-SCHEMA-OPTION-REQUIRED(WS-COMMAND-IDX,
                   DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX))
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-COMMAND-SCHEMA-ADD-OPTION.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-COMMAND-SCHEMA-VALIDATE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMMAND-IDX PIC 9(4) COMP-5.
       01 WS-OPTION-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       COPY "discord-command-schema.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-COMMAND-SCHEMA
           DC-RESULT.
       MAIN.
           *> JP: JSON 変換や同期の前に schema 全体の整合性を検証します。
           *> JP: 空の schema、blank な name/description、小文字でない name、
           *> JP: 範囲外の type をここでまとめて弾きます。
           *> EN: Validate the whole schema before JSON conversion or sync.
           *> EN: Empty schemas, blank names/descriptions, non-lowercase names,
           *> EN: and out-of-range types are all rejected here.
           MOVE DC-STATUS-OK TO DC-STATUS-CODE
           IF DC-SCHEMA-COMMAND-COUNT = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema must declare at least one command."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF DC-SCHEMA-COMMAND-COUNT > DC-SCHEMA-MAX-COMMANDS
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema declares too many commands."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VALIDATE-COMMAND
               VARYING WS-COMMAND-IDX FROM 1 BY 1
               UNTIL WS-COMMAND-IDX > DC-SCHEMA-COMMAND-COUNT
                   OR DC-STATUS-CODE = DC-STATUS-ERROR
           IF DC-STATUS-CODE = DC-STATUS-ERROR
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       VALIDATE-COMMAND.
           IF FUNCTION TRIM(DC-SCHEMA-COMMAND-NAME(WS-COMMAND-IDX))
               = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema entry is missing a name."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           IF DC-SCHEMA-COMMAND-NAME(WS-COMMAND-IDX) NOT =
               FUNCTION LOWER-CASE(
                   DC-SCHEMA-COMMAND-NAME(WS-COMMAND-IDX))
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema names must be lowercase."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           IF FUNCTION TRIM(DC-SCHEMA-COMMAND-DESC(WS-COMMAND-IDX))
               = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema entry is missing a description."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           IF DC-SCHEMA-COMMAND-TYPE(WS-COMMAND-IDX) < 1
              OR DC-SCHEMA-COMMAND-TYPE(WS-COMMAND-IDX) > 3
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema type is not supported."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           IF DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX)
               > DC-SCHEMA-MAX-OPTIONS
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema declares too many options."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           PERFORM VALIDATE-OPTION
               VARYING WS-OPTION-IDX FROM 1 BY 1
               UNTIL WS-OPTION-IDX
                   > DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX)
                   OR DC-STATUS-CODE = DC-STATUS-ERROR.

       VALIDATE-OPTION.
           IF FUNCTION TRIM(
               DC-SCHEMA-OPTION-NAME(WS-COMMAND-IDX, WS-OPTION-IDX))
               = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema option is missing a name."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           IF DC-SCHEMA-OPTION-NAME(WS-COMMAND-IDX, WS-OPTION-IDX)
               NOT = FUNCTION LOWER-CASE(
                   DC-SCHEMA-OPTION-NAME(WS-COMMAND-IDX, WS-OPTION-IDX))
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema option names must be lowercase."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           IF FUNCTION TRIM(
               DC-SCHEMA-OPTION-DESC(WS-COMMAND-IDX, WS-OPTION-IDX))
               = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema option is missing a description."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           IF DC-SCHEMA-OPTION-TYPE(WS-COMMAND-IDX, WS-OPTION-IDX) < 1
              OR DC-SCHEMA-OPTION-TYPE(WS-COMMAND-IDX, WS-OPTION-IDX)
                  > 11
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema option type is not supported."
                   TO DC-ERROR-MESSAGE
           END-IF.
       END PROGRAM DC-COMMAND-SCHEMA-VALIDATE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-COMMAND-SCHEMA-TO-JSON.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMMAND-IDX PIC 9(4) COMP-5.
       01 WS-OPTION-IDX PIC 9(4) COMP-5.
       01 WS-JSON-POS PIC 9(5) COMP-5.
       01 WS-OVERFLOW-FLAG PIC 9.
       01 WS-TYPE-TEXT PIC Z(4).
       01 WS-ESCAPE-IN PIC X(2000).
       01 WS-ESCAPED-NAME PIC X(4096).
       01 WS-ESCAPED-DESC PIC X(4096).
       01 WS-ESCAPE-RESULT.
          05 WS-ESCAPE-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-ESCAPE-ERROR-CODE PIC X(64).
          05 WS-ESCAPE-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-command-schema.cpy".
       01 DC-SCHEMA-COMMANDS-JSON PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-COMMAND-SCHEMA
           DC-SCHEMA-COMMANDS-JSON
           DC-RESULT.
       MAIN.
           *> JP: schema から overwrite にそのまま渡せる安定した JSON 配列を作ります。
           *> JP: key の順序と体裁を固定しているため、同じ schema からは常に
           *> JP: 同じ payload が得られます。text は JSON 向けに escape されます。
           *> EN: Build a stable JSON array from the schema, ready for the bulk
           *> EN: overwrite helper. Key order and formatting are fixed, so the
           *> EN: same schema always yields the same payload. Text fields are
           *> EN: escaped for JSON output.
           MOVE SPACES TO DC-SCHEMA-COMMANDS-JSON

           CALL "DC-COMMAND-SCHEMA-VALIDATE"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE 0 TO WS-OVERFLOW-FLAG
           MOVE 1 TO WS-JSON-POS
           STRING
               "[" DELIMITED BY SIZE
               INTO DC-SCHEMA-COMMANDS-JSON
               WITH POINTER WS-JSON-POS
               ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
           END-STRING

           PERFORM EMIT-COMMAND
               VARYING WS-COMMAND-IDX FROM 1 BY 1
               UNTIL WS-COMMAND-IDX > DC-SCHEMA-COMMAND-COUNT
                   OR DC-STATUS-CODE = DC-STATUS-ERROR
           IF DC-STATUS-CODE = DC-STATUS-ERROR
               GOBACK
           END-IF

           STRING
               "]" DELIMITED BY SIZE
               INTO DC-SCHEMA-COMMANDS-JSON
               WITH POINTER WS-JSON-POS
               ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
           END-STRING

           IF WS-OVERFLOW-FLAG = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_COMMAND_SCHEMA" TO DC-ERROR-CODE
               MOVE "Command schema JSON exceeds the payload buffer."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       EMIT-COMMAND.
           IF WS-COMMAND-IDX > 1
               STRING
                   "," DELIMITED BY SIZE
                   INTO DC-SCHEMA-COMMANDS-JSON
                   WITH POINTER WS-JSON-POS
                   ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
               END-STRING
           END-IF

           MOVE SPACES TO WS-ESCAPE-IN
           MOVE DC-SCHEMA-COMMAND-NAME(WS-COMMAND-IDX) TO WS-ESCAPE-IN
           PERFORM ESCAPE-INTO-NAME
           IF DC-STATUS-CODE = DC-STATUS-ERROR
               EXIT PARAGRAPH
           END-IF

           MOVE SPACES TO WS-ESCAPE-IN
           MOVE DC-SCHEMA-COMMAND-DESC(WS-COMMAND-IDX) TO WS-ESCAPE-IN
           PERFORM ESCAPE-INTO-DESC
           IF DC-STATUS-CODE = DC-STATUS-ERROR
               EXIT PARAGRAPH
           END-IF

           MOVE DC-SCHEMA-COMMAND-TYPE(WS-COMMAND-IDX) TO WS-TYPE-TEXT
           STRING
               '{"name":"' DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-NAME) DELIMITED BY SIZE
               '","type":' DELIMITED BY SIZE
               FUNCTION TRIM(WS-TYPE-TEXT) DELIMITED BY SIZE
               ',"description":"' DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-DESC) DELIMITED BY SIZE
               '"' DELIMITED BY SIZE
               INTO DC-SCHEMA-COMMANDS-JSON
               WITH POINTER WS-JSON-POS
               ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
           END-STRING

           IF DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX) > 0
               STRING
                   ',"options":[' DELIMITED BY SIZE
                   INTO DC-SCHEMA-COMMANDS-JSON
                   WITH POINTER WS-JSON-POS
                   ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
               END-STRING
               PERFORM EMIT-OPTION
                   VARYING WS-OPTION-IDX FROM 1 BY 1
                   UNTIL WS-OPTION-IDX
                       > DC-SCHEMA-OPTION-COUNT(WS-COMMAND-IDX)
                       OR DC-STATUS-CODE = DC-STATUS-ERROR
               IF DC-STATUS-CODE = DC-STATUS-ERROR
                   EXIT PARAGRAPH
               END-IF
               STRING
                   "]" DELIMITED BY SIZE
                   INTO DC-SCHEMA-COMMANDS-JSON
                   WITH POINTER WS-JSON-POS
                   ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
               END-STRING
           END-IF

           STRING
               "}" DELIMITED BY SIZE
               INTO DC-SCHEMA-COMMANDS-JSON
               WITH POINTER WS-JSON-POS
               ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
           END-STRING.

       EMIT-OPTION.
           IF WS-OPTION-IDX > 1
               STRING
                   "," DELIMITED BY SIZE
                   INTO DC-SCHEMA-COMMANDS-JSON
                   WITH POINTER WS-JSON-POS
                   ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
               END-STRING
           END-IF

           MOVE SPACES TO WS-ESCAPE-IN
           MOVE DC-SCHEMA-OPTION-NAME(WS-COMMAND-IDX, WS-OPTION-IDX)
               TO WS-ESCAPE-IN
           PERFORM ESCAPE-INTO-NAME
           IF DC-STATUS-CODE = DC-STATUS-ERROR
               EXIT PARAGRAPH
           END-IF

           MOVE SPACES TO WS-ESCAPE-IN
           MOVE DC-SCHEMA-OPTION-DESC(WS-COMMAND-IDX, WS-OPTION-IDX)
               TO WS-ESCAPE-IN
           PERFORM ESCAPE-INTO-DESC
           IF DC-STATUS-CODE = DC-STATUS-ERROR
               EXIT PARAGRAPH
           END-IF

           MOVE DC-SCHEMA-OPTION-TYPE(WS-COMMAND-IDX, WS-OPTION-IDX)
               TO WS-TYPE-TEXT
           STRING
               '{"name":"' DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-NAME) DELIMITED BY SIZE
               '","type":' DELIMITED BY SIZE
               FUNCTION TRIM(WS-TYPE-TEXT) DELIMITED BY SIZE
               ',"description":"' DELIMITED BY SIZE
               FUNCTION TRIM(WS-ESCAPED-DESC) DELIMITED BY SIZE
               '"' DELIMITED BY SIZE
               INTO DC-SCHEMA-COMMANDS-JSON
               WITH POINTER WS-JSON-POS
               ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
           END-STRING

           *> JP: required は true のときだけ出力します。Discord 側の既定が
           *> JP: false なので、省略しても意味は変わらず payload が安定します。
           *> EN: The required flag is emitted only when true. Discord defaults
           *> EN: to false, so omitting it keeps the payload stable and equivalent.
           IF DC-SCHEMA-OPTION-REQUIRED(WS-COMMAND-IDX, WS-OPTION-IDX)
               NOT = 0
               STRING
                   ',"required":true' DELIMITED BY SIZE
                   INTO DC-SCHEMA-COMMANDS-JSON
                   WITH POINTER WS-JSON-POS
                   ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
               END-STRING
           END-IF

           STRING
               "}" DELIMITED BY SIZE
               INTO DC-SCHEMA-COMMANDS-JSON
               WITH POINTER WS-JSON-POS
               ON OVERFLOW MOVE 1 TO WS-OVERFLOW-FLAG
           END-STRING.

       ESCAPE-INTO-NAME.
           MOVE SPACES TO WS-ESCAPED-NAME
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING WS-ESCAPE-IN
                     WS-ESCAPED-NAME
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
           END-IF.

       ESCAPE-INTO-DESC.
           MOVE SPACES TO WS-ESCAPED-DESC
           CALL "DC-INTERACTION-ESCAPE-TEXT"
               USING WS-ESCAPE-IN
                     WS-ESCAPED-DESC
                     WS-ESCAPE-RESULT
           IF WS-ESCAPE-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-ESCAPE-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-ESCAPE-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-ESCAPE-ERROR-MESSAGE TO DC-ERROR-MESSAGE
           END-IF.
       END PROGRAM DC-COMMAND-SCHEMA-TO-JSON.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-COMMAND-SCHEMA-SYNC.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMMANDS-JSON PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       COPY "discord-command-schema.cpy".
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-SLASH-GUILD-ID-IN
           DC-COMMAND-SCHEMA
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           *> JP: schema を検証・JSON 化した上で、bulk overwrite (PUT) として
           *> JP: Discord へ同期する高水準 API です。guild id が空なら global、
           *> JP: 入っていれば guild scoped commands を丸ごと置き換えます。
           *> EN: High-level API that validates the schema, converts it to JSON,
           *> EN: and synchronizes it to Discord as a bulk overwrite (PUT).
           *> EN: An empty guild id targets global commands; a populated guild id
           *> EN: replaces the guild-scoped command set as a whole.
           INITIALIZE LK-HTTP-RESPONSE

           MOVE SPACES TO WS-COMMANDS-JSON
           CALL "DC-COMMAND-SCHEMA-TO-JSON"
               USING DC-COMMAND-SCHEMA
                     WS-COMMANDS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-SLASH-COMMAND-OVERWRITE"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     WS-COMMANDS-JSON
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-COMMAND-SCHEMA-SYNC.
