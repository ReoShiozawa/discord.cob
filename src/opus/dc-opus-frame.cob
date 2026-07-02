       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-FRAME-CLEAR.
       *> JP: Opus frame DTO を空へ戻す最小 helper です。
       *> JP: frame 長と payload を再利用前にきれいに初期化する意図が明確になります。
       *> EN: Minimal helper that clears the Opus-frame DTO.
       *> EN: It makes the intent explicit: reset frame length and payload before reuse.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-OPUS-FRAME DC-RESULT.
       MAIN.
           INITIALIZE DC-OPUS-FRAME
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-FRAME-CLEAR.
