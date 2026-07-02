       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-AUDIO-BUFFER-CLEAR.
       *> JP: Audio/Opus frame を再利用前に空へ戻す小さな helper 群の入口です。
       *> JP: 再生 loop では古い payload 長や残骸を残さないことが重要です。
       *> EN: Entry point for tiny helpers that clear audio/Opus frames before reuse.
       *> EN: Playback loops rely on this to avoid carrying stale payload lengths or leftover bytes.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-OPUS-FRAME DC-RESULT.
       MAIN.
           INITIALIZE DC-OPUS-FRAME
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-AUDIO-BUFFER-CLEAR.
