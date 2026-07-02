       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-DAVE-INIT.
       *> JP: DAVE 関連 state の初期化 helper です。
       *> JP: voice 暗号化の追加交渉情報を固定長 state に載せる前提をここで整えます。
       *> EN: Initialization helper for DAVE-related state.
       *> EN: It prepares the fixed-size state used to carry extra negotiation data for voice encryption.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-crypto.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-DAVE-STATE DC-RESULT.
       MAIN.
           MOVE 0 TO DC-DAVE-ENABLED-FLAG
           MOVE 0 TO DC-DAVE-PROTOCOL-VERSION
           MOVE SPACES TO DC-DAVE-KEY-MATERIAL
           MOVE 0 TO DC-DAVE-READY-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-DAVE-INIT.
