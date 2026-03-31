# Decision 0004 — Nginx 보안 헤더 및 버전 정보 숨기기

## 왜 하게 됐나

Day16 점검에서 두 가지 문제를 발견했다.

첫째, curl -I 로 nginx 응답을 보면 Server: nginx/1.24.0 (Ubuntu) 처럼
버전 정보가 그대로 노출되고 있었다.
공격자 입장에서는 버전만 알아도 그 버전의 취약점을 바로 검색할 수 있다.

둘째, 보안 헤더가 하나도 없었다.
보안 헤더는 브라우저한테 "이렇게 동작해"라고 지시하는 설정인데,
없으면 브라우저가 멋대로 동작할 수 있다.

또한 access.log에서 외부 IP(194.163.183.223)가
우리 서버의 여러 경로를 탐색한 흔적도 발견했다.
이 시점에서 기본적인 응답 헤더 보안을 갖추기로 했다.

## 무엇을 적용했나

1. server_tokens off
   - nginx 응답에서 버전 정보를 숨긴다.
   - 적용 위치: /etc/nginx/nginx.conf (전역 설정)

2. X-Content-Type-Options: nosniff
   - 브라우저가 파일 타입을 멋대로 판단하지 못하게 막는다.
   - 예: 서버가 "이건 이미지야"라고 해도 브라우저가 "아닌데?"하고
     스크립트로 실행하려는 걸 차단한다.

3. X-Frame-Options: DENY
   - 내 사이트를 다른 페이지의 iframe 안에 넣지 못하게 막는다.
   - 공격자가 투명 iframe으로 사용자 클릭을 가로채는 걸 방지한다.

4. X-XSS-Protection: 1; mode=block
   - 브라우저가 수상한 스크립트를 감지하면 페이지를 아예 차단한다.
   - 적용 위치: /etc/nginx/sites-available/default (사이트별 설정)

## 한계와 선택 이유

- X-XSS-Protection은 요즘 최신 브라우저(Chrome, Firefox)에서는
  이미 지원을 끊은 헤더다.
  그래도 구형 브라우저 대응과 보안 점수 기준 때문에 일단 포함했다.


## 확인 결과

- curl -I http://localhost → 버전 정보 제거 + 헤더 3개 확인
- curl -I http://localhost/app → /app 경로에도 동일하게 적용 확인