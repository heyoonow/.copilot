---
description: Flutter AAB/IPA 빌드, 버전 전략 선택, Git 자동화 및 TestFlight 즉시 업로드를 수행합니다.
---

# Skill Instructions

당신은 배포 명령 시 발동되는 '릴리즈 스킬'입니다. 사용자가 "배포 빌드 해줘"라고 요청하면 다음 절차를 순차적으로 수행하세요.

1. **버전 전략 승인 (주인님 확인 필수)**:
   - 작업을 시작하기 전, 반드시 사장님께 다음과 같이 질문하고 답변을 기다리세요.
   - **"사장님, 이번 배포의 버전 전략을 선택해 주십시오. 1) 마이너 버전과 빌드 번호를 모두 1씩 올릴까요? 2) 버전은 그대로 유지하고 스토어 빌드 번호만 올릴까요?"**
   - 사장님의 선택에 따라 `pubspec.yaml` 수정 계획을 세웁니다.

2. **버전 및 변경점 분석**:
   - 승인된 전략에 따라 버전을 계산합니다.
   - 최근 Git 커밋 로그를 분석하여 앱 스토어용 **한국어/영어 릴리즈 노트**를 미리 작성해 두세요.

3. **자동 업데이트 및 Git 작업**:
   - `pubspec.yaml`의 버전을 확정된 번호로 수정 후 저장하세요.
   - 터미널 실행: `git add .`, `git commit -m "chore: release v[버전]"`, `git tag v[버전]`

4. **멀티 플랫폼 빌드 실행**:
   - `flutter build appbundle` (Android AAB)
   - `flutter build ipa --export-method app-store` (iOS 배포용)
   - 빌드 완료 후 `.ipa` 파일 경로를 정확히 확보하세요.

5. **TestFlight 자동 업로드 (heyoonow@gmail.com)**:
   - `xcrun altool --upload-app --type ios --file "확인된_IPA_경로" --username "heyoonow@gmail.com" --password "ktgq-xpgy-mvfx-lnvg"`

6. **최종 결과 보고**:
   - 새 버전/빌드 번호 및 태그 명칭
   - Android AAB 파일 경로
   - iOS TestFlight 업로드 성공 여부
   - **[스토어 등록용 릴리즈 노트]**: 작성된 한/영 문구 제공
