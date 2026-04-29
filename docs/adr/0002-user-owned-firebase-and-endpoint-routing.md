# ADR 0002: User-owned Firebase and centralized endpoint routing for the macOS fork

- Status: Accepted
- Date: 2026-04-13

## Context

ADR 0001 では、このフォークの「self-hosted」を
「Omi 社が管理する基盤から出すこと」と定義した。

一方で、現行の macOS 実装は次の状態にある。

- `OMI_API_URL` / `OMI_PYTHON_API_URL` / `OMI_AUTH_URL` による切り替え口は一部すでにある
- ただし実行時コードの一部は `https://api.omi.me` を直に参照している
- 認証・データ保存は Firebase Auth / Firestore への依存が強い
- そのため、URL だけ差し替えても「実はまだ Omi 管理基盤に接続している」状態が起きうる

このフォークで避けたいのは
「外部サービスを一切使うこと」ではなく、
「Omi 社が管理する基盤に機微データと運用責任を置くこと」である。

## Decision

このフォークでは、次を採用する。

1. self-hosted の意味を「自分で管理できる基盤を使うこと」とする。
2. Firebase / Firestore / GCP は引き続き利用してよい。ただし使うのは自分の Firebase プロジェクトに限る。
3. Omi 社管理の Firebase プロジェクト、Firestore、Auth、API エンドポイントは、このフォークの本番運用先にしない。
4. 長期的には、`api.omi.me` を含む Omi 社管理 URL を実行時コードへ直書きしない状態を目指す。
5. 長期的には、接続先の解決を 1 箇所の設定層へ集約し、各機能はその設定層だけを見る。
6. ただし最初の安全策として、既存ソースの広範囲な変更よりも起動前の endpoint preflight を優先する。

## What stays allowed

次は許容する。

- 自分の Firebase Auth
- 自分の Firestore
- 自分の Firebase Storage
- 自分の GCP 上の API
- 自分が許容し、明示的に設定した外部 AI ベンダー

つまり、この段階では
「完全ローカル化」や「Firebase 廃止」は目標にしない。

## Endpoint policy

今後の macOS フォークでは、実行時の HTTP / WebSocket 接続先を
新しい設定層に集約する。

最低でも次を設定対象に含める。

- Python API base URL
- Rust desktop backend base URL
- Auth base URL
- Transcription / listen pipeline が参照する base URL
- App update / appcast が参照する base URL

ルールは次の通り。

- 実行時コードで `https://api.omi.me` を直接組み立てない
- 実行時コードで `getenv("OMI_*")` を各所から直接読まない
- 既存コードは、薄い adapter / provider を経由する形に寄せる
- どうしても一時的な例外を残す場合は、設定層に明示し、コメントと文書で理由を残す

## Current guardrail

この ADR の最終形は endpoint 設定層への集約だが、最初の実装では
`desktop/run-self-hosted.sh` を self-hosted 起動入口にする。

このスクリプトは `desktop/self-hosted.env` などから `OMI_PYTHON_API_URL` と
`OMI_DESKTOP_API_URL` を読み、値が空または Omi 社管理 backend を指す場合は
アプリ起動前に失敗する。

この段階では、Swift / TypeScript / JavaScript 側の既存 fallback は大きく変更しない。
理由は、upstream 追従を優先し、まず「適切な env なしでは起動しない」状態を
小さい差分で作るためである。

## Migration plan for `api.omi.me`

`api.omi.me` 差し替えは、次の順で進める。

1. まず、self-hosted 起動入口で必須 endpoint の preflight を行う。
2. 次に、直書き URL と `getenv` 直参照を棚卸しする。
3. そのあと、挙動を変えずに設定層を追加する。
4. 各呼び出し元を設定層経由へ置き換える。
5. 置き換え後に、自前 Firebase / 自前 API の値へ切り替える。
6. 最後に、grep とテストで Omi 管理 URL の取りこぼしを確認する。

最初から接続先を変えながらリファクタするのではなく、
先に参照経路だけを 1 本化する。
これにより、差分を小さく保ち、upstream 追従をしやすくする。

## Initial implementation order

実装の着手順は次を優先する。

1. self-hosted 起動前 preflight の追加
2. URL 解決層の追加
3. `api.omi.me` 直書き箇所の置き換え
4. `GoogleService-Info*.plist`、Firebase API key、service account などの自分用プロジェクト化
5. Auth callback と token 検証先の自分用プロジェクト化
6. Firestore / Storage / screen activity 保存先の自分用プロジェクト化

この順なら、認証やデータ移行に入る前に
「どこへ通信するか」を安全に観測・制御できる。

## Consequences

### Positive

- self-hosted の意味が明確になる
- Firebase 依存を残しても、Omi 社管理基盤からは切り離せる
- URL 差し替え漏れによる意図しない送信を減らせる
- upstream 追従時の衝突を、設定層の周辺へ閉じ込めやすい

### Negative

- 設定層を経由するため、最初に小さな整理コストがかかる
- Firebase の project / key / plist / service account を自前で管理する必要がある
- update feed など、ユーザーデータとは直接関係しない経路も整理対象になる

## Non-goals

現時点では次は決めない。

- Firebase を即座に廃止すること
- 独自認証基盤へすぐ移行すること
- モバイル版も同じタイミングで切り替えること

## Follow-up work

次の作業では少なくとも次を行う。

- macOS 側の endpoint 設定層の名前と配置場所を決める
- `api.omi.me` 直書き箇所を洗い出して一覧化する
- 自分用 Firebase プロジェクトで必要な設定項目を整理する
