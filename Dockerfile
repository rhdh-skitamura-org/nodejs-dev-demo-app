# syntax=docker/dockerfile:1

########################
# Stage 1 – deps
########################
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS deps

WORKDIR /opt/app-root/src
COPY package.json package-lock.json ./

# prod 依存だけインストール
RUN npm ci --omit=dev

########################
# Stage 2 – builder
########################
FROM deps AS builder

WORKDIR /opt/app-root/src
COPY . .
RUN npm run build          # dist/ を生成

########################
# Stage 3 – runner (final)
########################
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS runner

WORKDIR /opt/app-root/src

# --- 1) OS を最新化（root 権限） ---
USER 0
RUN microdnf update -y && microdnf clean all
USER 1001

# --- 2) アプリと依存をコピー ---
# node_modules は deps ステージで作ったものをそのまま
COPY --from=deps    --chown=1001:1001 /opt/app-root/src/node_modules ./node_modules
COPY --from=builder --chown=1001:1001 /opt/app-root/src/dist          ./dist
COPY --from=builder --chown=1001:1001 /opt/app-root/src/package*.json ./

# nodemon は devDependencies 扱いなので runner には含まれない

# --- 3) 実行設定 ---
ENV NODE_ENV=production \
    PORT=3000
EXPOSE 3000

CMD ["node", "dist/index.js"]
