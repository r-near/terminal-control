#!/bin/sh
# Install the latest prebuilt termctrl from r-near/terminal-control releases.
# Usage: curl -fsSL https://raw.githubusercontent.com/r-near/terminal-control/main/install.sh | sh
# Set TERMCTRL_INSTALL_DIR to change the destination (default: ~/.local/bin).
set -eu

repo=r-near/terminal-control
dir=${TERMCTRL_INSTALL_DIR:-$HOME/.local/bin}

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) package=darwin-arm64 ;;
  Darwin-x86_64) package=darwin-x64 ;;
  Linux-aarch64 | Linux-arm64) package=linux-arm64-gnu ;;
  Linux-x86_64) package=linux-x64-gnu ;;
  *)
    echo "No prebuilt termctrl for $(uname -s) $(uname -m). Build from source:" >&2
    echo "  cargo install --locked --git https://github.com/$repo terminal-control" >&2
    exit 1
    ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://github.com/$repo/releases/latest/download/termctrl-$package.tar.gz" | tar -xz -C "$tmp"
mkdir -p "$dir"
install -m 755 "$tmp/termctrl" "$dir/termctrl"
echo "Installed $("$dir/termctrl" --version) to $dir/termctrl"
case ":$PATH:" in
  *":$dir:"*) ;;
  *) echo "Add $dir to PATH to use termctrl." ;;
esac
