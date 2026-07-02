       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-CMD-APP-ID.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 LK-APPLICATION-ID PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           LK-APPLICATION-ID
           DC-RESULT.
       MAIN.
           *> JP: Discord の application command API は application id を path に要求します。
           *> JP: 通常は client id を使い、未取得時だけ user id を代替に使います。
           *> EN: Discord's application-command API requires an application id in
           *> EN: the request path. We prefer the client id and fall back to user id
           *> EN: only when the former has not been populated yet.
           MOVE SPACES TO LK-APPLICATION-ID

           IF FUNCTION TRIM(DC-CLIENT-ID) NOT = SPACES
               MOVE DC-CLIENT-ID TO LK-APPLICATION-ID
           ELSE
               MOVE DC-CLIENT-USER-ID TO LK-APPLICATION-ID
           END-IF

           IF FUNCTION TRIM(LK-APPLICATION-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Client application id is required for slash command requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-CMD-APP-ID.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-CMD-BUILD-COLL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-APPLICATION-ID PIC X(32).
       01 WS-BODY-LENGTH PIC 9(5) COMP-5.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 DC-SLASH-METHOD-IN PIC X(8).
       01 DC-SLASH-COMMAND-JSON PIC X(8192).
       01 LK-HTTP-REQUEST.
          05 LK-HTTP-METHOD PIC X(8).
          05 LK-HTTP-HOST PIC X(256).
          05 LK-HTTP-PATH PIC X(512).
          05 LK-HTTP-AUTHORIZATION PIC X(320).
          05 LK-HTTP-CONTENT-TYPE PIC X(128).
          05 LK-HTTP-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-SLASH-GUILD-ID-IN
           DC-SLASH-METHOD-IN
           DC-SLASH-COMMAND-JSON
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
           *> JP: collection endpoint 用の共通 request builder です。
           *> JP: register/list/overwrite は HTTP method と body の違いだけなので、
           *> JP: path と auth header の組み立てをここへ集約しています。
           *> EN: This is the shared request builder for collection endpoints.
           *> EN: Register/list/overwrite differ mainly by HTTP method and body,
           *> EN: so path and auth-header construction live here in one place.
           *>
           *> JP: guild id が空なら global commands、入っていれば guild scoped commands
           *> JP: として扱います。
           *> EN: An empty guild id means global commands; a populated guild id
           *> EN: targets guild-scoped commands.
           INITIALIZE LK-HTTP-REQUEST
           MOVE 0 TO WS-BODY-LENGTH

           IF FUNCTION TRIM(DC-CLIENT-TOKEN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Bot token is required for slash command requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-SLASH-CMD-APP-ID"
               USING DC-CLIENT
                     WS-APPLICATION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE DC-SLASH-METHOD-IN TO LK-HTTP-METHOD
           MOVE "discord.com" TO LK-HTTP-HOST
           STRING
               "Bot " DELIMITED BY SIZE
               FUNCTION TRIM(DC-CLIENT-TOKEN) DELIMITED BY SIZE
               INTO LK-HTTP-AUTHORIZATION
           END-STRING

           IF FUNCTION TRIM(DC-SLASH-GUILD-ID-IN) = SPACES
               STRING
                   "/api/v10/applications/" DELIMITED BY SIZE
                   FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
                   "/commands" DELIMITED BY SIZE
                   INTO LK-HTTP-PATH
               END-STRING
           ELSE
               STRING
                   "/api/v10/applications/" DELIMITED BY SIZE
                   FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
                   "/guilds/" DELIMITED BY SIZE
                   FUNCTION TRIM(DC-SLASH-GUILD-ID-IN) DELIMITED BY SIZE
                   "/commands" DELIMITED BY SIZE
                   INTO LK-HTTP-PATH
               END-STRING
           END-IF

           IF FUNCTION TRIM(DC-SLASH-COMMAND-JSON) NOT = SPACES
               MOVE "application/json" TO LK-HTTP-CONTENT-TYPE
               MOVE FUNCTION LENGTH(
                   FUNCTION TRIM(DC-SLASH-COMMAND-JSON TRAILING))
                   TO WS-BODY-LENGTH
               MOVE WS-BODY-LENGTH TO LK-HTTP-BODY-LENGTH
               IF WS-BODY-LENGTH > 0
                   MOVE DC-SLASH-COMMAND-JSON(1:WS-BODY-LENGTH)
                       TO LK-HTTP-BODY(1:WS-BODY-LENGTH)
               END-IF
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-CMD-BUILD-COLL.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-CMD-BUILD-ITEM.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-APPLICATION-ID PIC X(32).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 DC-SLASH-COMMAND-ID-IN PIC X(32).
       01 DC-SLASH-METHOD-IN PIC X(8).
       01 LK-HTTP-REQUEST.
          05 LK-HTTP-METHOD PIC X(8).
          05 LK-HTTP-HOST PIC X(256).
          05 LK-HTTP-PATH PIC X(512).
          05 LK-HTTP-AUTHORIZATION PIC X(320).
          05 LK-HTTP-CONTENT-TYPE PIC X(128).
          05 LK-HTTP-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-SLASH-GUILD-ID-IN
           DC-SLASH-COMMAND-ID-IN
           DC-SLASH-METHOD-IN
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
           *> JP: 単一 command endpoint 用の builder です。
           *> JP: delete や将来の get-one/patch-one で同じ path 形を再利用できます。
           *> EN: This builder targets a single-command endpoint and can be reused
           *> EN: by delete or future get-one/patch-one style helpers.
           INITIALIZE LK-HTTP-REQUEST

           IF FUNCTION TRIM(DC-CLIENT-TOKEN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Bot token is required for slash command requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-SLASH-CMD-APP-ID"
               USING DC-CLIENT
                     WS-APPLICATION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE DC-SLASH-METHOD-IN TO LK-HTTP-METHOD
           MOVE "discord.com" TO LK-HTTP-HOST
           STRING
               "Bot " DELIMITED BY SIZE
               FUNCTION TRIM(DC-CLIENT-TOKEN) DELIMITED BY SIZE
               INTO LK-HTTP-AUTHORIZATION
           END-STRING

           IF FUNCTION TRIM(DC-SLASH-GUILD-ID-IN) = SPACES
               STRING
                   "/api/v10/applications/" DELIMITED BY SIZE
                   FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
                   "/commands/" DELIMITED BY SIZE
                   FUNCTION TRIM(DC-SLASH-COMMAND-ID-IN) DELIMITED BY SIZE
                   INTO LK-HTTP-PATH
               END-STRING
           ELSE
               STRING
                   "/api/v10/applications/" DELIMITED BY SIZE
                   FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
                   "/guilds/" DELIMITED BY SIZE
                   FUNCTION TRIM(DC-SLASH-GUILD-ID-IN) DELIMITED BY SIZE
                   "/commands/" DELIMITED BY SIZE
                   FUNCTION TRIM(DC-SLASH-COMMAND-ID-IN) DELIMITED BY SIZE
                   INTO LK-HTTP-PATH
               END-STRING
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-CMD-BUILD-ITEM.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-COMMAND-BUILD-REQUEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-METHOD PIC X(8) VALUE "POST".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 DC-SLASH-COMMAND-JSON PIC X(8192).
       01 LK-HTTP-REQUEST.
          05 LK-HTTP-METHOD PIC X(8).
          05 LK-HTTP-HOST PIC X(256).
          05 LK-HTTP-PATH PIC X(512).
          05 LK-HTTP-AUTHORIZATION PIC X(320).
          05 LK-HTTP-CONTENT-TYPE PIC X(128).
          05 LK-HTTP-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-SLASH-GUILD-ID-IN
           DC-SLASH-COMMAND-JSON
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
           *> JP: register 用の公開 helper では、必須の JSON presence だけ先に検証し、
           *> JP: 実際の request 組み立ては共通 builder へ流します。
           *> EN: The public register helper validates the presence of command JSON
           *> EN: up front, then delegates actual request construction to the
           *> EN: shared builder.
           IF FUNCTION TRIM(DC-SLASH-COMMAND-JSON) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Slash command JSON is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-SLASH-CMD-BUILD-COLL"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     WS-METHOD
                     DC-SLASH-COMMAND-JSON
                     LK-HTTP-REQUEST
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-COMMAND-BUILD-REQUEST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-COMMAND-REGISTER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 DC-SLASH-COMMAND-JSON PIC X(8192).
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
           DC-SLASH-COMMAND-JSON
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           *> JP: build と execute を分けた上で、ここは 2xx 判定までを担う高水準 API です。
           *> EN: Build and execute are split intentionally; this high-level API
           *> EN: owns the final HTTP call and the 2xx success check.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-SLASH-COMMAND-BUILD-REQUEST"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     DC-SLASH-COMMAND-JSON
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-POST"
               USING DC-HTTP-REQUEST
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Slash command registration did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-COMMAND-REGISTER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-COMMAND-BUILD-LIST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-METHOD PIC X(8) VALUE "GET".
       01 WS-EMPTY-BODY PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 LK-HTTP-REQUEST.
          05 LK-HTTP-METHOD PIC X(8).
          05 LK-HTTP-HOST PIC X(256).
          05 LK-HTTP-PATH PIC X(512).
          05 LK-HTTP-AUTHORIZATION PIC X(320).
          05 LK-HTTP-CONTENT-TYPE PIC X(128).
          05 LK-HTTP-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-SLASH-GUILD-ID-IN
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
           *> JP: list は body を持たない GET なので、空 body のまま collection builder を再利用します。
           *> EN: Listing is a bodyless GET, so it simply reuses the collection
           *> EN: builder with an empty request body.
           CALL "DC-SLASH-CMD-BUILD-COLL"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     WS-METHOD
                     WS-EMPTY-BODY
                     LK-HTTP-REQUEST
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-COMMAND-BUILD-LIST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-COMMAND-LIST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
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
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           *> JP: 一覧取得も register と同じく、request build -> HTTP execute -> 2xx 検証
           *> JP: の 3 段に揃えています。
           *> EN: Listing follows the same three-stage shape as registration:
           *> EN: request build, HTTP execute, and 2xx verification.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-SLASH-COMMAND-BUILD-LIST"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-GET"
               USING DC-HTTP-REQUEST
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Slash command fetch did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-COMMAND-LIST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-COMMAND-BUILD-DELETE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-METHOD PIC X(8) VALUE "DELETE".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 DC-SLASH-COMMAND-ID-IN PIC X(32).
       01 LK-HTTP-REQUEST.
          05 LK-HTTP-METHOD PIC X(8).
          05 LK-HTTP-HOST PIC X(256).
          05 LK-HTTP-PATH PIC X(512).
          05 LK-HTTP-AUTHORIZATION PIC X(320).
          05 LK-HTTP-CONTENT-TYPE PIC X(128).
          05 LK-HTTP-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-SLASH-GUILD-ID-IN
           DC-SLASH-COMMAND-ID-IN
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
           *> JP: delete は command id が path に入るため、まず id の存在だけを明示的に検証します。
           *> EN: Delete needs a command id in the path, so it first validates
           *> EN: that the id is explicitly present.
           IF FUNCTION TRIM(DC-SLASH-COMMAND-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Slash command id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-SLASH-CMD-BUILD-ITEM"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     DC-SLASH-COMMAND-ID-IN
                     WS-METHOD
                     LK-HTTP-REQUEST
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-COMMAND-BUILD-DELETE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-COMMAND-DELETE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 DC-SLASH-COMMAND-ID-IN PIC X(32).
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
           DC-SLASH-COMMAND-ID-IN
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           *> JP: delete 実行側も公開 API としては 2xx まで面倒を見て、
           *> JP: 呼び出し側が生 raw status を都度解釈しなくて済むようにします。
           *> EN: The delete executor also owns the 2xx check so callers do not
           *> EN: need to interpret raw HTTP statuses each time.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-SLASH-COMMAND-BUILD-DELETE"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     DC-SLASH-COMMAND-ID-IN
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-DELETE"
               USING DC-HTTP-REQUEST
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Slash command delete did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-COMMAND-DELETE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-COMMAND-BUILD-SET.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-METHOD PIC X(8) VALUE "PUT".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 DC-SLASH-COMMANDS-JSON PIC X(8192).
       01 LK-HTTP-REQUEST.
          05 LK-HTTP-METHOD PIC X(8).
          05 LK-HTTP-HOST PIC X(256).
          05 LK-HTTP-PATH PIC X(512).
          05 LK-HTTP-AUTHORIZATION PIC X(320).
          05 LK-HTTP-CONTENT-TYPE PIC X(128).
          05 LK-HTTP-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-SLASH-GUILD-ID-IN
           DC-SLASH-COMMANDS-JSON
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-SLASH-COMMANDS-JSON) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Slash command set JSON is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-SLASH-CMD-BUILD-COLL"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     WS-METHOD
                     DC-SLASH-COMMANDS-JSON
                     LK-HTTP-REQUEST
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-COMMAND-BUILD-SET.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SLASH-COMMAND-OVERWRITE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-SLASH-GUILD-ID-IN PIC X(32).
       01 DC-SLASH-COMMANDS-JSON PIC X(8192).
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
           DC-SLASH-COMMANDS-JSON
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-SLASH-COMMAND-BUILD-SET"
               USING DC-CLIENT
                     DC-SLASH-GUILD-ID-IN
                     DC-SLASH-COMMANDS-JSON
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-PUT"
               USING DC-HTTP-REQUEST
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Slash command overwrite did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SLASH-COMMAND-OVERWRITE.
