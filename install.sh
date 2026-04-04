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

install_vim() {
    if command -v vim &>/dev/null; then
        echo "  skip: vim already installed ($(vim --version | head -1))"
        return
    fi

    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq vim
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y vim
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm vim
    elif command -v brew &>/dev/null; then
        brew install vim
    else
        echo "  error: パッケージマネージャが見つかりません。手動で vim をインストールしてください。"
        return 1
    fi
    echo "  installed: vim ($(vim --version | head -1))"
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

install_vim_plugins() {
    local plugin_dir="$REPO_DIR/.vim/pack/plugins/start/vim-gitgutter"
    if [[ -d "$plugin_dir/.git" ]] || [[ -f "$plugin_dir/.git" ]]; then
        echo "  skip: vim plugins already initialized"
        return
    fi
    git -C "$REPO_DIR" submodule update --init --recursive
    echo "  installed: vim plugins (git submodule)"
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

# --- gitconfig の include 設定 ---
setup_gitconfig() {
    local include_path="$REPO_DIR/.gitconfig"
    local tilde_path="${include_path/#$HOME/\~}"

    # 既にincludeされているか確認 (~/ 形式と絶対パス両方)
    local existing
    existing="$(git config --global --get-all include.path 2>/dev/null)" || true
    if [[ -n "$existing" ]]; then
        if printf '%s\n' "$existing" | grep -qxF "$tilde_path" || \
           printf '%s\n' "$existing" | grep -qxF "$include_path"; then
            echo "  skip: .gitconfig include already configured"
            return
        fi
    fi

    git config --global --add include.path "$tilde_path"
    echo "  added: include.path = $tilde_path to ~/.gitconfig"
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
install_vim
install_claude_code
install_vim_plugins

echo "==> Creating directories..."
mkdir -p "$HOME/.vim/swap"

echo "==> Linking dotfiles..."
link_dotfile .inputrc
link_dotfile .vimrc
link_dotfile .tmux.conf
link_dotfile .claude/CLAUDE.md
link_dotfile .claude/settings.json
link_dotfile .vim/pack/plugins/start/vim-gitgutter

echo "==> Setting up gitconfig..."
setup_gitconfig

echo "==> Setting up PATH..."
setup_path

echo "==> Done! Restart your shell or run: source ~/.bashrc"
