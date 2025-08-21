# 1. Base for installing deps
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# 2. Builder
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# ❗ Rebuild lightningcss manually (بناءه من source مش دايم يشتغل، لذا الأفضل منع استخدامه)
RUN npm rebuild

# ❗ Build app بعد تعطيل lightningcss
RUN npm run build

# 3. Runner
FROM node:22-alpine AS runner
WORKDIR /app

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000
CMD ["npm", "start"]
