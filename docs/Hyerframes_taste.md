# HyperFrames · Taste Skill 사용설명서

2026-09-23 기준

웹페이지를 만들 땐 Taste Skill, 영상이나 발표 덱을 만들 땐 HyperFrames를 씁니다.

## 한눈에 비교

| 항목      | HyperFrames                                     | Taste Skill                                      |
| --------- | ----------------------------------------------- | ------------------------------------------------ |
| 결과물    | MP4 영상, 발표 덱                               | 웹페이지·UI 코드, 디자인 참고 이미지             |
| 언제 쓰나 | 기능 소개 영상, PR 설명 영상, 자막, 모션 그래픽 | HTML 소개 페이지, 팀 공유 페이지, 기존 UI 다듬기 |
| 필요 환경 | Node.js 22 이상, FFmpeg                         | 없음 (스킬 파일만 있으면 됨)                     |
| 스킬 수   | 21개 (핵심 세트만 설치 권장)                    | 코드용 10개 + 이미지용 3개                       |
| 라이선스  | Apache 2.0                                      | MIT                                              |

## 설치

프로젝트 폴더에서 아래 명령을 실행합니다. Claude Code, Codex, Cursor 등 스킬을 지원하는 에이전트에서 동작합니다.

**HyperFrames** (핵심 세트만 설치 — 권장)

```bash
npx hyperframes skills update
```

- 대화형으로 고르려면 `npx skills add heygen-com/hyperframes` → "Core Skills" 그룹만 선택
- 비대화형으로 `skills add`를 실행하면 21개가 전부 설치되니 주의
- 영상 렌더링에는 Node.js 22 이상과 FFmpeg가 필요 (예: `brew install ffmpeg`)

**Taste Skill** (기본 스킬만 설치 — 권장)

```bash
npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"
```

- 사내 문서 느낌을 원하면 `--skill "minimalist-ui"`도 추가
- 전체 설치는 `--skill` 없이 실행

## HyperFrames 사용법

항상 `/hyperframes`로 시작합니다. 요청을 보고 알맞은 워크플로를 골라 필요한 스킬을 자동으로 설치합니다.

```text
Using /hyperframes, create a 10-second product intro with a fade-in title, a background video, and subtle background music.
```

| 스킬                    | 이럴 때                                           |
| ----------------------- | ------------------------------------------------- |
| `/product-launch-video` | 웹사이트 URL로 제품 소개·홍보 영상 (30~90초 권장) |
| `/pr-to-video`          | GitHub PR을 변경사항 설명 영상으로 (gh CLI 필요)  |
| `/faceless-explainer`   | 텍스트만으로 개념 설명 영상                       |
| `/slideshow`            | 발표용 덱 (영상이 아닌 넘길 수 있는 덱)           |
| `/motion-graphics`      | 10초 이내 짧은 모션 그래픽, 로고 연출             |
| `/embedded-captions`    | 기존 영상에 자막 넣기                             |
| `/general-video`        | 그 외 모든 영상                                   |

CLI로 직접 쓸 때:

```bash
npx hyperframes init my-video
cd my-video
npx hyperframes preview   # 브라우저 미리보기
npx hyperframes render    # MP4로 렌더링
```

## Taste Skill 사용법

설치하면 에이전트가 프론트엔드 작업 때 자동으로 불러옵니다. 어떤 스킬을 쓸지 프롬프트에 이름을 적어주면 더 확실합니다.

| 스킬 (설치 이름)             | 이럴 때                                   |
| ---------------------------- | ----------------------------------------- |
| `design-taste-frontend`      | 기본. 새 페이지를 만들 때 (v2, 실험 단계) |
| `minimalist-ui`              | Notion·Linear 같은 깔끔한 문서형 페이지   |
| `high-end-visual-design`     | 여백 많고 고급스러운 느낌                 |
| `redesign-existing-projects` | 이미 있는 페이지 다듬기                   |
| `full-output-enforcement`    | 에이전트가 코드를 중간에 생략할 때        |
| `design-taste-frontend-v1`   | v2가 문제일 때 이전 버전                  |

**설정 다이얼** (`design-taste-frontend`의 SKILL.md 상단, 1~10):

- `DESIGN_VARIANCE`: 낮을수록 중앙 정렬·단정, 높을수록 비대칭·실험적
- `MOTION_INTENSITY`: 낮으면 호버 효과만, 높으면 스크롤 애니메이션
- `VISUAL_DENSITY`: 낮으면 여유롭게, 높으면 대시보드처럼 빽빽하게

```text
design-taste-frontend 스킬을 써서 새 배포 파이프라인을 팀에 소개하는 단일 HTML 페이지를 만들어줘.
```

## 팀 공유용 활용 팁

- **소개 페이지**: Taste Skill로 HTML 페이지를 만들고 링크로 공유
- **짧은 소개 영상**: 같은 내용을 `/product-launch-video`나 `/pr-to-video`로 영상화해 슬랙 등에 첨부
- **최신 버전 유지**: HyperFrames는 `npx hyperframes skills update`, Taste Skill은 설치 명령을 다시 실행

## 출처

- [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes)
- [Leonxlnx/taste-skill](https://github.com/leonxlnx/taste-skill)
