# Global Instructions

- gitのブランチ管理にはworktreeを用いること
- worktreeの作成・管理にはClaude Codeの純正ツール（EnterWorktree / ExitWorktree）を使用すること
- gitで管理されているプロジェクトでは、作業時にブランチを切って進めること
- worktreeを新規作成した際は、元のworktreeから `.env` 系ファイル（`.env`, `.env.local`, `.env.*` など `.gitignore` されている環境設定ファイル）をコピーすること。worktreeごとに独立した環境変数を扱えるようにするため、シンボリックリンクではなくコピーを用いる
