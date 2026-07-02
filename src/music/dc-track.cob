       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-TRACK-FROM-SOURCE.
       *> JP: 外部 source から music track DTO を組み立てる helper です。
       *> JP: queue に積める最小メタデータ形へ正規化する責務を持ちます。
       *> EN: Helper that builds a music-track DTO from an external source.
       *> EN: It normalizes source input into the minimal metadata shape that can be queued.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-TRACK-SOURCE-IN PIC X(512).
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-TRACK-SOURCE-IN
           DC-MUSIC-TRACK
           DC-RESULT.
       MAIN.
           INITIALIZE DC-MUSIC-TRACK
           MOVE DC-TRACK-SOURCE-IN TO DC-TRACK-SOURCE
           MOVE DC-TRACK-SOURCE-IN TO DC-TRACK-TITLE
           MOVE 0 TO DC-TRACK-STATUS
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-TRACK-FROM-SOURCE.
