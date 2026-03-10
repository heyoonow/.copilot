---
name: shrimp-install
description: "Shrimp Task Manager MCP 최초 설치 및 환경 설정. 프로젝트에 Shrimp를 처음 세팅할 때만 사용한다."
---

# Shrimp Task Manager — 설치 및 세팅

별도 설치 없이 두 파일만 만들면 된다.

---

## 1. 프로젝트 루트에 `.mcp.json`

```json
{
  "shrimp-task-manager": {
    "command": "npx",
    "args": ["mcp-shrimp-task-manager"],
    "env": {
      "DATA_DIR": "/절대경로/프로젝트명/shrimp_data",
      "ENABLE_GUI": "true"
    }
  }
}
```

`DATA_DIR`은 프로젝트 루트 기준 절대경로로 설정한다. 프로젝트마다 다른 경로를 써야 한다.

---

## 2. `shrimp_data` 폴더 생성

`DATA_DIR`에 설정한 경로의 폴더가 실제로 존재해야 한다. 없으면 MCP가 실행되지 않으니 반드시 미리 만들어둔다.

---

## 3. `.gitignore`에 추가

```
shrimp_data/
```

태스크 데이터는 로컬에만 유지하고 Git에는 올리지 않는다.

---

## 환경변수 옵션

| 변수                   | 기본값 | 설명                                             |
| ---------------------- | ------ | ------------------------------------------------ |
| `DATA_DIR`             | 필수   | 태스크 저장 경로 (절대경로, 프로젝트별로 다르게) |
| `ENABLE_THOUGHT_CHAIN` | `true` | 단계별 사고 과정 활성화 (권장)                   |
| `TEMPLATES_USE`        | `en`   | 언어 템플릿 (`en` / `zh`)                        |
| `ENABLE_GUI`           | `true` | 웹 UI 활성화 (기본 활성화)                       |
