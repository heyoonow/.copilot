---
description: HEYNOW 웹 서버 배포 자동화 스킬. 현재 변경사항 확인 → 깃 푸시 여부 확인 → SSH로 서버에 접속해 deploy까지 한 번에 처리한다. "배포해줘", "서버 올려줘", "deploy", "web-deploy" 등의 요청에 트리거된다.
---

# Skill Instructions

당신은 HEYNOW 웹 서버 배포 전담 요원입니다. 아래 절차를 반드시 순서대로 수행하세요.

## 서버 접속 정보

```
Host: heynow-server
HostName: heynow.co.kr
User: root
Port: 22
IdentityFile: /Users/heyoonow/.ssh/id_rsa
```

SSH 명령 예시:

```bash
ssh -o StrictHostKeyChecking=no heynow-server "..."
```

## 배포 절차

### STEP 1. 현재 변경사항 확인

`git status`와 `git diff --stat`으로 로컬에 커밋되지 않은 변경사항이 있는지 확인합니다.

- 변경사항이 **없으면** → STEP 2로 바로 넘어갑니다.
- 변경사항이 **있으면** → 변경된 파일 목록을 대표님께 보여주고 `ask_user` 툴로 아래 질문을 합니다:

  > "로컬에 변경사항이 있습니다. 깃에 푸시하고 배포할까요?"
  > choices: ["푸시하고 배포 (Recommended)", "푸시 없이 배포", "취소"]

### STEP 2. 깃 푸시 (선택한 경우)

"푸시하고 배포"를 선택한 경우:

1. 변경 파일을 논리적 그룹으로 나눠 커밋합니다.
   - 커밋 메시지 형식: `[TAG] 한글 설명` (태그: FEAT/FIX/REFACTOR/CHORE/DOCS/STYLE)
   - 항상 Co-authored-by 트레일러 추가:
     `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
2. `git push`로 원격에 업로드합니다.
3. 푸시 완료 후 STEP 3으로 넘어갑니다.

### STEP 3. 서버 배포

SSH로 서버에 접속해 아래 명령을 실행합니다:

```bash
ssh -o StrictHostKeyChecking=no heynow-server "cd ~/heynow/web && git pull && docker compose up --build -d 2>&1"
```

- 빌드에는 1~3분 소요됩니다. 완료까지 기다립니다.
- 빌드 로그를 확인해 오류가 없는지 검증합니다.

### STEP 4. 배포 결과 확인

```bash
ssh -o StrictHostKeyChecking=no heynow-server "cd ~/heynow/web && docker compose ps"
```

모든 컨테이너(`heynow-app-container`, `heynow-nginx-container`, `heynow-mongodb-container`)가 `running` 상태인지 확인합니다.

### STEP 5. 보고

배포 결과를 대표님께 보고합니다:

- ✅ 성공 시: "대표님, 배포 완료했습니다. 모든 컨테이너 정상 기동 중입니다."
- ❌ 실패 시: 에러 로그를 분석해 원인을 설명하고 해결책을 제시합니다.

## 주의사항

- `dc` alias는 비대화형 SSH 세션에서 동작하지 않으므로 반드시 `docker compose`를 직접 사용합니다.
- 빌드 중 `MONGODB_URI` 에러가 나면 모든 API route에 `export const dynamic = "force-dynamic"`이 있는지 확인합니다.
- SSL 인증서 관련 이슈가 있으면 `certbot --expand` 명령을 안내합니다.
