# Flutter Reversi

このプロジェクトは、Flutterで作成したリバーシゲームです。(お試しで作っております)

## 操作方法

- **石を置く**: 盤面上の空いているマスをタップしてください。
- **打てる場所の確認**: 現在の手番のプレイヤーが置ける場所に、小さなグレーの点が表示されます。
- **パス**: 置ける場所がない場合は、自動的に相手のターンに切り替わります。
- **タイトルへ戻る**: 画面下の「ゲームリセット」ボタンから、確認を経てタイトル画面（設定画面）に戻ることができます。

## ビルド・実行方法

### 前提条件

- Flutter SDK がインストールされていること

### 実行手順

1. ターミナルでプロジェクトルートに移動します：

2. 依存関係を解決します：

   ```bash
   flutter pub get
   ```

3. Windows または Web で実行します：

   ```bash
   flutter run -d windows
   # または
   flutter run -d chrome
   ```

## インストーラーの作成 (Windows)

本プロジェクトは MSIX 形式でのパッケージ化に対応しています。

### 作成手順

1. Windows用バイナリをビルドします：

   ```bash
   flutter build windows
   ```

2. MSIX インストーラーを生成します：

   ```bash
   flutter pub run msix:create
   ```

生成された `.msix` ファイルは `build\windows\x64\runner\Release` フォルダに保存されます。

## フォルダ構成

- `lib/domain`: ゲームの純粋なロジック（ルール）
- `lib/state`: Riverpod による状態管理
- `lib/presentation`: UI コンポーネントおよび画面
