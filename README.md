# catbin 🐈‍⬛

> 📚 본 프로젝트는 패스트캠퍼스(FastCampus) 강의 자료입니다.

독(Dock)의 검은 고양이에게 파일을 던지면, 고양이가 입을 다물며 받아먹고 그 파일을 휴지통으로 보내는 macOS 앱입니다. 풀 Xcode 없이 `swiftc` + Command Line Tools만으로 `.app` 번들을 직접 조립합니다.

## 동작

- **평소**: 입을 벌린 상태(`open.png`)로 독에서 대기
- **파일을 던지면**: 즉시 휴지통으로 삭제 → 입을 다물었다가(`idle.png`) → 다시 벌림
- **독 아이콘 클릭**: 입을 잠깐 다물었다 벌리는 애니메이션 (삭제 없음)
- 여러 파일 동시 드롭 지원 / 폴더도 통째로 휴지통행

삭제는 `FileManager.trashItem`(휴지통 이동)을 사용하므로 실수해도 복구할 수 있습니다.

## 빌드 & 실행

```bash
./build.sh          # Catbin.app 생성
open Catbin.app     # 실행 (또는 Finder에서 Dock으로 드래그)
```

독 아이콘 우클릭 → 옵션 → **Dock에 유지** 로 상주시키면 파일을 바로 던질 수 있습니다.

## 고양이 이미지 교체

`art/` 폴더의 파일을 바꾼 뒤 `./build.sh`를 다시 실행하면 됩니다.

| 파일 | 역할 |
|---|---|
| `art/idle.png` | 입 다문 모습 |
| `art/open.png` | 입 벌린 모습 (평소 상태) |
| `art/AppIcon.icns` | 앱 아이콘 (미실행 시 표시) |

## 프로젝트 구조

```
catbin/
├─ Sources/main.swift   # 앱 로직 (독 타일 애니메이션 + 드롭/클릭 처리 + 휴지통)
├─ Info.plist           # 모든 파일 타입 수신(public.item) 선언
├─ build.sh             # swiftc 빌드 + .app 조립 + ad-hoc 서명
└─ art/                 # 고양이 이미지 & 아이콘
```

## 요구 사항

- macOS 13.0 이상
- Xcode Command Line Tools (`xcode-select --install`)

## 라이선스

교육용 강의 자료입니다.
