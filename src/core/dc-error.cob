       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-RESULT-OK.
       *> JP: 共通 result を成功/失敗形に整える最小 helper 群です。
       *> JP: 多くの API が同じ終了規約に乗るので、ここが土台になります。
       *> EN: Minimal helpers that shape the common result into success or error states.
       *> EN: Many APIs rely on the same exit convention, so this file is foundational.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-RESULT.
       MAIN.
           MOVE DC-STATUS-OK TO DC-STATUS-CODE
           MOVE SPACES TO DC-ERROR-CODE
           MOVE SPACES TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-RESULT-OK.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-RESULT-ERROR.
       *> JP: 共通 result を成功/失敗形に整える最小 helper 群です。
       *> JP: 多くの API が同じ終了規約に乗るので、ここが土台になります。
       *> EN: Minimal helpers that shape the common result into success or error states.
       *> EN: Many APIs rely on the same exit convention, so this file is foundational.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-result.cpy".
       01 DC-IN-ERROR-CODE PIC X(64).
       01 DC-IN-ERROR-MESSAGE PIC X(256).

       PROCEDURE DIVISION USING
           DC-RESULT
           DC-IN-ERROR-CODE
           DC-IN-ERROR-MESSAGE.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE DC-IN-ERROR-CODE TO DC-ERROR-CODE
           MOVE DC-IN-ERROR-MESSAGE TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-RESULT-ERROR.
