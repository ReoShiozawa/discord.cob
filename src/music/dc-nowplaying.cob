       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-NOWPLAYING-FORMAT.
       *> JP: 現在再生中 track を表示向け文字列へ整える formatter です。
       *> JP: command 側はここで user-facing text を一箇所に寄せられます。
       *> EN: Formatter that turns the currently playing track into display text.
       *> EN: Command-side code can keep user-facing wording centralized here.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       01 DC-NOWPLAYING-TEXT PIC X(2000).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-TRACK
           DC-NOWPLAYING-TEXT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-NOWPLAYING-TEXT
           IF DC-TRACK-STATUS NOT = 1
      *> JP: player が active でない snapshot は「再生中なし」とみなします。
      *> EN: Treat snapshots outside the active playing state as "nothing playing".
               MOVE "Nothing is playing right now."
                   TO DC-NOWPLAYING-TEXT
           ELSE
               IF FUNCTION TRIM(DC-TRACK-TITLE) NOT = SPACES
                   STRING
                       "Now playing: " DELIMITED BY SIZE
                       FUNCTION TRIM(DC-TRACK-TITLE)
                           DELIMITED BY SIZE
                       INTO DC-NOWPLAYING-TEXT
                   END-STRING
               ELSE
                   STRING
                       "Now playing: " DELIMITED BY SIZE
                       FUNCTION TRIM(DC-TRACK-SOURCE)
                           DELIMITED BY SIZE
                       INTO DC-NOWPLAYING-TEXT
                   END-STRING
               END-IF
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-NOWPLAYING-FORMAT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-QUEUE-FORMAT.
       *> JP: queue snapshot を人向けの短い一覧へ整形する formatter です。
       *> JP: interaction reply やログが内部配列構造に依存しないようにします。
       *> EN: Formatter that turns a queue snapshot into a compact human-facing list.
       *> EN: It keeps interaction replies and logs independent from the raw array layout.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-DISPLAY-IDX PIC 9(4) COMP-5.
       01 WS-QUEUE-IDX PIC 9(4) COMP-5.
       01 WS-TEXT-POS PIC 9(4) COMP-5.
       01 WS-QUEUE-SIZE-TEXT PIC ZZZ9.
       01 WS-DISPLAY-NUM-TEXT PIC ZZZ9.
       01 WS-REMAINING-TEXT PIC ZZZ9.
       01 WS-REMAINING-COUNT PIC 9(4) COMP-5.
       01 WS-TRACK-TEXT PIC X(512).

       LINKAGE SECTION.
       COPY "discord-music.cpy".
       01 DC-QUEUE-TEXT PIC X(2000).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-QUEUE
           DC-QUEUE-TEXT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-QUEUE-TEXT
           IF DC-MQ-SIZE <= 0
               MOVE "Queue is empty." TO DC-QUEUE-TEXT
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           MOVE 1 TO WS-TEXT-POS
           MOVE DC-MQ-SIZE TO WS-QUEUE-SIZE-TEXT
           STRING
               "Queue (" DELIMITED BY SIZE
               FUNCTION TRIM(WS-QUEUE-SIZE-TEXT)
                   DELIMITED BY SIZE
               "): " DELIMITED BY SIZE
               INTO DC-QUEUE-TEXT
               WITH POINTER WS-TEXT-POS
           END-STRING

           MOVE DC-MQ-HEAD TO WS-QUEUE-IDX
           PERFORM VARYING WS-DISPLAY-IDX FROM 1 BY 1
               UNTIL WS-DISPLAY-IDX > DC-MQ-SIZE
                  OR WS-DISPLAY-IDX > 5
               MOVE SPACES TO WS-TRACK-TEXT
               IF FUNCTION TRIM(DC-MQ-TITLE(WS-QUEUE-IDX)) NOT = SPACES
                   MOVE DC-MQ-TITLE(WS-QUEUE-IDX) TO WS-TRACK-TEXT
               ELSE
                   IF FUNCTION TRIM(DC-MQ-SOURCE(WS-QUEUE-IDX))
                       NOT = SPACES
                       MOVE DC-MQ-SOURCE(WS-QUEUE-IDX) TO WS-TRACK-TEXT
                   ELSE
                       MOVE "Untitled track" TO WS-TRACK-TEXT
                   END-IF
               END-IF

               IF WS-DISPLAY-IDX > 1
                   STRING
                       " | " DELIMITED BY SIZE
                       INTO DC-QUEUE-TEXT
                       WITH POINTER WS-TEXT-POS
                   END-STRING
               END-IF

               MOVE WS-DISPLAY-IDX TO WS-DISPLAY-NUM-TEXT
               STRING
                   FUNCTION TRIM(WS-DISPLAY-NUM-TEXT)
                       DELIMITED BY SIZE
                   ". " DELIMITED BY SIZE
                   FUNCTION TRIM(WS-TRACK-TEXT)
                       DELIMITED BY SIZE
                   INTO DC-QUEUE-TEXT
                   WITH POINTER WS-TEXT-POS
               END-STRING

               IF WS-QUEUE-IDX >= 100
                   MOVE 1 TO WS-QUEUE-IDX
               ELSE
                   ADD 1 TO WS-QUEUE-IDX
               END-IF
           END-PERFORM

           IF DC-MQ-SIZE > 5
               COMPUTE WS-REMAINING-COUNT = DC-MQ-SIZE - 5
               MOVE WS-REMAINING-COUNT TO WS-REMAINING-TEXT
               STRING
                   " | +" DELIMITED BY SIZE
                   FUNCTION TRIM(WS-REMAINING-TEXT)
                       DELIMITED BY SIZE
                   " more" DELIMITED BY SIZE
                   INTO DC-QUEUE-TEXT
                   WITH POINTER WS-TEXT-POS
               END-STRING
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-QUEUE-FORMAT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TRACK-FORMAT.
       *> JP: 単一 track を短い表示文字列へ整形する formatter です。
       *> EN: Formatter that turns a single track into a compact display string.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       01 DC-TRACK-TEXT PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-TRACK
           DC-TRACK-TEXT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-TRACK-TEXT
           IF FUNCTION TRIM(DC-TRACK-TITLE) NOT = SPACES
               MOVE DC-TRACK-TITLE TO DC-TRACK-TEXT
           ELSE
               IF FUNCTION TRIM(DC-TRACK-SOURCE) NOT = SPACES
                   MOVE DC-TRACK-SOURCE TO DC-TRACK-TEXT
               ELSE
                   MOVE "Untitled track" TO DC-TRACK-TEXT
               END-IF
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TRACK-FORMAT.
