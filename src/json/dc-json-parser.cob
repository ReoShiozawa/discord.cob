       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-VALIDATE.
       *> JP: JSON 文字列の妥当性確認を担う入口です。
       *> JP: 深い意味解釈より先に「読み進めてよい形か」を判断する土台になります。
       *> EN: Entry point responsible for validating JSON text.
       *> EN: It provides the foundation that answers whether the input is safe to parse further.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-json.cpy".

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-JSON-BUFFER-IN DC-RESULT.
       MAIN.
           CALL "DC-JSON-SCAN"
               USING DC-JSON-BUFFER-IN DC-JSON-TOKENS DC-RESULT
           GOBACK.
       END PROGRAM DC-JSON-VALIDATE.
