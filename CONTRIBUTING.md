# Contributing to discord.cob

Contributions are welcome. The easiest changes to review are focused, test-backed, and preserve the repository's All COBOL boundary: human-authored library source belongs in COBOL, with no custom C adapter modules.

## Development workflow

1. Install GnuCOBOL, `libsodium`, `pkg-config`, OpenSSL, and netcat.
2. Create a branch from `main`.
3. Keep the change within the smallest relevant module boundary.
4. Add or update an executable test under `tests/`.
5. Run `make build`, `make test`, and `make examples`.
6. Open a pull request describing behavior, compatibility impact, and verification.

Public helpers return `DC-RESULT`. New shared record layouts belong in `src/copybooks/`. Comments should explain protocol constraints or non-obvious state transitions and, where practical, include concise Japanese and English lines.

Please do not commit bot tokens, guild IDs, captured secret keys, generated `build/` output, or compiler-generated C/object files.

## 日本語

コントリビュートを歓迎します。レビューしやすいのは、変更範囲が明確で、対応するテストがあり、All COBOL 方針を保っている Pull Request です。ライブラリ用の C adapter は追加せず、人が管理する実装は COBOL に置いてください。

開発時は `main` から branch を作り、必要な module と test だけを変更します。提出前に `make build`、`make test`、`make examples` を実行してください。公開 helper は `DC-RESULT` を返し、共有 data layout は `src/copybooks/` に置きます。認証情報、Voice の secret key、`build/` 以下の生成物、compiler が生成した C/object file は commit しないでください。
