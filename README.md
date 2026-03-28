# dotfiles

個人の設定ファイルと自作ツールを管理するリポジトリ。

## セットアップ

```bash
git clone https://github.com/octout/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` は以下を実行する:

- dotfiles (`~/.tmux.conf` 等) をホームディレクトリにシンボリックリンク
- `bin/` を PATH に追加

## 構成

| パス | 説明 |
|------|------|
| `bin/` | 自作スクリプト・ツール (PATH に追加される) |
| `install.sh` | セットアップスクリプト |
| `.claude/CLAUDE.md` | Claude Code グローバル指示 |
| `.claude/settings.json` | Claude Code グローバル設定 |
| `.tmux.conf` | tmux 設定 |

## ツール

### tmux-tree

tmux pane 内で動作するファイルツリーブラウザ。

```bash
tmux-tree [directory]
```

| キー | 操作 |
|------|------|
| `j/k`, 矢印 | カーソル移動 |
| `Enter` | ファイルを開く / ディレクトリ展開 |
| `Space` | ディレクトリ展開/折り畳み |
| `l`, 右矢印 | ディレクトリに入る / ファイルを開く |
| `h`, 左矢印 | 親ディレクトリへ |
| `g/G` | 先頭/末尾 |
| `r` | リフレッシュ |
| `q` | 終了 |

環境変数で設定可能:

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `TMUX_TREE_DEPTH` | `4` | ツリーの深さ |
| `TMUX_TREE_EDITOR` | `vim` | エディタ |
| `TMUX_TREE_SPLIT` | `h` | tmux 分割方向 |
| `TMUX_TREE_REFRESH` | `5` | 自動リフレッシュ間隔 (秒) |
| `TMUX_TREE_IGNORE` | `.git\|node_modules\|...` | 無視パターン |
