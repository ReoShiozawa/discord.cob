       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-OPEN.
       *> JP: Opus source を開き、frame 単位で読み、閉じる高水準 reader API 群です。
       *> JP: playback 層は container 差分を意識せずこの API 面を使います。
       *> EN: High-level reader APIs that open an Opus source, read frames, and close it.
       *> EN: The playback layer can use this surface without caring about container-specific details.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-AUDIO-SOURCE
           DC-OPUS-HANDLE
           DC-RESULT.
       MAIN.
           CALL "DC-OGG-OPUS-OPEN"
               USING DC-AUDIO-SOURCE
                     DC-OPUS-HANDLE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-OPEN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-READ-FRAME.
       *> JP: Opus source を開き、frame 単位で読み、閉じる高水準 reader API 群です。
       *> JP: playback 層は container 差分を意識せずこの API 面を使います。
       *> EN: High-level reader APIs that open an Opus source, read frames, and close it.
       *> EN: The playback layer can use this surface without caring about container-specific details.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-OPUS-HANDLE
           DC-OPUS-FRAME
           DC-RESULT.
       MAIN.
           CALL "DC-OGG-OPUS-READ-FRAME"
               USING DC-OPUS-HANDLE
                     DC-OPUS-FRAME
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-READ-FRAME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-CLOSE.
       *> JP: Opus source を開き、frame 単位で読み、閉じる高水準 reader API 群です。
       *> JP: playback 層は container 差分を意識せずこの API 面を使います。
       *> EN: High-level reader APIs that open an Opus source, read frames, and close it.
       *> EN: The playback layer can use this surface without caring about container-specific details.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-OPUS-HANDLE DC-RESULT.
       MAIN.
           CALL "DC-OGG-OPUS-CLOSE"
               USING DC-OPUS-HANDLE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-CLOSE.
