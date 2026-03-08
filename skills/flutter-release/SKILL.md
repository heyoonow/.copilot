---
description: Flutter AAB/IPA 빌드, 버전 전략 선택, Git 자동화 및 TestFlight 즉시 업로드를 수행합니다.
---

# Skill Instructions

당신은 배포 명령 시 발동되는 '릴리즈 스킬'입니다. 다음 절차를 순차적으로 수행하세요.

## 0단계. 빌드 대상 플랫폼 결정

요청 메시지에서 플랫폼 키워드를 감지하여 빌드 대상을 결정한다. **별도 질문 없이 즉시 판단한다.**

| 요청 키워드                                       | 빌드 대상               |
| ------------------------------------------------- | ----------------------- |
| 키워드 없음 (예: "배포 빌드 해줘", "릴리즈 해줘") | **Android + iOS 둘 다** |
| `aos`, `안드`, `안드로이드`, `android`            | **Android만**           |
| `ios`, `아이폰`, `아이오에스`                     | **iOS만**               |
| `aos, ios`, `안드 ios`, `둘다` 등 둘 다 명시      | **Android + iOS 둘 다** |

결정된 플랫폼을 첫 줄에 명시한 뒤 바로 다음 단계로 진행한다.  
예: `🎯 빌드 대상: Android + iOS`

---

## 1단계. 버전 전략 승인 (대표님 확인 필수)

작업을 시작하기 전, 반드시 대표님께 다음과 같이 질문하고 답변을 기다린다.

현재 `pubspec.yaml`의 버전을 먼저 확인한 뒤, 아래 선택지를 `ask_user` 로 제시한다.

예시 (현재 버전이 `1.3.1+34`인 경우):

> **"대표님, 이번 배포의 버전 전략을 선택해 주십시오. (현재: 1.3.1+34)"**
>
> 1. 패치 버전 + 빌드 번호 올리기 → `1.3.2+35`
> 2. 마이너 버전 + 빌드 번호 올리기 → `1.4.0+35`
> 3. 메이저 버전 + 빌드 번호 올리기 → `2.0.0+35`
> 4. 버전 유지, 빌드 번호만 올리기 → `1.3.1+35`

대표님의 선택에 따라 `pubspec.yaml` 수정 계획을 세운다.

---

## 2단계. 버전 및 변경점 분석

- 승인된 전략에 따라 버전을 계산한다.
- 최근 Git 커밋 로그를 분석하여 앱 스토어용 **한국어/영어 릴리즈 노트**를 미리 작성해 둔다.

---

## 3단계. 자동 업데이트 및 Git 작업

- `pubspec.yaml`의 버전을 확정된 번호로 수정 후 저장한다.
- 터미널 실행: `git add .`, `git commit -m "chore: release v[버전]"`, `git tag v[버전]`

---

## 4단계. 플랫폼별 빌드 실행

**0단계에서 결정된 플랫폼에 해당하는 명령만 실행한다.**

```bash
# Android 빌드 (Android 대상 시 실행)
fvm flutter build appbundle

# iOS 빌드 (iOS 대상 시 실행)
fvm flutter build ipa --export-method app-store
```

빌드 완료 후 `.ipa` 파일 경로를 정확히 확보한다.

---

## 5단계. TestFlight 자동 업로드

**iOS 빌드가 포함된 경우에만 실행한다.**

```bash
xcrun altool --upload-app --type ios \
  --file "확인된_IPA_경로" \
  --username "heyoonow@gmail.com" \
  --password "ktgq-xpgy-mvfx-lnvg"
```

---

## 6단계. 최종 결과 보고

- 빌드 대상 플랫폼
- 새 버전/빌드 번호 및 태그 명칭
- Android AAB 파일 경로 (Android 빌드 시)
- iOS TestFlight 업로드 성공 여부 (iOS 빌드 시)
- **[스토어 등록용 릴리즈 노트]**: 작성된 한/영 문구 제공

---

## 🔧 트러블슈팅 & 학습 노트

### Android — Java heap space OOM
- **증상**: Gradle `bundleRelease` 중 `JetifyTransform: Java heap space` 에러
- **원인**: `android/gradle.properties`의 `org.gradle.jvmargs=-Xmx1536M`이 너무 낮음
- **해결**: 빌드 전 `org.gradle.jvmargs=-Xmx4096M`으로 올린 뒤 재실행
- **팁**: 빌드 실패 시 가장 먼저 이 값을 확인할 것

### iOS — "iOS Distribution" 인증서 없음
- **증상**: 아카이브는 성공하지만 IPA export 단계에서 `No signing certificate "iOS Distribution" found` 에러
- **원인**: Keychain에 배포용 인증서가 없는 환경 (CI/로컬 신규 맥 등)
- **해결**: `xcrun altool` 업로드 불가 → Xcode Organizer로 `.xcarchive`를 열어 **Distribute App → App Store Connect → Upload** 로 직접 배포
- **사전 체크**: 빌드 전 `security find-identity -v -p codesigning | grep "iPhone Distribution"` 으로 인증서 존재 여부 확인 권장

### 릴리즈 노트 작성 원칙
- 대표님은 실제 커밋 메시지 내용이 아닌 **유저 친화적 문구** 선호
- 예: "클린 아키텍처 리팩토링" → "앱 안정성 및 성능 최적화"
- 예: "ATT 팝업 중복 제거" → "사용자 경험 개선"
- 항상 한국어/영어 **둘 다** 작성해서 제공할 것

### 빌드 순서 권장
- Android → iOS 순서로 진행 (Android가 빠르고 실패 시 수정이 쉬움)
- 두 빌드를 병렬로 돌리지 말 것 (Gradle 데몬과 Xcode가 리소스 충돌 가능)
