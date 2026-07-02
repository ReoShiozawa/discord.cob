       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SPEAKING-BUILD.
       *> JP: Discord Voice の speaking payload を組み立てる helper です。
       *> JP: 実際の音声 frame 送信前に状態通知を出すための JSON をここで作ります。
       *> EN: Helper that builds Discord Voice speaking payloads.
       *> EN: It creates the JSON used to announce speaking state before audio frames are sent.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-SPEAKING-TEXT PIC Z(9)9.
       01 WS-DELAY-TEXT PIC Z(9)9.
       01 WS-SSRC-TEXT PIC Z(9)9.

       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-SPEAKING-PAYLOAD-JSON PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-SPEAKING-PAYLOAD
           DC-SPEAKING-PAYLOAD-JSON
           DC-RESULT.
       MAIN.
           MOVE DC-SPEAKING-FLAG TO WS-SPEAKING-TEXT
           MOVE DC-SPEAKING-DELAY TO WS-DELAY-TEXT
           MOVE DC-SPEAKING-SSRC TO WS-SSRC-TEXT
           MOVE SPACES TO DC-SPEAKING-PAYLOAD-JSON
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "op" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":5," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "d" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "speaking" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(WS-SPEAKING-TEXT) DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "delay" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(WS-DELAY-TEXT) DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "ssrc" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(WS-SSRC-TEXT) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-SPEAKING-PAYLOAD-JSON
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SPEAKING-BUILD.
