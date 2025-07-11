# User Creation Script with Podman Container Integration

このプロジェクトは、Podman コンテナベースの開発環境を持つユーザーを自動で作成するスクリプトです。

## 概要

`create_user.sh` は以下の機能を提供します：
- 新しいユーザーの作成
- GitHub Personal Access Token (PAT) の設定
- Podman コンテナの自動起動設定
- SSH接続時のコンテナ起動による開発環境の提供

## 前提条件

- Ubuntu/Debian系のLinuxディストリビューション
- root権限またはsudo権限
- インターネット接続

## 必要なパッケージ

スクリプトは以下のパッケージを自動でインストールします：
- `yq` - YAML処理用
- `podman` - コンテナ実行環境

## テンプレート構造

スクリプトは以下のテンプレートファイルを期待しています：
```
$TEMPLATE_DIR/
├── container/
│   └── .devcontainer/
│       ├── devcontainer.json
│       └── docker-compose.yml
└── .container_launcher.sh
```

## 使用方法

### 1. スクリプトの実行

```bash
sudo ./create_user.sh
```

### 2. 対話形式での設定

スクリプトは以下の情報を対話形式で求めます：

1. **ユーザー名**
   - 形式: 小文字で始まり、小文字・数字・アンダースコア・ハイフンのみ
   - 例: `john`, `user_01`, `dev-user`

2. **GitHub Personal Access Token (PAT)**
   - GitHub の Personal Access Token を入力
   - 形式チェック: `ghp_` または `ghs_` で始まる形式を推奨

3. **パスワード**
   - 作成されたユーザーのパスワードを設定

## 機能詳細

### セキュリティ設定
- ユーザーを `podman` グループに追加
- ホームディレクトリ以下のみアクセス可能

### SSH接続時の動作
- SSH接続時に `.container_launcher.sh` が実行される
- Podman コンテナが自動起動
- 開発環境に直接接続

### 設定ファイル
- GitHub PAT は `~/container/.devcontainer/docker-compose.yml` に保存
- コンテナ設定は `.devcontainer/` ディレクトリで管理

## 接続方法

作成されたユーザーには以下のようにSSH接続できます：

```bash
ssh username@server_ip
```

接続すると自動的にPodmanコンテナが起動し、開発環境が利用可能になります。

## 注意事項

- SSH接続時にコンテナが自動起動するため、初回接続時は時間がかかる場合があります
- ユーザーはホームディレクトリ以下のみアクセス可能です
- GitHub PATは適切に管理し、必要に応じて定期的にローテーションしてください

## トラブルシューティング

### よくある問題

1. **パッケージインストールエラー**
   - `apt update` が失敗する場合は、インターネット接続を確認してください

2. **テンプレートファイルが見つからない**
   - `$TEMPLATE_DIR` 変数が正しく設定されているか確認してください
   - 必要なテンプレートファイルが存在するか確認してください

3. **SSH接続時にコンテナが起動しない**
   - `.container_launcher.sh` の実行権限を確認してください
   - Podmanサービスが正常に動作しているか確認してください

## 環境変数

スクリプトで使用される主な環境変数：
- `TEMPLATE_DIR` - テンプレートファイルのディレクトリパス

## ライセンス

このプロジェクトのライセンスについては、適切なライセンスファイルを参照してください。

## 貢献

バグ報告や機能要求は、プロジェクトのIssueトラッカーにて受け付けています。