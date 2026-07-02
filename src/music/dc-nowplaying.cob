       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-NOWPLAYING-FORMAT.
       *> JP: 現在再生中 track を表示向け文字列へ整える formatter です。
       *> JP: command 側はここで user-facing text を一箇所に寄せられます。
       *> EN: Formatter that turns the currently playing track into display text.
       *> EN: Command-side code can keep user-facing wording centralized here.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       01 DC-NOWPLAYING-TEXT PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-TRACK
           DC-NOWPLAYING-TEXT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-NOWPLAYING-TEXT
           STRING
               "Now playing: " DELIMITED BY SIZE
               FUNCTION TRIM(DC-TRACK-TITLE) DELIMITED BY SIZE
               INTO DC-NOWPLAYING-TEXT
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-NOWPLAYING-FORMAT.
