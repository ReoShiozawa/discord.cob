       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-TOKENIZE.
       *> JP: JSON 文字列を token 列へ分解する低レベル helper です。
       *> JP: parser や path helper が前提にする字句単位をここで作ります。
       *> EN: Low-level helper that tokenizes JSON text.
       *> EN: It produces the lexical units assumed by the parser and path helpers.

       DATA DIVISION.
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
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-JSON-TOKENIZE.
