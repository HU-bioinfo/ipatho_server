#!/usr/bin/env bash
#
# Ubuntu Server 用ユーザー作成スクリプト
# 使い方: sudo ./create_user.sh
# - ホームディレクトリにテンプレートを展開
# - SSH ログイン時に Podman コンテナを起動
# - PAT を docker‑compose.yml に書き込み
# --------------------------------------------

set -euo pipefail

# ---------- 共通メッセージ ----------
print_info()    { echo -e "\033[0;34m[INFO]\033[0m    $*"; }
print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }
print_error()   { echo -e "\033[0;31m[ERROR]\033[0m   $*"; }
print_warning() { echo -e "\033[0;33m[WARNING]\033[0m $*"; }

# ---------- 前提チェック ----------
[[ $EUID -eq 0 ]] || { print_error "root で実行してください"; exit 1; }

check_and_install_packages() {
    local -a pkgs=(yq podman)
    local -a missing=()

    for p in "${pkgs[@]}"; do command -v "$p" &>/dev/null || missing+=("$p"); done
    if ((${#missing[@]})); then
        print_info "不足パッケージをインストール: ${missing[*]}"
        apt update && apt install -y "${missing[@]}"
    fi
}

# ---------- テンプレート ----------
TEMPLATE_DIR=/usr/local/sbin/ipatho_server/home_template
check_home_template() {
    [[ -r $TEMPLATE_DIR ]] || { print_error "テンプレート $TEMPLATE_DIR が読めません"; exit 1; }
    for f in container/.devcontainer/{devcontainer.json,docker-compose.yml} .container_launcher.sh; do
        [[ -e $TEMPLATE_DIR/$f ]] || print_warning "必要ファイル欠落: $f"
    done
}

# ---------- ユーザー入力 ----------
get_username() {
    while true; do
        read -rp "ユーザー名: " username
        [[ $username =~ ^[a-z][a-z0-9_-]*$ ]] || { print_error "無効な形式"; continue; }
        id "$username" &>/dev/null && { print_error "既に存在します"; continue; }
        break
    done
}

get_github_pat() {
    while true; do
        read -rsp "GitHub PAT: " github_pat; echo
        [[ -n $github_pat ]] || { print_error "空です"; continue; }
        [[ $github_pat =~ ^gh[ps]_[A-Za-z0-9_]+ ]] || {
            read -n1 -rp "形式が怪しいですが続行しますか? (y/N): "; echo
            [[ $REPLY =~ [Yy] ]] || continue
        }
        break
    done
}

# ---------- セットアップ ----------
create_user_with_home() {
    useradd -m -s /bin/bash "$username"
    local home="/home/$username"

    print_info "テンプレートをコピー..."
    # 「.」を付けて隠しファイルも含め再帰コピー
    cp -a "$TEMPLATE_DIR/." "$home/"

    print_info "PAT を docker‑compose.yml に挿入..."
    local compose="$home/container/.devcontainer/docker-compose.yml"
    [[ -f $compose ]] && sed -i "s/GITHUB_PAT=.*/GITHUB_PAT=$github_pat/" "$compose"
    [[ -f $compose ]] && sed -i "s|^[[:space:]]*container_name:[[:space:]]*bioinfolauncher-.*|container_name: bioinfolauncher-$username|" "$compose"


    chown -R "$username:$username" "$home"
    chmod 700 "$home"

    # ランチャースクリプトの権限調整
    local launcher="$home/.container_launcher.sh"
    chmod +x "$launcher"
    chown "$username:$username" "$launcher"

    print_success "ユーザー $username 作成完了"
}

setup_ssh_shell() {
    local launcher="/home/$username/.container_launcher.sh"

    # /etc/shells に登録されていなければ追記
    grep -qxF "$launcher" /etc/shells || echo "$launcher" >> /etc/shells

    # ユーザーのログインシェルを直接変更
    usermod -s "$launcher" "$username"
    
    # 起動スクリプトの権限を厳格化
    chown root:root "$launcher"
    chmod 755 "$launcher"

    print_success "ログインシェルを $launcher に設定しました"
}

set_user_password() {
    print_info "パスワードを設定してください"
    passwd "$username"
}

setup_security() {
    usermod -aG podman "$username" 2>/dev/null || true
}

show_user_info() {
    local ip
    ip=$(hostname -I | awk '{print $1}')
    cat <<EOF
==============================
ユーザー名     : $username
ホーム         : /home/$username
ログインシェル : /home/$username/.ssh_wrapper.sh
SSH 接続例     : ssh $username@$ip
注意:
  - SSH 接続すると Podman コンテナが自動起動します
  - ホーム以下のみアクセス可能
  - PAT は ~/container/.devcontainer/docker-compose.yml に書き込まれています
==============================
EOF
}

# ---------- メイン ----------
main() {
    print_info "ユーザー作成を開始します"
    check_and_install_packages
    check_home_template
    get_username
    get_github_pat
    create_user_with_home
    setup_ssh_shell
    set_user_password
    setup_security
    show_user_info
    print_success "すべて完了しました！"
}

main "$@"
