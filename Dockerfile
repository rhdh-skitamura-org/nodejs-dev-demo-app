# syntax=docker/dockerfile:1

########################
# Stage 1 – deps (dev+prod ぜんぶ)
########################
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS deps
WORKDIR /opt/app-root/src

# パッケージ定義をコピーして依存を「全部」入れる
COPY package.json package-lock.json ./
RUN npm ci             # devDependencies も含む

########################
# Stage 2 – builder
########################
FROM deps AS builder
WORKDIR /opt/app-root/src

# ソースをコピーしてビルド
COPY . .
RUN npm run build      # ← esbuild が使える

########################
# Stage 3 – runner (最終イメージ)
########################
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS runner
WORKDIR /opt/app-root/src

### 1. OS パッチ適用（root 必須）
USER 0
RUN microdnf update -y && microdnf clean all
USER 1001

### 2. アプリ成果物だけコピー
COPY --from=builder --chown=1001:1001 /opt/app-root/src/dist          ./dist
COPY --from=builder --chown=1001:1001 /opt/app-root/src/package*.json ./

### 3. 本番依存だけ再インストール
RUN npm ci --omit=dev   # devDependencies を含めない

### 4. 実行設定
ENV NODE_ENV=production \
    PORT=3000
EXPOSE 3000

CMD ["node", "dist/index.js"]
