       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-PACKET-NEXT.
       *> JP: Opus packet 列から次の packet を取り出す helper です。
       *> JP: reader 側の page 進行と playback 側の frame 消費の橋渡しを担います。
       *> EN: Helper that advances to the next packet in an Opus packet stream.
       *> EN: It bridges page-level reader progress and playback-side frame consumption.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-OPUS-HANDLE
           DC-OPUS-FRAME
           DC-RESULT.
       MAIN.
           CALL "DC-OPUS-READ-FRAME"
               USING DC-OPUS-HANDLE DC-OPUS-FRAME DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-PACKET-NEXT.
