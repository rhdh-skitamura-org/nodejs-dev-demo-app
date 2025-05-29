# nodejs-dev-demo

このComponent では、OpenShift 上に CI/CD パイプラインを備えた Node.js サンプルアプリケーションをデプロイします。

## デプロイされるリポジトリ
この Golden Path を実行すると、以下 2 種類のリポジトリが生成されます。

* `nodejs-dev-demo-app` – アプリケーションのサンプルコードと Dockerfile を格納  
* `nodejs-dev-demo-manifest` – K8s マニフェストと CI/CD 関連ファイルを格納  

## 使い方
（テンプレートのスキャフォールド手順は後述）

---

## 前提条件 <!-- Prerequisites -->
- **OpenShift 4.17** 以降
- **Red Hat Developer Hub (RHDH)** 1.4 以降  
  - *TechDocs* ビルド環境と *Scaffolder* が有効
- **Tekton Pipelines / Triggers**
- **OpenShift GitOps (Argo CD)**（任意）
- コンテナイメージをプッシュできるレジストリ（OpenShift 内蔵 or Quay.io 等）

---

## リポジトリ構成 <!-- Repository layout -->

### 1. `nodejs-dev-demo-app`
```text
.
├── Dockerfile            # node:20-alpine ベース
├── app/                  # Express サンプル API
│   └── index.js
├── package.json
├── .eslint* / .prettierrc
└── tests/                # Jest + Supertest
```

### 2. `nodejs-dev-demo-manifest`
```text
.
├── k8s/
│   ├── deployment.yaml      # Deployment / Service / Route
│   └── kustomization.yaml
├── pipelines/
│   ├── pipeline.yaml        # Build → Push → Deploy
│   ├── tasks/               # buildah, kubectl-apply など
│   └── triggers/            # Git push 用 TriggerTemplate
└── overlays/
    ├── dev/
    ├── stage/
    └── prod/                # 環境別上書き
```

---

## テンプレートのスキャフォールド手順 <!-- How to scaffold -->

1. Developer Hub → **Create**  
2. **Node.js Golden Path** テンプレート → *Choose*  
3. フォームに値を入力して *Create*  
4. 数十秒後、Git に 2 つのリポジトリが作成され、Catalog に登録されます

---

## CI/CD パイプラインの流れ <!-- Pipeline overview -->

```mermaid
graph TD
    A[Webhook (push)] -->|Trigger| B[PipelineRun]
    B --> C[Build (buildah)]
    C --> D[Push image]
    D --> E[Deploy to dev]
    E --> F[Smoke test]
    F --> G[Manual approval]
    G --> H[Deploy to stage/prod]
```

1. **Git push** が発火点  
2. `buildah` でイメージビルド  
3. レジストリへプッシュ  
4. `overlays/dev` を適用  
5. `/healthz` をチェック  
6. ステージ/本番は Argo CD 同期 + 手動承認

---

## ローカル開発 & デバッグ <!-- Local development -->

```bash
git clone https://github.com/rhdh-skitamura-org/nodejs-dev-demo-app.git
cd nodejs-dev-demo-app

npm ci        # 依存関係
npm test      # 単体テスト
npm run dev   # nodemon でホットリロード
```

OpenShift 上でデバッグする場合は `odo dev` を利用し、VS Code の Remote Attach を行います。

---

## カスタマイズのポイント <!-- Customization tips -->

| 変更対象 | 例 | 影響範囲 |
| -------- | --- | -------- |
| Node.js バージョン | `FROM node:18-alpine` | CI イメージ / ローカル |
| 環境変数 | `deployment.yaml` の `env:` | ランタイム |
| パイプライン Task | `pipelines/tasks/*.yaml` | CI/CD ロジック |
| Kustomize オーバレイ | `overlays/prod/hpa.yaml` | 本番スケール戦略 |

---

## よくあるエラーと対処 <!-- Troubleshooting -->

| 症状 | 原因 | 解決策 |
| ---- | ---- | ------ |
| `unable to push image` | レジストリ認証失敗 | SA に `registry-editor` ロール付与 |
| `CrashLoopBackOff` | `PORT` 不一致 | YAML とコードのポートを統一 |
| Argo CD `OutOfSync` | `kustomization.yaml` 更新漏れ | 新リソースを追加 |

---

## 参考リンク <!-- References -->
- [Red Hat Developer Hub Docs](https://access.redhat.com/documentation/en-us/red_hat_developer_hub/)
- [Tekton Pipelines](https://tekton.dev/)
- [OpenShift Pipelines Operator](https://docs.openshift.com/container-platform/latest/cicd/pipelines/understanding-openshift-pipelines.html)
- [Argo CD](https://argo-cd.readthedocs.io/)
