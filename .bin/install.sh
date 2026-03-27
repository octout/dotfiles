#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

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

    local path_line="export PATH=\"$SCRIPT_DIR:\$PATH\""

    if grep -qF "$SCRIPT_DIR" "$shell_rc" 2>/dev/null; then
        echo "  skip: PATH already configured in $shell_rc"
    else
        echo "" >> "$shell_rc"
        echo "# dotfiles .bin" >> "$shell_rc"
        echo "$path_line" >> "$shell_rc"
        echo "  added: PATH entry to $shell_rc"
    fi
}

echo "==> Linking dotfiles..."
link_dotfile .tmux.conf

echo "==> Setting up PATH..."
setup_path

echo "==> Done! Restart your shell or run: source ~/.bashrc"
