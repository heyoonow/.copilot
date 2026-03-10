---
name: flutter-debugging
description: "Flutter 앱의 버그 수정, 버전 충돌 해결, 코드 구조 개선을 담당한다. 단순 에러 수정이 아니라 근본 원인 파악 후 더 나은 구조로 개선한다. 에러, 크래시, 버전 충돌, 성능 이슈, 플러그인 문제 등 Flutter 관련 문제가 발생하면 이 스킬을 사용한다."
---

# Flutter Debugging

단순히 에러를 고치지 않는다. 왜 발생했는지 파악하고, 더 나은 구조로 개선한다.
버전은 철저히 확인하고, 최신 best practice로 맞춘다.

---

## 참조 문서 로딩 (문제 유형별 필요한 것만 읽는다)

| 문제 유형                                          | 읽을 파일        | 해당 상황 예시                                               |
| -------------------------------------------------- | ---------------- | ------------------------------------------------------------ |
| 에러 원인 파악 / 레이어 진단 / 증상별 원인 표      | `./diagnosis.md` | ProviderException, null crash, 빌드 에러, 타입 불일치        |
| 패키지 버전 충돌 / dependency 정리 / Firebase BOM  | `./versions.md`  | pub get 실패, 충돌 경고, 패키지 업그레이드                   |
| 안티패턴 개선 / best practice 교체 / 성능 최적화   | `./fixes.md`     | BuildContext async 사용, initState ref 접근, 불필요한 리빌드 |
| Android·iOS 네이티브 에러 / Pod 충돌 / Gradle 실패 | `./platform.md`  | Gradle 빌드 실패, Pod 에러, 아키텍처 문제                    |

**여러 유형에 해당하면 해당하는 파일 모두 읽는다.**

예시: 버전 충돌 + 마이그레이션 → `./versions.md` + `./fixes.md`
예시: iOS 빌드 실패 + Pod 에러 → `./platform.md`
예시: 에러 원인 불명 → `./diagnosis.md` 먼저

---

## 디버깅 6단계

### STEP 1 — 현황 파악 (항상 가장 먼저)

```bash
# Flutter + 패키지 버전 전체 확인
fvm flutter --version
cat pubspec.yaml | grep -A 100 "dependencies:"
fvm flutter pub deps

# 에러 전체 수집
fvm flutter analyze
fvm flutter pub get 2>&1
```

에러가 어느 레이어에서 발생했는지 확인 후 `./diagnosis.md` 참조.

### STEP 2 — 버전 호환성 검증

버전 정보는 항상 웹 검색으로 최신 확인 — 내부 지식 믿지 않는다.
`./versions.md` 참조.

### STEP 3 — 근본 원인 분석

에러 메시지만 보고 덮어쓰지 않는다. 왜 발생했는지.
`./diagnosis.md`의 증상별 원인 표 참조.

### STEP 4 — Best Practice 검색

고치기 전에 현재 방식이 최선인지 확인.
`./fixes.md` 참조.

### STEP 5 — 수정 + 구조 개선

에러만 고치지 않는다. 더 나은 구조가 가능하면 함께 개선.

**개선 우선순위:**

1. 컴파일 에러 / 크래시 → 즉시 수정
2. 버전 충돌 → 호환되는 버전으로 정리
3. 안티패턴 발견 → 올바른 패턴으로 교체
4. 중복 코드 → 공통화
5. 성능 이슈 → 최적화

### STEP 6 — 검증

```bash
# 전체 분석
fvm flutter analyze

# 빌드 확인
fvm flutter build apk --debug
fvm flutter build ios --debug --no-codesign

# 모델 변경 시 build_runner 재생성
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 절대 원칙

| 원칙                             | 내용                                       |
| -------------------------------- | ------------------------------------------ |
| 버전은 항상 웹 검색              | pub.dev, 공식 docs — 내부 지식 믿지 않는다 |
| 에러 덮어쓰기 금지               | 왜 발생했는지 파악 후 수정                 |
| `dependency_overrides` 남발 금지 | 근본 해결이 우선, 불가피할 때만            |
| `fvm flutter clean` 만능 아님    | 원인 파악 후 사용                          |
| build_runner 파일 커밋 O         | 항상 재생성 가능해야 함                    |
| 수정 후 반드시 확인              | `fvm flutter analyze` 통과 필수            |
