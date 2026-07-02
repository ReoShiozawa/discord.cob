       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-REPLY.

       DATA DIVISION.
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
               FUNCTION TRIM(DC-REPLY-CONTENT) DELIMITED BY SIZE
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
               FUNCTION TRIM(DC-REPLY-CONTENT) DELIMITED BY SIZE
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
           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{"
               QUOTE
               "content"
               QUOTE
               ":"
               QUOTE
               FUNCTION TRIM(DC-REPLY-CONTENT)
               QUOTE
               "}"
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-FOLLOWUP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-UPDATE.

       DATA DIVISION.
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
               FUNCTION TRIM(DC-REPLY-CONTENT) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-UPDATE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-COMPONENT.

       DATA DIVISION.
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
               FUNCTION TRIM(DC-REPLY-CONTENT) DELIMITED BY SIZE
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
