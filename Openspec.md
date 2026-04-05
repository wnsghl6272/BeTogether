# BeTogether Project Specification

---

## Implemented Features

### Phase 7 — AI Matchmaker Chatbot

AI 기반 유저 매칭 추천 기능. 유저가 원하는 상대방을 자연어로 입력하면, OpenAI GPT-4와 MBTI 궁합 데이터를 결합해 최적의 매칭 상대를 추천한다.

#### 구성 요소

**1. Edge Function — `ai-recommendation`**
- Supabase Edge Function (Deno, TypeScript)
- 인증: `auth.getUser(jwt)` — 앱이 보낸 Bearer JWT를 Supabase Auth에 직접 검증
- 승인된 유저(`status='approved'`)만 후보로 포함
- GPT-4 Turbo (`gpt-4-turbo-preview`) 호출, `response_format: json_object` 사용
- 4단계 추천 이유(`reason1~4`) JSON 반환
- Service Role Key는 Edge Function 서버 내부에서만 사용 (RLS 우회, 후보 데이터 조회용)
- Required Secrets: `OPENAI_API_KEY` (Supabase Dashboard > Edge Functions > Secrets에서 설정)

**2. iOS — `AiChatInterfaceView.swift`**
- `TextEditor` 기반 멀티라인 입력창
- `AuthManager.fetchCurrentAccessToken()` — 세션 자동 갱신 후 유효 JWT 반환
- 수동 `URLRequest`로 Edge Function 호출 (Authorization: Bearer + apikey 헤더)
- 추천 결과 → `AiRevealEffectView`로 전달 (4단계 블러 해제 애니메이션)

**3. iOS — `AiRevealEffectView.swift`**
- 4단계 gamified 블러 해제 효과
- 단계별 이유 텍스트 표시
- "Why this match?" 버튼 (카드 우측 상단) → 전체 이유 시트
- 버튼/콘텐츠가 하단에서 잘리지 않도록 ScrollView 내부 레이아웃 고정

**4. iOS — `AuthManager.swift`**
- `fetchCurrentAccessToken()` 추가
  - Step 1: `client.auth.refreshSession()` — 만료된 토큰 자동 갱신
  - Step 2: `client.auth.session` — 현재 유효 세션 읽기
  - Step 3: 저장된 `currentAccessToken` — 마지막 수단 (OTP 인증 시 저장)

#### 보안 구조

**데이팅 앱 핵심 보안 아키텍처**

1. **프로필 및 사진 열람 (타인 접근 통제)**
   - **RLS (Row Level Security)**: 모든 데이터 테이블은 행 수준 보안이 적용되어 있어 API나 직접 쿼리 공격을 원천 차단.
   - **승인 기반 열람**: 관리자의 가입 승인을 받은 유저(`status='approved'`)만 다른 '승인된 유저'의 정보를 조회할 수 있음.
   - **본인 데이터 관리**: `blocked_contacts`, `profiles` 수정 등은 요청자의 JWT(`auth.uid()`)가 해당 레코드의 `id`와 일치할 때만 허용.
   - **향후 확장성**: 친구 요청/수락 기능 구현 시, 요청 발신자 및 수신자를 `auth.uid()`로 강제하는 정책만 추가하면 타인 명의 도용을 쉽게 방지할 수 있는 구조.

2. **로그인 세션 유지 및 토큰 검증**
   - **안전한 보관 (iOS Keychain)**: 로그인 시 발급되는 JWT 세션은 iOS의 강력한 암호화 저장소인 Keychain에 자동 보관되어 타 앱의 접근을 차단.
   - **자동 갱신 (Refresh Token)**: 엑세스 토큰 만료 시 Supabase SDK(`client.auth.refreshSession()`)가 백그라운드에서 자동으로 새 토큰을 발급받아 세션을 연장함.
   - **유효성 보장**: AI 매칭 등 중요 API 호출 시 항상 갱신된(가장 최신의 유효한) 토큰만을 사용하므로, 만료 및 탈취된 구형 토큰을 활용한 재생 공격(Replay Attack)을 방지.

**AI 매칭 엣지 함수 보안 흐름**
```
[iOS App]
  → Bearer: 실제 Supabase 유저 JWT (fetchCurrentAccessToken으로 자동 갱신)
  → body: { query: "..." }  // userId는 보내지 않음

[Edge Function, verify_jwt=false]
  → auth.getUser(jwt) → Supabase Auth 서버에서 JWT 직접 검증
  → userId를 서버에서 추출 (클라이언트의 userId 위조 원천 차단)
  → adminClient (Service Role) 로 후보 조회 (RLS 우회)
  → OpenAI API 호출 및 결과 반환
```

#### 데이터베이스 — RLS 정책

| 테이블 | 정책 | 조건 |
|--------|------|------|
| `profiles` | Approved users can view other approved profiles | `status='approved' AND auth.uid() IS NOT NULL` |
| `user_traits` | Approved users can read other users traits | 요청자가 `approved`인 경우 |

기존 정책 (유지):
- `profiles`: 본인만 읽기/수정, 관리자 전체 읽기/수정
- `user_photos`: 본인 관리, 관리자 전체, `is_verified=true`면 공개
- `user_traits`: 본인만 읽기/수정
- `blocked_contacts`: 본인만 관리
- `mbti_compatibility`: 전체 읽기 (공개)

#### 향후 개선 사항
- Rate Limiting: 유저당 하루 AI 추천 요청 횟수 제한 (OpenAI 비용 통제)
- 데이터 프라이버시: 개인정보 OpenAI 전송에 대한 이용약관 명시
- 디버그 로그 (`AI Debug token preview`) 출시 전 제거

### Phase 8 — Real-Time Chat System

실시간 1:1 채팅 인프라 및 UI.

#### 구성 요소

**1. Database — `messages` Table & Realtime**
- `messages` 테이블 생성 (`id`, `sender_id`, `receiver_id`, `content`, `created_at`).
- Supabase Realtime Publication 설정 완료.
- RLS 정책 설정: 발신자(`sender_id`) 또는 수신자(`receiver_id`)가 자기 자신(`auth.uid()`)일 때만 조회(Select)/생성(Insert) 가능.

**2. iOS — `ChatManager.swift`**
- Supabase Swift Realtime V2 (`realtimeV2`, `RealtimeChannelV2`) 스펙 완전 연동.
- `postgresChange(InsertAction.self)` 리스너를 통해 상대방과 메시지를 즉각적으로 화면에 동기화.
- 100% `async/await` 동시성(Concurrency) 기법만을 활용한 구독 및 구독 해지 생명주기 관리.

**3. iOS — `ChatRootView` & `ChatRoomView`**
- `ChatRootView`: 하단 Chat 탭 클릭 시, 기존 NotificationView 대신 노출됨. 상단 Segment를 통해 `Matches`와 `Friends`로 리스트 분리.
- `ChatRoomView`: 1:1 카카오톡 스타일 채팅방 구현. `ScrollViewReader`를 연동하여 메시지를 주고받을 때 항상 대화방 최하단으로 자동 스크롤.

### Phase 9 — Daily Picks & Bug Fixes

오늘의 추천(Daily Picks) 기능 및 온보딩 사진 업로드 로직 디버깅.

#### 구성 요소

**1. VisionManager (온보딩 사진 얼굴 인식 픽스)**
- iOS 시뮬레이터 환경에서 발생하는 `VNDetectFaceRectanglesRequest` (Code 9) 에러 해결.
- 시뮬레이터 감지 시 최신 `.revision3` 대신 `.revision1`을 강제 주입하여 우회하는 폴백(Fallback) 로직 추가.

**2. Database — `daily_picks` Table**
- 테이블 생성 (`id`, `user_id`, `target_user_id`, `picked_date`, `is_unlocked`).
- RLS 정책 설정. 권한 우회를 막기 위해 `INSERT/SELECT` 시 `user_id`가 `auth.uid()`와 일치해야만 허용.

**3. iOS — `InteractionManager.swift`**
- Lazy Generation(지연 생성) 아키텍처 구현: 서버에서 일괄 생성하지 않고, 유저가 앱에 진입 시 그 날(`picked_date`) 데이터가 없다면 그 즉시 상대방 `profiles` 중 무작위 2명을 가져와 DB에 보관. DB 비용 절감.
- 존재하지 않는 `mbti` 필드 호출로 인한 `42703 (undefined_column)` PostgreSQL 이슈 해결.
- 삽입 시 `id: UUID().uuidString`을 넘기도록 수정하여 `NOT NULL` 제약 조건 통과 보장.

**4. iOS — `MatchesView.swift` & UI 개선**
- 상단의 쓸모없는 탭 구조 (Matches, Report) 삭제. Navigation Title 을 "Connections" 에서 "Explore"로 직관적으로 변경.
- `DailyPickCardView`에 Glassmorphism 블러(UIBlurEffect) 기법 도입하여 미니멀하고 프리미엄한 잠금 처리 레이아웃 완성.
- 하루 1회 무료 언락 로직과 우아한 스프링 애니메이션(.spring) 결합.


### Security Audit (Production Readiness)

출시 전(Production) 반드시 체크 및 수정하고 넘어가야 할 보안 및 안정성 검토 사항들입니다.

1. **Edge Functions `verify_jwt` 활성화**
   - 개발 환경에서 인증 우회를 위해 설정된 JWT 검증 생략은 운영 서버 배포 시 반드시 `true`로 켤 것. API 앤드포인트 노출 시 임의 접근 방지 필수.
2. **응답 데이터 최소화 (Over-fetching 방지)**
   - 상대방 프로필 등을 불러올 때 `.select()`를 막연히 사용하면 GPS 좌표나 연락처 등 민감한 개인정보가 클라이언트(아이폰)까지 전송될 수 있음. 운영 배포 전 `.select("id, name, age, mbti, image_name")` 등으로 필터 고도화 적용.
3. **가짜 Auth 조작 방지 (Impersonation Defense)**
   - RLS 정책(INSERT)에서, 악의적인 공격자가 HTTP 패킷의 JSON 바디 조작을 통해 타인의 ID를 `sender_id`나 `actor_id` 에 강제 주입하는 시도를 차단해야 함. 반드시 해당 컬럼이 `auth.uid()`와 일치할 때만 Insert가 되도록 RLS 적용.
4. **에러 시스템 마스킹 (Stack Trace Leakage)**
   - API / DB 서버 내부에서 발생한 생날 것(Raw)의 에러 메시지(테이블 명칭, DB 버전, 칼럼 규칙 등 포함)가 유저 스마트폰까지 전달되면 엄청난 보안 취약점이 됨. '서버 오류 발생' 등의 문자열로 치환.

---

## Future Features

### Apple Sign-In Integration (Postponed)
This feature has been postponed due to Apple Developer Program fee requirements.

**1. Required Setup (Apple & Supabase)**
- **Apple Developer Portal:**
  - Need to enroll in Apple Developer Program (requires fee).
  - Enable "Sign In with Apple" capability on the App ID (`com.wnsghl6272.BeTogether`).
  - Create a new Service ID for "Sign In with Apple".
  - Generate a new Private Key (`.p8` file) for "Sign In with Apple".
- **Supabase Dashboard:**
  - Go to Authentication > Providers > Apple.
  - Turn on the toggle.
  - Fill in Bundle ID, Team ID, Key ID, and the `.p8` Private Key content.
- **Xcode Project:**
  - Add "Sign In with Apple" capability in Signing & Capabilities.

**2. User Management & Onboarding Flow Considerations**
- Apple Sign-In provides an email (often a private relay email) but **DOES NOT provide a phone number**.
- **Recommended Flow (Option A):** 
  - Since our app relies heavily on phone numbers (e.g., for Contact Blocking), the onboarding flow for Apple users should look like this:
  - Apple Login -> **Phone Number Verification** -> Terms View -> Profile Setup
- This skips the Email Verification step (as Apple verifies the email), but enforces Phone Verification to maintain data consistency and enable features like blocking contacts.
