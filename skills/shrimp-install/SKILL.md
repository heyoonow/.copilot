---
name: shrimp-install
description: "Shrimp Task Manager MCP를 처음 세팅하는 스킬. '새 프로젝트에 Shrimp 붙여줘', '태스크 매니저 설치해줘', 'Shrimp 세팅해줘' 같은 요청에 사용한다."
---

# Shrimp Task Manager — 설치편

> 별도 설치 없음. 파일 3개 + 폴더 1개로 끝난다.

---

## TODO

- [ ] 1. `.mcp.json` 생성
- [ ] 2. `shrimp_data/` 폴더 생성
- [ ] 3. `.gitignore` 추가
- [ ] 4. Claude Code에서 MCP 연결 확인

---

## Step 1. `.mcp.json` 생성

프로젝트 **루트**에 생성한다. (`.cursor/`, `src/` 안에 넣으면 안 됨)

```json
{
  "shrimp-task-manager": {
    "command": "npx",
    "args": ["mcp-shrimp-task-manager"],
    "env": {
      "DATA_DIR": "/절대경로/프로젝트명/shrimp_data",
      "ENABLE_GUI": "true",
      "ENABLE_THOUGHT_CHAIN": "true",
      "TEMPLATES_USE": "en"
    }
  }
}
```

> **⚠️ 절대경로 필수.** `./shrimp_data` 같은 상대경로는 동작 안 함.
> 현재 경로 확인: `pwd` 명령어로 확인 후 붙여넣기

**경로 예시:**

```
/Users/heynow/projects/my-app/shrimp_data   ← Mac
C:\Users\heynow\projects\my-app\shrimp_data  ← Windows
```

---

## Step 2. `shrimp_data/` 폴더 생성

`DATA_DIR`에 설정한 경로의 폴더가 실제로 존재해야 한다.

```bash
mkdir shrimp_data
```

> 폴더 없으면 MCP 실행 시 에러 발생. 반드시 먼저 만들 것.

---

## Step 3. `.gitignore` 추가

```gitignore
# Shrimp Task Manager
shrimp_data/
```

태스크 데이터는 로컬에만 유지. Git에 올리지 않는다.

---

## Step 4. Claude Code에서 MCP 연결 확인

Claude Code를 **재시작**하거나 MCP 새로고침 후:

```
/mcp
```

목록에 `shrimp-task-manager`가 뜨면 연결 성공 ✅

> 안 뜨면 `.mcp.json` 경로가 프로젝트 루트인지, `DATA_DIR` 절대경로가 맞는지 재확인.

---

## 완료 체크

```
✅ 프로젝트 루트에 .mcp.json 생성됨
✅ shrimp_data/ 폴더 생성됨
✅ .gitignore에 shrimp_data/ 추가됨
✅ /mcp 목록에 shrimp-task-manager 표시됨
```

완료되면 **shrimp-use 스킬**로 이동.