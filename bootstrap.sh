#!/usr/bin/env bash
# マイソースの Claude Code 環境を入れる入口。ターミナルに次の1行を貼って実行する:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mysource-inc/claude-starter/main/bootstrap.sh)"
# ここでは GitHub にログインして非公開のキット本体を取ってくるだけ。中身のインストールは本体の setup.sh が行う。
set -euo pipefail

KIT_REPO="mysource-inc/claude-skills"
KIT_DIR="$HOME/Claude/_repos/claude-skills"

[ "$(uname)" = "Darwin" ] || { echo "このセットアップは Mac 専用です。" >&2; exit 1; }

echo "▶ 準備（1/3）: Mac の開発用ツール"
if ! xcode-select -p >/dev/null 2>&1; then
  echo "  画面に出るウィンドウで「インストール」を押してください。終わったら、もう一度この1行を貼ってください。"
  xcode-select --install || true
  exit 0
fi

echo "▶ 準備（2/3）: Homebrew と GitHub の道具"
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)"; done
if ! command -v brew >/dev/null; then
  echo "  Mac のパスワードを聞かれたら入力してください（入力中の文字は表示されません）。"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$b" ] && eval "$("$b" shellenv)"; done
fi
command -v gh >/dev/null || brew install gh

echo "▶ 準備（3/3）: GitHub にログイン"
if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "  ブラウザが開きます。画面に出る8桁のコードを入力し、「Authorize」を押してください。"
  gh auth login -h github.com -p https -w
fi
gh auth setup-git >/dev/null 2>&1 || true

if [ -d "$KIT_DIR/.git" ]; then
  git -C "$KIT_DIR" pull --ff-only -q
else
  mkdir -p "$(dirname "$KIT_DIR")"
  if ! gh repo clone "$KIT_REPO" "$KIT_DIR" -- -q; then
    echo
    echo "キット本体を取得できませんでした。会社からの GitHub 招待メールを受け取って「Accept」を押してから、もう一度この1行を貼ってください。" >&2
    exit 1
  fi
fi

exec bash "$KIT_DIR/setup.sh" "$@"
