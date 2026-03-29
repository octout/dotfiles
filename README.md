# dotfiles

個人の設定ファイルと自作ツールを管理するリポジトリ。

## セットアップ

```bash
git clone --recurse-submodules https://github.com/octout/dotfiles ~/dotfiles
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
| `.vimrc` | Vim 設定 |
| `.vim/pack/` | Vim プラグイン (git submodule) |
| `.claude/CLAUDE.md` | Claude Code グローバル指示 |
| `.claude/settings.json` | Claude Code グローバル設定 |
| `.tmux.conf` | tmux 設定 |

## Vim

プラグインは Vim 8 のネイティブパッケージ機構 (`pack/*/start/`) で管理し、git submodule でバージョンを固定している。

| プラグイン | バージョン | 説明 |
|-----------|-----------|------|
| [vim-gitgutter](https://github.com/airblade/vim-gitgutter) | [`55b368d`](https://github.com/airblade/vim-gitgutter/commit/55b368d) | サイン列に git diff を表示 (`+` 追加 / `~` 変更 / `-` 削除) |

主なキーバインド (gitgutter):

| キー | 操作 |
|------|------|
| `]c` / `[c` | 次/前の変更箇所へジャンプ |
| `<leader>hp` | 変更箇所をプレビュー |
| `<leader>hs` | 変更箇所をステージ |
| `<leader>hu` | 変更箇所を元に戻す |

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
