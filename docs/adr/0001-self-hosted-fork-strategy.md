# ADR 0001: Self-hosted fork strategy for the macOS app

- Status: Accepted
- Date: 2026-04-13

## Context

このフォークでは、公式 Omi macOS アプリの利便性はなるべく維持しつつ、
プライバシーと運用責任の置き場所を見直したい。

特に次の前提を置く。

- Omi 社が運用するサーバーに個人情報や機微な画面・音声データを置かない
- ただし OpenAI / Gemini など、こちらで許容する外部 AI への送信はあり得る
- 公式 upstream にできる限り追従しやすい形でカスタマイズする
- 既存コードの直接改変は最小限にし、新規ファイルと差し込み口で拡張する
- 自分用ビルドとして署名・配布し、公式配布アプリの設定画面には依存しない

確認した範囲では、公式配布済みの macOS アプリは設定画面から送信先を柔軟に差し替える設計ではない。
一方で、ソースコード版は `OMI_API_URL` / `OMI_PYTHON_API_URL` などの環境変数で接続先を切り替える前提がすでにある。

## Decision

このフォークでは、以下の方針を採用する。

1. 公式リポジトリをフォークし、upstream 追従を前提に運用する。
2. 公式のクラウド前提機能を、そのまま設定画面で切り替えることは目指さない。
3. 自前ビルドの macOS アプリとして、接続先・認証・保存先を自前インフラ向けに差し替える。
4. 差し替えは既存コードの全面書き換えではなく、薄い差し込み口を追加して新規ファイル側で実装する。
5. 自前ビルドは公式アプリとは別の識別子で運用する。

## Architectural principles

### 1. Existing-code changes must stay small

既存コードへの変更は、原則として次のいずれかに限る。

- 設定取得の窓口を 1 箇所に寄せる
- 実装を選択する factory / provider / protocol を追加する
- 既存の直参照 (`getenv`, 直 URL, 直クライアント生成) を差し込み口経由に置き換える

業務ロジックを既存ファイル上で大きく書き換えることは避ける。

### 2. New behavior lives in new files

自前インフラ向けの実装は、できるだけ新規ファイルへ置く。
想定例:

- `CustomBackendConfig`
- `SelfHostedAPIClientAdapter`
- `SelfHostedGeminiProxyClient`
- `SelfHostedTranscriptionService`
- `SelfHostedAuthProvider`

### 3. Build variant, not runtime UI toggle

公式配布アプリの設定画面で切り替えるのではなく、
自前ビルドの構成として切り替える。

切り替えは次のいずれかで行う。

- `.env`
- 環境変数
- ビルド設定
- コンパイルフラグ

### 4. Separate app identity from the official app

自前ビルドは、公式アプリと別の識別子で運用する。
少なくとも次を分離する。

- App Name
- Bundle ID
- URL scheme
- Code signing identity

理由:

- TCC 権限の衝突を避ける
- Launch Services / auth callback の混乱を減らす
- 公式版と自前版を同じマシンに共存しやすくする

## Scope of self-hosting

この ADR 時点では、「完全ローカル完結」は必須としない。
まずは次を Omi 社管理外へ出すことを優先する。

- API endpoint
- 認証基盤
- 画面活動データの保存先
- 会話 / メモリー / タスクの保存先
- AI プロキシの制御点

OpenAI / Gemini など、こちらが許容する外部 AI ベンダーへの送信は、
自前インフラまたは自前ビルドから明示的に制御する。

## Initial migration order

優先順位は次の順にする。

1. バックエンド URL の自前化
2. 画面活動同期の自前化
3. Gemini / embedding プロキシの自前化
4. 認証の自前化
5. 音声転写系の自前化

この順により、差分を小さく保ちながら upstream 追従性を落としにくくする。

## Consequences

### Positive

- Omi 社の管理するサーバーに機微データを置かずに済む
- upstream を追いながら、自前運用の必要部分だけ差し替えやすい
- 問題発生時の責任境界を、自分のインフラ基準で明確にしやすい

### Negative

- 公式配布版の設定画面だけでは達成できず、自前ビルド運用が前提になる
- 最初に差し込み口を作るための最小限の既存コード変更は避けられない
- Firebase など、公式クラウド前提の周辺依存を段階的に剥がす必要がある

## Non-goals

現時点では次は決めない。

- 完全ローカル LLM / STT への全面移行
- 公式 upstream へ戻すための一般化された PR 方針
- モバイル版まで含む全面セルフホスト化

## Follow-up decisions

後続 ADR で少なくとも次を決める。

- 自前ビルドで使う App Name / Bundle ID / URL scheme
- 設定取得層の API と配置場所
- 認証を Firebase のまま残すか、自前認証へ移すか
- 画面活動データの保存モデルと保持期間
- 外部 AI へ送ってよいデータ境界
