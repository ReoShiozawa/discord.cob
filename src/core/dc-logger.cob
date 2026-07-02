       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-LOG.
       *> JP: framework 内の簡易ログ出力入口です。
       *> JP: 呼び出し側はログ整形の詳細を気にせず、level と message だけを渡します。
       *> EN: Lightweight logging entry point for the framework.
       *> EN: Callers pass only the level and message without caring about formatting details.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-LOG-LEVEL-IN PIC 9(2) COMP-5.
       01 DC-LOG-MESSAGE PIC X(256).

       PROCEDURE DIVISION USING DC-LOG-LEVEL-IN DC-LOG-MESSAGE.
       MAIN.
           DISPLAY "[discord.cob] "
               FUNCTION TRIM(DC-LOG-MESSAGE)
           END-DISPLAY
           GOBACK.
       END PROGRAM DC-LOG.
