#!/usr/bin/env bash
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$REPO_DIR/bin"

# --- ツールのインストール ---
install_tmux() {
    if command -v tmux &>/dev/null; then
        echo "  skip: tmux already installed ($(tmux -V))"
        return
    fi

    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq tmux
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y tmux
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm tmux
    elif command -v brew &>/dev/null; then
        brew install tmux
    else
        echo "  error: パッケージマネージャが見つかりません。手動で tmux をインストールしてください。"
        return 1
    fi
    echo "  installed: tmux ($(tmux -V))"
}

install_claude_code() {
    if command -v claude &>/dev/null; then
        echo "  skip: claude already installed ($(claude --version 2>/dev/null || echo 'unknown'))"
        return
    fi

    if ! command -v curl &>/dev/null; then
        echo "  error: curl が見つかりません。先に curl をインストールしてください。"
        return 1
    fi

    curl -fsSL https://claude.ai/install.sh | bash
    echo "  installed: claude code"
}

# --- dotfiles のシンボリックリンク作成 ---
link_dotfile() {
    local src="$REPO_DIR/$1"
    local dest="$HOME/$1"

    if [[ ! -e "$src" ]]; then
        echo "  skip: $1 (not found)"
        return
    fi

    if [[ -L "$dest" ]]; then
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        mv "$dest" "${dest}.bak"
        echo "  backup: $dest -> ${dest}.bak"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "  link: $dest -> $src"
}

# --- PATH 追加 ---
setup_path() {
    local shell_rc=""
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    local path_line="export PATH=\"$BIN_DIR:\$PATH\""

    if grep -qF "$BIN_DIR" "$shell_rc" 2>/dev/null; then
        echo "  skip: PATH already configured in $shell_rc"
    else
        echo "" >> "$shell_rc"
        echo "# dotfiles bin" >> "$shell_rc"
        echo "$path_line" >> "$shell_rc"
        echo "  added: PATH entry to $shell_rc"
    fi
}

echo "==> Installing tools..."
install_tmux
install_claude_code

echo "==> Linking dotfiles..."
link_dotfile .inputrc
link_dotfile .vimrc
link_dotfile .tmux.conf
link_dotfile .claude/CLAUDE.md
link_dotfile .claude/settings.json

echo "==> Setting up PATH..."
setup_path

echo "==> Done! Restart your shell or run: source ~/.bashrc"
