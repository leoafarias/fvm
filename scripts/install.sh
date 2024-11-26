#!/usr/bin/env bash

# Function to log messages with date and time
log_message() {
    echo -e "$1"
}

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Map to FVM naming
case "$OS" in
Linux*) OS='linux' ;;
Darwin*) OS='macos' ;;
*)
    log_message "Unsupported OS"
    exit 1
    ;;
esac

case "$ARCH" in
x86_64) ARCH='x64' ;;
arm64 | aarch64) ARCH='arm64' ;;
armv7l) ARCH='arm' ;;
*)
    log_message "Unsupported architecture"
    exit 1
    ;;
esac

# Terminal colors setup

Color_Off='\033[0m' # Reset
Green='\033[0;32m'  # Green
Red='\033[0;31m'
Bold_White='\033[1m' # Bold White

success() {
    log_message "${Green}$1${Color_Off}"
}

info_bold() {
    log_message "${Bold_White}$1${Color_Off}"
}

error() {
    log_message "${Red}error: $1${Color_Off}" >&2
    exit 1
}

# Log detected OS and architecture
log_message "Detected OS: $OS"
log_message "Detected Architecture: $ARCH"

# Check for curl
if ! command -v curl &>/dev/null; then
    error "curl is required but not installed."
fi

# Get installed FVM version if exists
INSTALLED_FVM_VERSION=""
if command -v fvm &>/dev/null; then
    INSTALLED_FVM_VERSION=$(fvm --version 2>&1) || error "Failed to fetch installed FVM version."
fi

# Define the URL of the FVM binary
if [ -z "$1" ]; then
    FVM_VERSION=$(curl -s https://api.github.com/repos/leoafarias/fvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$FVM_VERSION" ]; then
        error "Failed to fetch latest FVM version."
    fi
else
    FVM_VERSION="$1"
fi

log_message "Installing FVM version $FVM_VERSION."

# Setup installation directory and symlink
FVM_DIR="${FVM_DIR:-$HOME/.fvm_flutter}"
FVM_DIR_BIN="${FVM_DIR_BIN:-$FVM_DIR/bin}"
SYMLINK_TARGET="${FVM_SYMLINK_TARGET:-/usr/local/bin/fvm}"

# Create FVM directory if it doesn't exist
mkdir -p "$FVM_DIR_BIN" || {
    echo "Failed to create FVM directory: $FVM_DIR_BIN."
    exit 1
}

echo "FVM installation directory: $FVM_DIR"
echo "FVM binary directory: $FVM_DIR_BIN"
echo "FVM symlink target: $SYMLINK_TARGET"

# Check if FVM_DIR_BIN exists, and if it does delete it

if [ -d "$FVM_DIR_BIN" ]; then
    log_message "FVM bin directory already exists. Removing it."
    if ! rm -rf "$FVM_DIR_BIN"; then
        error "Failed to remove existing FVM directory: $FVM_DIR_BIN."
    fi
fi

# Download FVM
URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"
if ! curl -L "$URL" -o fvm.tar.gz; then
    error "Download failed. Check your internet connection and URL: $URL"
fi

# Extract binary to the new location
if ! tar xzf fvm.tar.gz -C "$FVM_DIR" 2>&1; then
    error "Extraction failed. Check permissions and tar.gz file integrity."
fi

# Cleanup
if ! rm -f fvm.tar.gz; then
    error "Failed to cleanup"
fi

# Rename FVM_DIR/fvm to FVM_DIR/bin
if ! mv "$FVM_DIR/fvm" "$FVM_DIR_BIN"; then
    error "Failed to move fvm to bin directory."
fi

# Create a symlink
if [ -n "${FVM_SYMLINK_TARGET}" ]; then
    # Skip sudo if FVM_SYMLINK_TARGET is explicitly set
    if ! ln -sf "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET"; then
        echo "Failed to create symlink at $SYMLINK_TARGET."
        exit 1
    fi
else
    # Use sudo for default SYMLINK_TARGET
    if ! sudo ln -sf "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET"; then
        echo "Failed to create symlink at $SYMLINK_TARGET with sudo."
        exit 1
    fi
fi

echo "Symlink created at $SYMLINK_TARGET pointing to $FVM_DIR_BIN/fvm"

tildify() {
    if [[ $1 = $HOME/* ]]; then
        local replacement=\~/

        echo "${1/$HOME\//$replacement}"
    else
        echo "$1"
    fi
}

tilde_FVM_DIR_BIN=$(tildify "$FVM_DIR_BIN")
refresh_command=''

case $(basename "$SHELL") in
fish)
    commands=(
        "set --export PATH $FVM_DIR_BIN \$PATH"
    )

    fish_config=$HOME/.config/fish/config.fish
    tilde_fish_config=$(tildify "$fish_config")

    if [[ -w $fish_config ]]; then
        {
            echo -e '\n# FVM'

            for command in "${commands[@]}"; do
                echo "$command"
            done
        } >>"$fish_config"

        log_message "Added \"$tilde_FVM_DIR_BIN\" to \$PATH in \"$tilde_fish_config\""
        refresh_command="source $tilde_fish_config"

    else
        log_message "Manually add the directory to $tilde_fish_config (or similar):"

        for command in "${commands[@]}"; do
            info_bold "  $command"
        done
    fi
    ;;
zsh)
    commands=(
        "export PATH=\"$FVM_DIR_BIN:\$PATH\""
    )

    zsh_config=$HOME/.zshrc
    tilde_zsh_config=$(tildify "$zsh_config")

    if [[ -w $zsh_config ]]; then
        {
            echo -e '\n# FVM'

            for command in "${commands[@]}"; do
                echo "$command"
            done
        } >>"$zsh_config"

        log_message "Added \"$tilde_FVM_DIR_BIN\" to \$PATH in \"$tilde_zsh_config\""
        refresh_command="source $zsh_config"

    else
        log_message "Manually add the directory to $tilde_zsh_config (or similar):"

        for command in "${commands[@]}"; do
            info_bold "  $command"
        done
    fi
    ;;
bash)
    commands=(
        "export PATH=$FVM_DIR_BIN:\$PATH"
    )

    bash_configs=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
    )

    if [[ ${XDG_CONFIG_HOME:-} ]]; then
        bash_configs+=(
            "$XDG_CONFIG_HOME/.bash_profile"
            "$XDG_CONFIG_HOME/.bashrc"
            "$XDG_CONFIG_HOME/bash_profile"
            "$XDG_CONFIG_HOME/bashrc"
        )
    fi

    set_manually=true
    for bash_config in "${bash_configs[@]}"; do
        tilde_bash_config=$(tildify "$bash_config")

        if [[ -w $bash_config ]]; then
            {
                echo -e '\n# FVM'

                for command in "${commands[@]}"; do
                    echo "$command"
                done
            } >>"$bash_config"

            log_message "Added \"$tilde_FVM_DIR_BIN\" to \$PATH in \"$tilde_bash_config\""
            refresh_command="source $bash_config"
            set_manually=false
            break
        fi
    done

    if [[ $set_manually = true ]]; then
        log_message "Manually add the directory to $tilde_bash_config (or similar):"

        for command in "${commands[@]}"; do
            info_bold "  $command"
        done
    fi
    ;;
*)
    log_message 'Manually add the directory to ~/.bashrc (or similar):'
    info_bold "  export PATH=\"$FVM_DIR_BIN:\$PATH\""
    ;;
esac

echo
log_message "To get started, run:"
echo

if [[ $refresh_command ]]; then
    info_bold "  $refresh_command"
fi

info_bold "  fvm --help"
