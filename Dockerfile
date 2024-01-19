# Build frontend dist.
FROM node:20-alpine AS frontend

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g' /etc/apk/repositories

WORKDIR /frontend-build

RUN npm config set registry http://mirrors.cloud.tencent.com/npm/

COPY . .

WORKDIR /frontend-build/web

RUN corepack enable && pnpm i --frozen-lockfile && pnpm type-gen

RUN pnpm build

# Build backend exec file.
FROM golang:1.21-alpine AS backend

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g' /etc/apk/repositories

ENV GO111MODULE="on"
ENV GOPROXY="https://goproxy.cn"

WORKDIR /backend-build

COPY . .

RUN CGO_ENABLED=0 go build -o memos ./bin/memos/main.go

# Make workspace with above generated files.
FROM alpine:latest AS monolithic

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g' /etc/apk/repositories

WORKDIR /usr/local/memos

RUN apk add --no-cache tzdata && rm -rf /var/cache/apk/* /tmp/*
ENV TZ="Asia/Shanghai"

COPY --from=frontend /frontend-build/web/dist /usr/local/memos/dist
COPY --from=backend /backend-build/memos /usr/local/memos/

EXPOSE 5230

# Directory to store the data, which can be referenced as the mounting point.
RUN mkdir -p /var/opt/memos
VOLUME /var/opt/memos

ENV MEMOS_MODE="prod"
ENV MEMOS_PORT="5230"

ENTRYPOINT ["./memos"]
