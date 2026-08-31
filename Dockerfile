# [변경: 2026-08-28 17:10, 김병현 수정] Scratch GUI 배포용 Dockerfile 추가.
# 로컬 개발(PM2)은 계속 `npm run start`(webpack dev server, 9007)를 쓰고,
# 이 Dockerfile 은 배포용 정적 빌드만 담당한다.
FROM node:20 AS builder

WORKDIR /app

# 의존성 먼저 설치해서 소스가 바뀌어도 이 레이어는 캐시가 살아있게 한다.
# scripts/ 를 같이 복사하는 이유: npm ci 가 prepublish(scripts/prepublish.mjs)를
# 실행해서 micro:bit HEX 같은 정적 자산을 내려받기 때문이다.
COPY package.json package-lock.json ./
COPY scripts ./scripts
RUN npm ci

# 소스 복사 후 정적 사이트 빌드 (결과물은 build 에 떨어진다)
# NODE_ENV 를 production 으로 두지 않는 이유: 그러면 라이브러리용 dist 까지
# 같이 빌드해서 시간이 두 배로 드는데, 배포에는 build 만 필요하다.
COPY . .
RUN npm run build

FROM nginx:alpine AS production

# Caddy 가 scratch:9007 로 프록시하므로 nginx 도 9007 에서 듣게 맞춘다
RUN sed -i 's/listen\( *\)80;/listen\19007;/' /etc/nginx/conf.d/default.conf

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 9007

CMD ["nginx", "-g", "daemon off;"]
