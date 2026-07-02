       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-INIT.
       *> JP: music queue の初期化・push・pop を行う基礎 helper 群です。
       *> JP: guild ごとの track 順序を固定長リングに近い形で扱います。
       *> EN: Foundational helpers for initializing, pushing to, and popping from the music queue.
       *> EN: They manage guild-scoped track order in a fixed-size queue structure.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       01 DC-MQ-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-QUEUE
           DC-MQ-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           INITIALIZE DC-MUSIC-QUEUE
           MOVE DC-MQ-GUILD-ID-IN TO DC-MQ-GUILD-ID
           MOVE 1 TO DC-MQ-HEAD
           MOVE 0 TO DC-MQ-TAIL
           MOVE 0 TO DC-MQ-SIZE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-INIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-PUSH.
       *> JP: music queue の初期化・push・pop を行う基礎 helper 群です。
       *> JP: guild ごとの track 順序を固定長リングに近い形で扱います。
       *> EN: Foundational helpers for initializing, pushing to, and popping from the music queue.
       *> EN: They manage guild-scoped track order in a fixed-size queue structure.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-QUEUE
           DC-MUSIC-TRACK
           DC-RESULT.
       MAIN.
           IF DC-MQ-SIZE >= 100
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_QUEUE_FULL" TO DC-ERROR-CODE
               MOVE "Music queue is full." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-MQ-TAIL >= 100
               MOVE 1 TO DC-MQ-TAIL
           ELSE
               ADD 1 TO DC-MQ-TAIL
           END-IF

           MOVE DC-TRACK-ID TO DC-MQ-TRACK-ID(DC-MQ-TAIL)
           MOVE DC-TRACK-TITLE TO DC-MQ-TITLE(DC-MQ-TAIL)
           MOVE DC-TRACK-SOURCE TO DC-MQ-SOURCE(DC-MQ-TAIL)
           MOVE DC-TRACK-REQUESTER-ID
               TO DC-MQ-REQUESTER-ID(DC-MQ-TAIL)
           MOVE DC-TRACK-STATUS TO DC-MQ-STATUS(DC-MQ-TAIL)
           ADD 1 TO DC-MQ-SIZE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-PUSH.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-POP.
       *> JP: music queue の初期化・push・pop を行う基礎 helper 群です。
       *> JP: guild ごとの track 順序を固定長リングに近い形で扱います。
       *> EN: Foundational helpers for initializing, pushing to, and popping from the music queue.
       *> EN: They manage guild-scoped track order in a fixed-size queue structure.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-QUEUE
           DC-MUSIC-TRACK
           DC-RESULT.
       MAIN.
           IF DC-MQ-SIZE = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "Music queue is empty." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-MQ-TRACK-ID(DC-MQ-HEAD) TO DC-TRACK-ID
           MOVE DC-MQ-TITLE(DC-MQ-HEAD) TO DC-TRACK-TITLE
           MOVE DC-MQ-SOURCE(DC-MQ-HEAD) TO DC-TRACK-SOURCE
           MOVE DC-MQ-REQUESTER-ID(DC-MQ-HEAD)
               TO DC-TRACK-REQUESTER-ID
           MOVE DC-MQ-STATUS(DC-MQ-HEAD) TO DC-TRACK-STATUS

           IF DC-MQ-HEAD >= 100
               MOVE 1 TO DC-MQ-HEAD
           ELSE
               ADD 1 TO DC-MQ-HEAD
           END-IF
           SUBTRACT 1 FROM DC-MQ-SIZE
           IF DC-MQ-SIZE = 0
               MOVE 1 TO DC-MQ-HEAD
               MOVE 0 TO DC-MQ-TAIL
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-POP.
