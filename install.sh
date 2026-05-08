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

install_gh() {
    if command -v gh &>/dev/null; then
        echo "  skip: gh already installed ($(gh --version | head -1))"
        return
    fi

    if command -v apt-get &>/dev/null; then
        if ! command -v curl &>/dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y -qq curl
        fi
        sudo mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
            sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
            sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update -qq && sudo apt-get install -y -qq gh
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y 'dnf-command(config-manager)'
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf install -y gh --repo gh-cli
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm github-cli
    elif command -v brew &>/dev/null; then
        brew install gh
    else
        echo "  error: パッケージマネージャが見つかりません。手動で gh をインストールしてください。"
        return 1
    fi
    echo "  installed: gh ($(gh --version | head -1))"
}

install_docker() {
    if command -v docker &>/dev/null; then
        echo "  skip: docker already installed ($(docker --version))"
        return
    fi

    local os
    os="$(uname -s)"
    case "$os" in
        Linux)
            if command -v apt-get &>/dev/null; then
                local codename id
                . /etc/os-release
                id="${ID:-debian}"
                codename="${VERSION_CODENAME:-}"
                [[ -z "$codename" ]] && codename="$(lsb_release -cs 2>/dev/null || echo stable)"

                sudo apt-get update -qq
                sudo apt-get install -y -qq ca-certificates curl
                sudo install -m 0755 -d /etc/apt/keyrings
                sudo curl -fsSL "https://download.docker.com/linux/${id}/gpg" -o /etc/apt/keyrings/docker.asc
                sudo chmod a+r /etc/apt/keyrings/docker.asc
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${id} ${codename} stable" | \
                    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
                sudo apt-get update -qq
                sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y dnf-plugins-core
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                sudo systemctl enable --now docker
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm docker docker-buildx docker-compose
                sudo systemctl enable --now docker
            else
                echo "  error: パッケージマネージャが見つかりません。手動で docker をインストールしてください。"
                return 1
            fi

            if ! getent group docker &>/dev/null; then
                sudo groupadd docker
            fi
            if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
                sudo usermod -aG docker "$USER"
                echo "  note: $USER を docker グループに追加。反映には再ログインが必要"
            fi
            ;;
        Darwin)
            if command -v brew &>/dev/null; then
                brew install --cask docker
            else
                echo "  error: brew が見つかりません。Docker Desktop を手動でインストールしてください。"
                return 1
            fi
            ;;
        *)
            echo "  error: unsupported OS: $os"
            return 1
            ;;
    esac
    echo "  installed: docker ($(docker --version 2>/dev/null || echo 'unknown'))"
}

NVM_VERSION="v0.40.4"

install_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        echo "  skip: nvm already installed ($NVM_DIR)"
        return
    fi

    if ! command -v curl &>/dev/null; then
        echo "  error: curl が見つかりません。"
        return 1
    fi

    PROFILE=/dev/null curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    echo "  installed: nvm ${NVM_VERSION}"
}

install_node() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # shellcheck disable=SC1091
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

    if ! command -v nvm &>/dev/null; then
        echo "  skip: nvm not loaded — node のインストールをスキップ"
        return
    fi

    if [[ -n "$(nvm version --no-colors node 2>/dev/null | grep -v 'N/A')" ]]; then
        echo "  skip: node already installed via nvm ($(nvm current))"
        return
    fi

    nvm install --lts
    nvm alias default "lts/*" >/dev/null
    echo "  installed: node $(node -v) via nvm"
}

install_aws_cli() {
    if command -v aws &>/dev/null; then
        echo "  skip: aws cli already installed ($(aws --version 2>&1))"
        return
    fi

    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os" in
        Linux)
            if ! command -v unzip &>/dev/null; then
                echo "  error: unzip が見つかりません。先に unzip をインストールしてください。"
                return 1
            fi
            local url
            case "$arch" in
                x86_64)        url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;;
                aarch64|arm64) url="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" ;;
                *) echo "  error: unsupported arch: $arch"; return 1 ;;
            esac
            local tmp
            tmp="$(mktemp -d)"
            curl -fsSL "$url" -o "$tmp/awscliv2.zip"
            unzip -q "$tmp/awscliv2.zip" -d "$tmp"
            sudo "$tmp/aws/install" --update
            rm -rf "$tmp"
            ;;
        Darwin)
            if command -v brew &>/dev/null; then
                brew install awscli
            else
                echo "  error: brew が見つかりません。手動で AWS CLI をインストールしてください。"
                return 1
            fi
            ;;
        *)
            echo "  error: unsupported OS: $os"
            return 1
            ;;
    esac
    echo "  installed: aws cli ($(aws --version 2>&1))"
}

install_difit() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # shellcheck disable=SC1091
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

    if ! command -v npm &>/dev/null; then
        echo "  error: npm が見つかりません。先に node をインストールしてください。"
        return 1
    fi

    if command -v difit &>/dev/null; then
        echo "  skip: difit already installed ($(difit --version 2>/dev/null || echo 'unknown'))"
        return
    fi

    npm install -g difit
    echo "  installed: difit ($(difit --version 2>/dev/null || echo 'unknown'))"
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
install_gh
install_docker
install_nvm
install_node
install_aws_cli
install_difit
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
