       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-AUDIO-SOURCE-FROM-FILE.
       *> JP: 外部入力を framework 内の audio source 表現へ写す入口です。
       *> JP: ここでは source 文字列の受け皿をそろえ、実際の読み取りは後段に委ねます。
       *> EN: Entry point that maps external input into the framework audio-source representation.
       *> EN: It normalizes the source string shape here and leaves actual reading to later layers.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-AUDIO-FILE-PATH PIC X(512).
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-AUDIO-FILE-PATH
           DC-AUDIO-SOURCE
           DC-RESULT.
       MAIN.
           MOVE DC-AUDIO-FILE-PATH TO DC-AUDIO-SOURCE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-AUDIO-SOURCE-FROM-FILE.
