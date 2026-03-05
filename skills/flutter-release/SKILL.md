---
description: Flutter AAB/IPA 빌드, 버전 자동 펌핑, Git 자동화 및 TestFlight(heyoonow@gmail.com) 즉시 업로드를 수행합니다.
---

# Skill Instructions

당신은 Flutter 전문 릴리즈 에이전트입니다. 사용자가 "배포 빌드 해줘"라고 요청하면 다음 절차를 중단 없이 순차적으로 수행하세요.

1. **버전 및 변경점 분석**:
   - `pubspec.yaml`의 현재 버전을 확인하고, `PATCH` 버전과 `BUILD` 번호를 각각 1씩 올리세요.
   - 최근 Git 커밋 로그를 분석하여 앱 스토어용 **한국어/영어 릴리즈 노트**를 미리 작성해 두세요.

2. **자동 업데이트 및 Git 작업**:
   - `pubspec.yaml`의 버전을 새 버전으로 수정 후 저장하세요.
   - 터미널에서 다음을 실행하세요:
     1) `git add .`
     2) `git commit -m "chore: release v[새버전]"`
     3) `git tag v[새버전]`

3. **멀티 플랫폼 빌드 실행**:
   - `flutter build appbundle` (Android용 AAB 생성)
   - `flutter build ipa` (iOS용 IPA 생성)
   - 빌드 완료 후 `build/ios/ipa/` 폴더 내에 생성된 `.ipa` 파일의 정확한 경로를 확인하세요.

4. **TestFlight 자동 업로드 (heyoonow@gmail.com)**:
   - 확인된 IPA 파일 경로를 사용하여 아래 명령어를 터미널에서 즉시 실행하세요.
   - `xcrun altool --upload-app -f "확인된_IPA_경로" -t ios -u "heyoonow@gmail.com" -p "ktgq-xpgy-mvfx-lnvg"`

5. **최종 결과 보고**:
   - 모든 작업이 끝나면 다음 내용을 요약 보고하세요:
     - 새 버전 및 태그 명칭
     - Android AAB 파일 경로
     - iOS TestFlight 업로드 성공 여부
     - **[스토어 등록용 릴리즈 노트]**: 작성된 한/영 문구 제공