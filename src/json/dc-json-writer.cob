       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-WRITE-STRING.
       *> JP: JSON 文字列を安全に組み立てる writer helper 群です。
       *> JP: reply payload や command payload の断片をエスケープ込みで整えます。
       *> EN: Writer helpers for safely constructing JSON strings.
       *> EN: They escape and assemble fragments used in replies and command payloads.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-JSON-KEY-IN PIC X(128).
       01 DC-JSON-VALUE-IN PIC X(512).
       01 DC-JSON-OUT PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-KEY-IN
           DC-JSON-VALUE-IN
           DC-JSON-OUT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-JSON-OUT
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-JSON-KEY-IN) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-JSON-VALUE-IN) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "}" DELIMITED BY SIZE
               INTO DC-JSON-OUT
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-JSON-WRITE-STRING.
