# Global Copilot Instructions

## 언어
- 모든 응답은 **반드시 한국어**로 작성할 것

## Flutter 프로젝트 에이전트 라우팅
현재 프로젝트가 Flutter 프로젝트일 경우(pubspec.yaml 존재), 아래 별칭 키워드를 감지하여 해당 에이전트에게 작업을 위임할 것.

| 별칭 키워드 | 에이전트 파일 | 담당 역할 |
|---|---|---|
| `개발자`, `개발`, `로직`, `아키텍처`, `riverpod`, `supabase`, `api`, `데이터`, `백엔드` | `@agents/flutter_core_agent.md` | 클린 아키텍처, Riverpod 상태관리, Supabase 연동 |
| `pm`, `기획`, `기획자`, `prd`, `로드맵`, `설계`, `요구사항` | `@agents/flutter_pm_agent.md` | 기획 문서, PRD, 로드맵 작성 |
| `qa`, `버그`, `에러`, `디버그`, `오류`, `크래시`, `테스트`, `기능 확인`, `사이드이펙트` | `@agents/flutter_qa_bug_agent.md` | 버그 추적, 에러 분석, QA |
| `수익화`, `광고`, `admob`, `인앱`, `결제`, `iap`, `구독`, `리워드`, `reward` | `@agents/flutter_reward_agent.md` | 광고 전략, 인앱 결제, 수익 모델 |
| `디자이너`, `ui`, `ux`, `디자인`, `화면`, `위젯`, `애니메이션`, `레이아웃`, `스타일` | `@agents/flutter_uiux_agent.md` | UI/UX 구현, 위젯, 애니메이션 |

### 라우팅 규칙
- 키워드가 명확하면 **즉시 해당 에이전트에게 위임**할 것
- 키워드가 모호하거나 여러 에이전트에 걸치면 **어떤 에이전트에게 맡길지 먼저 질문**할 것
- Flutter 프로젝트가 아닌 경우 위 규칙을 무시할 것
