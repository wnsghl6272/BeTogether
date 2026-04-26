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
- `mbti_compatibility_v2`: 서비스 역할 전용 (public/anon 접근 불가 — Phase 16에서 교체)
- `mbti_pair_lookup`: 서비스 역할 전용 (public/anon 접근 불가 — Phase 16에서 신규 생성)

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

### Phase 10 — Real-Time Push Notification & Read Receipts System 결함 수정 및 고도화

실시간 채팅 알림(알람 뱃지) 동기화 오류 및 메시지 프라이버시, SwiftUI 생명주기 관련 문제의 완벽한 해결.

#### 구성 요소

**1. Database — `notifications` Table & Realtime Publication**
- 누락되었던 `notifications` 테이블을 `supabase_realtime` Publication에 포함(ALTER PUBLICATION)하여 클라이언트로의 실시간 웹소켓(WebSocket) 브로드캐스팅 라우트를 개통.
- 홈 화면(종 아이콘)과 채팅 화면(메뉴 뱃지)의 읽음 상태 처리가 `is_read` 단일 컬럼으로 묶여있던 문제를 해결하고자 **`is_seen` boolean 컬럼 추가**.
- `handle_new_message_notification` 트리거 수정: 사생활 보호를 위해 알림 생성 시 채팅 원문을 그대로 사용하지 않고, `profiles` 테이블과 조인하여 `"[상대방 닉네임] sent you a message."` 포맷으로 치환해 노출하도록 변경.

**2. iOS — Read States Decoupling (상태 분리)**
- **홈 화면 (알림 센터용)**: `is_seen` 컬럼만 감시 (`NotificationManager`). 알림 창을 열어보면 기존 알림들이 `is_seen = true`로 변경되며 홈 화면 뱃지가 사라지지만, 채팅방은 여전히 안 읽은 상태(`is_read = false`)로 유지됨.
- **채팅 탭 (채팅 목록용)**: 기존대로 `is_read` 감시 (`ChatManager`). 사용자가 직접 채팅방에 진입 시 `is_read = true` 및 `is_seen = true`로 동시 업데이트하여 알림을 일괄 소진함.

**3. iOS — SwiftUI `NavigationLink` Eager Evaluation Bug 수정**
- `List` 내부의 `NavigationLink(destination: ChatRoomView)` 렌더링 과정에서 SwiftUI의 과도한 사전 로딩(Preload) 때문에 `.onAppear`가 유저 몰래 동작하여 알림을 읽음(`markMessagesAsRead`) 처리해버리던 치명적 버그 수정.
- 화면 라우팅을 명시적 `Button` 터치 방식으로 뜯어고치고, `.onAppear` 대신 **Button Action 블록 내부**에서 직접 읽음 API를 호출하는 형태로 전환하여 안전성과 성능 확보.


### Phase 11 — 닉네임 기반 친구 시스템, 프로필 UI 리뉴얼 & 업로드 최적화

기존 매치 시스템과 완전히 분리된 닉네임 기반의 친구 추가/채팅 시스템을 구축하고, 프로필 조회/수정 기능 및 온보딩 과정을 개선.

#### 구성 요소

**1. 닉네임 친구 시스템 및 대화방 분리 (Conversations Architecture 도입)**
- `conversations` 및 `conversation_members` 테이블을 활용한 метод C 아키텍처 도입.
- 기존 `messages` 테이블을 `conversation_id` 단위로 나누어 데이터 격리 처리.
- `add_friend_by_nickname` RPC 업데이트: 친구가 맺어질 경우 `type = 'friend'` 인 `conversations` 레코드 자동 생성.
- `get_my_conversations` RPC 구성: `type` (match/friend)에 따라 채팅 세션 및 안읽은 메시지 수 별도 조회.
- **UI/UX:** `ChatRootView`에서 Matches 와 Friends 세그먼트로 나누어 별개의 리스트와 배지 카운트 표시. `ExploreView`에서 친구 리스트의 대화 버튼 누르면 `pendingChatSession`을 통해 자동으로 특정 채팅방 진입.

**2. 프로필 UI 리뉴얼 (Profile Menu)**
- `ProfileMainView`: DB (`profiles` 및 `user_traits`)에서 불러온 내 모든 정보(키, 직업, 음주, 닉네임, 한줄소개 등)를 한눈에 볼 수 있도록 구성.
- 사진 갤러리는 `TabView` 기반 스와이프 인터페이스로 고도화.
- `ProfileEditView`: Form 스타일 입력. Supabase를 통해 클라우드에 직접 수정 데이터 영구 보존.

**3. 온보딩 최적화**
- **닉네임 중복 확인 (Validation):** `ProfileSetupView` 온보딩 닉네임 설정 시 "Check" 버튼 도입. 고유 아이디 성격에 맞게, 중복검사 통과 후에만 다음 단계 진행 가능. (저장 후 `ProfileEditView`에서는 수정 불가능하게 Lock 처리)
- **업로드 용량 절감 (HEIC 압축 최적화):** `PhotoUploadView`에서 리스케일링 사이즈를 `1080px` → `800px`로 하향 조정 및 iOS 네이티브 API (AVFoundation) 를 활용한 HEIC 압축 로직 추가 (`UIImage+HEIC` 익스텐션). 이를 통해 **기존 JPEG 대비 약 50%의 서버 스토리지 및 네트워크 대역폭 비용 절감**.
- **브랜딩 텍스트 수정:** 홈 화면, 스플래시 화면의 Honsyl 텍스트를 대문자 `HONSYL`로 일괄 적용.

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

### Phase 12 — 유저 관리 고도화, 신고 시스템, 매칭 프리퍼런스 & 안정화

차단 연락처 관리 UI, 매칭 선호도 필터링, 친구/매치 삭제 로직, 앱 내 신고(Report) 시스템 구축 및 다수의 UI 안정화 패치.

#### 구성 요소

**1. 닉네임 고유성 강화**
- **온보딩 중복확인 버튼**: `ProfileSetupView`에 "Check" 버튼 추가. `profiles` 테이블에서 닉네임 중복 여부를 실시간 조회. 중복검사를 통과해야만 다음 단계 진행 가능.
- **프로필 수정 시 잠금**: `ProfileEditView`에서 닉네임 필드를 읽기 전용(disabled)으로 처리하여 가입 후 변경 불가.

**2. Blocked Contact 관리 UI**
- `ProfileMainView` → Settings 섹션에 "Blocked Contacts" 메뉴 추가.
- `BlockedContactsView` 신규 구현: 현재 차단된 연락처 목록 표시 및 **Unblock(차단 해제)** 기능 제공.
- 온보딩 시 설정한 차단 목록을 프로필 탭에서도 추가/관리할 수 있도록 UX 개선.

**3. Matching Preference 시스템 (Home 탭 연동)**
- **온보딩 수집**: 온보딩 `MatchingPreferencesView`에서 선호 성별, 연령대, MBTI 등 설정.
- **AI 추천 우선 반영**: `ai-recommendation` Edge Function 호출 시, 유저의 매칭 프리퍼런스를 우선 필터링 조건으로 전달. 조건에 맞는 후보가 없으면 AI 콘텐츠 기반 추천으로 폴백하며, `"Recommended based on AI content analysis"` 메시지를 표시.
- **Home 탭 상단 수정 UI**: 알람 아이콘 옆에 프리퍼런스 편집 버튼 배치. 탭 내에서 바로 선호도를 수정 가능.

**4. 친구/매치 삭제 로직 (Conversation Lifecycle)**
- **매치 삭제**: 한쪽이 삭제 시 양쪽 모두에서 대화 및 매칭이 제거됨. 관련 `messages` 레코드와 `conversations`/`conversation_members` 레코드 일괄 삭제.
- **친구 삭제**: 한쪽이 삭제해도 상대방의 채팅 기록은 유지됨. 다만 삭제한 쪽에서는 해당 대화방이 사라지고, 상대방의 채팅방에는 "Add Friends" 버튼이 다시 표시됨.

**5. 신고(Report) 시스템 — Option B (DB + 자동 이메일)**
- **Database**: `reports` 테이블 생성.
  - 컬럼: `id`, `reporter_id`, `target_user_id` (nullable), `reason` (enum: inappropriate_content, harassment, fake_profile, spam, other), `details` (text), `status` (pending/reviewed/resolved), `created_at`.
  - RLS 정책: 로그인 유저 본인의 신고만 생성/조회 가능.
- **UI — `ReportSubmissionView`**: 신고 사유 선택(5가지) 및 상세 내용 작성 폼.
  - `ProfileMainView` → Settings에 "Help & Report Issue" 버튼 (일반 앱 문의/버그 신고용, `targetUserId = nil`).
  - `ChatRoomView` → 네비게이션 바 우측에 🚨 버튼 (채팅 상대 특정 신고, `targetUserId = 상대방 ID` 자동 세팅).
- **Backend — Supabase Edge Function (`send-report-email`)**:
  - `reports` 테이블에 INSERT 발생 시 Webhook Trigger로 자동 함수 호출.
  - Resend API를 통해 관리자 이메일로 신고 내용을 실시간 발송하는 템플릿 코드 구현 완료.
  - **환경 변수 설정 필요**: Supabase Dashboard > Edge Functions > Secrets에서 `RESEND_API_KEY`, `ADMIN_EMAIL` 설정 후 즉시 이메일 발송 활성화.

**6. Admin Dashboard — 사진 뷰어 수정**
- **문제**: Admin 계정이 pending 유저의 사진을 볼 때, 시뮬레이터 QUIC/HTTP3 네트워크 스택 충돌로 공개 URL에서의 이미지 다운로드 실패.
- **해결**: `URLSession` / `AsyncImage`를 통한 공개 URL 직접 다운로드 대신, **Supabase Storage SDK의 `download()` 메서드**를 사용하여 이미 인증된 클라이언트 연결을 재활용.
  - `AuthManager.downloadStoragePhoto(imageUrl:)` 함수 추가: 공개 URL에서 스토리지 경로를 추출하여 SDK를 통한 안전한 다운로드 수행.
- **UI 개선**: 사진을 `TabView(.page)` 스타일의 **스와이프 가능한 갤러리**로 변경. 하단에 페이지 인디케이터(●○○) 및 현재 페이지 카운터 ("1 / 6") 표시.

**7. UI 안정화 — CoreGraphics NaN 에러 해결**
- `ProfileMainView` 및 `PhotoCardView` 내 `GeometryReader` 사용 시 프레임 계산 과정에서 발생하던 `NaN` (Not a Number) 에러 방지.
- `max(0, geometry.size.width)` 등 안전 장치(guard) 적용으로 런타임 경고 완전 제거.

### Phase 13 — Chat Reliability, Unmatch Logic Overhaul, and Dynamic Reporting

Overhaul of the unmatch logic, chat memory deletion fixes, and dynamic reporting categories to ensure system stability and privacy.

#### Components

**1. Chat Memory & Deletion Fixes (Server-Side Message Filtering)**
- **Problem**: Previously cleared conversations reappeared when a peer sent a new message, due to flaws in client-side timeline filtering (`cleared_at`).
- **Solution**: Transitioned the fetch logic in `ChatManager` to a dedicated Supabase Postgres RPC (`get_conversation_messages`). This shifts the filtering logic to the database layer, strictly ensuring that any messages created before a user's `cleared_at` timestamp are inherently pruned from the exact payload returned to the client. This guarantees cleared message histories never reappear.

**2. Unmatch Logic Overhaul & Foreign Key Constraint Resolution**
- **Problem**: When attempting to unmatch a user, the deletion of related `conversations` was failing. This triggered a Foreign Key Constraint violation (`Error 23503: notifications_conversation_id_fkey`) because stranded notification records referencing the conversation still existed. Consequently, "unmatched" users reappeared on the Explore screen after reloading.
- **Solution**: 
  - Updated the PostgreSQL `unmatch_user` RPC to explicitly cascade the deletion. It now meticulously deletes records from `messages`, any related `notifications` targeting the specific `conversation_id`, `conversation_members`, the core `conversations` record itself, and finally the `matches` & `user_interactions`.
  - Refactored `InteractionManager` passing arguments to the `unmatch_user` RPC using strongly-typed `UUID` Encodables via URLSession, eliminating `try?` silent suppression in `ExploreView`, forcing active UI synchronization and re-fetching after an unmatch completes.

**3. Dynamic Reporting Categories (Context-Aware Issue Reporting)**
- Refactored `ReportSubmissionView` to react based on its point of entry:
  - **Global Context (`ProfileMainView`)**: Restricts the selection to generic items like `App Bug / Issue` and `Other` when reporting structural app-wide problems without a designated target.
  - **Peer Context (`ChatRoomView`)**: Expands the categories to `Harassment`, `Inappropriate Content`, `Spam`, and `Fake Profile` to correctly audit peer-to-peer behavior.

#### 보안 및 운영 참고

| 항목 | 설명 |
|------|------|
| `reports` RLS | `reporter_id = auth.uid()` 일 때만 INSERT/SELECT 허용 |
| Edge Function Secrets | `RESEND_API_KEY`, `ADMIN_EMAIL` — 실제 발송을 위해 필수 설정 |
| Storage SDK Download | 공개 URL 대신 SDK `download()` 사용 시 RLS/인증 토큰 자동 적용 |

### Phase 14 — Onboarding & Matching Overhaul

Streamlined the complete onboarding flow and significantly remodeled how user preferences are structured.

#### 구성 요소

**1. Onboarding UI Restructuring**
- **ProfileSetupView**: Removed redundant `.drinking` and `.smoking` queries.
- **PersonalityQAView**: Eradicated outdated drinking habit tracking to accelerate the QA survey.
- **MBTIResultView**: Simplified the interface by removing over-designed charts and focusing purely on the result text to decrease friction.

**2. Data Structure Modernization (User Traits)**
- Created a robust `lifestyle` JSONB property within the `user_traits` PostgreSQL table.
- Deployed a data migration to seamlessly transfer legacy `smoking` and `drinking` preferences into the structured `lifestyle` dictionary.
- **LifestyleOptionsView**: A new, expansive step integrated natively into the `OnboardingRouter`. Designed using a bespoke `FlowLayout` to elegantly present tag-based lifestyle attributes (Zodiac, Education, Family Plans, etc.).

**3. Matching Preference Remaster**
- **MatchingPreferenceView Redesign**: Redesigned the preference page combining a sticky Location row with interactive, dynamically-sized multi-selectable grid layouts that store attributes globally.
- Re-wired the data pipeline to handle categorical array lists directly into the `matching_preferences` JSON.

### Phase 15 — Onboarding Quality Enhancement, Profile Photo Management & UI Polish

온보딩 흐름 고도화, 프로필 사진 사후 관리, 매칭 프리퍼런스 정리 및 Explore UI 정렬 수정.

#### 구성 요소

**1. 프로필 사진 사후 관리 시스템 (`ProfilePhotoEditView`)**
- `ProfileMainView` 하단에 "Manage Photos" 버튼 추가. 온보딩 이후에도 사진을 추가, 삭제, 재정렬 가능.
- 온보딩과 동일한 얼굴 인식 (`VisionManager.shared.detectSingleFace`) 적용: 첫 두 장은 반드시 얼굴이 포함된 사진이어야 함.
- 온보딩과 동일한 이미지 압축(HEIC/JPEG) 파이프라인 재사용으로 서버 스토리지 비용 절감.
- **사후 사진 수정 시 `pending_approval` 상태 변경 없음** — 온보딩 승인 이후에는 사진 변경으로 인한 재승인 대기가 발생하지 않음.

**2. Matching Preferences — Workout Preference 제거**
- `MatchingPreferenceView` (온보딩) 및 `MatchingPreferenceEditView` (설정)에서 "Workout Preference" 필터 섹션 완전 제거.
- Workout 데이터는 `user_traits.lifestyle` JSONB에서 관리되므로 매칭 프리퍼런스와의 중복 저장 해소.
- 관련 State, Options 배열, UI 섹션, 데이터 로드/저장 로직 모두 정리.

**3. 온보딩 University 스텝 제거**
- `ProfileSetupView`에서 `.university` 스텝 enum, UI, 저장 로직 완전 제거.
- `ProfileEditView`에서 University 입력 필드 제거.
- `UserSessionViewModel`에서 `university` 프로퍼티 제거.
- 기존 유저의 `university` DB 컬럼은 유지 — `ProfileMainView`에서 기존 데이터가 있으면 표시.
- 학력 정보는 Lifestyle Options의 "Education" 카테고리에서 선택 가능.

**4. Occupation — 자유 입력 → 검색형 선택 리스트**
- `ProfileSetupView`: 기존 자유 텍스트 입력 → 80개 이상의 직업 목록에서 검색/선택하는 방식으로 전환.
- 검색 필드에 타이핑하면 실시간 필터링. 선택된 직업은 체크마크 뱃지로 표시.
- `OccupationPickerSheet.swift` 신규 생성: `ProfileEditView`에서도 동일한 모달 시트로 직업 변경 가능한 재사용 컴포넌트.

**5. One-Line Intro — 가이드 텍스트 및 글자 수 제한**
- 제목을 "Your One-Line Intro"로 변경, "Write one sentence that shows off your charm!" 안내 문구 추가.
- **80자 글자 수 제한** (`onChange`로 강제 적용).
- 실시간 글자 카운터 (`/80`) 표시, 70자 이상 시 오렌지색 경고.
- 빈 문자열/공백만 입력 시 Next 버튼 비활성화.

**6. About Me (Self Intro) — AI 매칭 가이드 및 최소 글자 수**
- 제목을 "About Me"로 변경.
- AI 가이드 배너 추가: "Our AI uses this to find your perfect match. Write as accurately and attractively as you can — the better your description, the better your matches!"
- **500자 글자 수 제한** 및 **최소 20자 요구** (약 한 문장 이상).
- 20자 미만 입력 시 "Please write at least one full sentence." 경고 표시 + Complete Profile 버튼 비활성화.
- `ProfileEditView`에서도 동일한 글자 수 제한 및 AI 가이드 아이콘 표시.

**7. Explore 메뉴 — DailyPickCardView 이미지 중앙 정렬 수정**
- **문제**: `.scaledToFill()` + `.frame(maxWidth: .infinity)` + `.clipped()` 조합에서 이미지가 부모 컨테이너보다 크게 확장되면서 iPhone에서 왼쪽으로 치우쳐 잘리는 현상 발생.
- **해결**: `GeometryReader`로 감싸서 정확한 부모 컨테이너 너비(`geo.size.width`)를 이미지 frame에 전달. 이미지가 정확히 카드 너비에 맞춰 중앙 정렬되도록 수정.

#### 변경 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `ProfilePhotoEditView.swift` | [NEW] 프로필 사진 사후 관리 뷰 |
| `OccupationPickerSheet.swift` | [NEW] 재사용 가능한 직업 검색/선택 시트 |
| `ProfileSetupView.swift` | University 스텝 제거, Occupation 검색 리스트, Intro 가이드 및 제한 |
| `ProfileEditView.swift` | University 필드 제거, Occupation 시트, Intro 가이드 및 제한 |
| `ProfileMainView.swift` | Manage Photos 버튼 추가 |
| `MatchingPreferenceView.swift` | Workout Preference 제거 |
| `MatchingPreferenceEditView.swift` | Workout Preference 제거 |
| `UserSessionViewModel.swift` | `university` 프로퍼티 제거 |
| `MatchesView.swift` | DailyPickCardView 이미지 중앙 정렬 수정 |

---

### Phase 16 — AI Matchmaker Algorithm Overhaul (Multi-Dimensional Scoring Engine)

기존 단순 MBTI 점수 조회 방식에서 **다차원 성격·라이프스타일·가치관 기반 복합 매칭 엔진**으로 전면 개편. 136개 MBTI 쌍별 7차원 루브릭 데이터를 활용하여 정확성과 추천 근거의 깊이를 대폭 강화.

#### 구성 요소

**1. Database — MBTI Compatibility V2 마이그레이션**

| 작업 | 상세 |
|------|------|
| 삭제 | `mbti_compatibility` (기존 빈 테이블) |
| 신규 | `mbti_compatibility_v2` — 136개 MBTI 쌍 레코드, 7차원 루브릭 점수 |
| 신규 | `mbti_pair_lookup` — 256개 양방향 조회 엔트리 |
| RLS | 두 테이블 모두 `service_role` 전용 (public/anon 접근 완전 차단) |

**7차원 루브릭 (Rubric Dimensions):**

| 차원 | 최대 점수 | 설명 |
|------|-----------|------|
| Core Needs & Energy | 25 | 에너지 방향성 및 핵심 욕구 정렬 |
| Emotional Safety & Intimacy | 20 | 감정적 안전감 및 친밀감 기반 |
| Communication & Conflict | 15 | 소통 방식 및 갈등 해결 스타일 |
| Lifestyle Execution | 15 | 일상 생활 방식 실행력 |
| Values & Meaning | 10 | 가치관 및 의미 추구 정렬 |
| Growth & Repair | 8 | 성장 지향 및 관계 복원력 |
| Stress Support | 5 | 스트레스 상황에서의 상호 지지 |

각 레코드에는 `summary`, `why_it_works[]`, `watch_outs[]`, `success_conditions[]`, `flags[]` 등 GPT 컨텍스트용 자연어 데이터 포함.

**양방향 조회 (Bidirectional Lookup):**
- `mbti_pair_lookup` 테이블은 `INTJ_ENFP` → `pair_key`, `ENFP_INTJ` → 동일한 `pair_key`로 매핑하여, MBTI 순서와 무관하게 O(1) 조회 보장.

---

**2. Edge Function — `ai-recommendation` 전면 재작성**

기존 단순 MBTI 점수 참조 로직에서 **4차원 복합 매칭 점수(CMS) 엔진**으로 완전 교체.

**Composite Match Score (CMS) 공식:**
```
CMS = (MBTI × 0.40) + (Lifestyle × 0.25) + (Values × 0.20) + (Profile Affinity × 0.15)
```

| 차원 | 가중치 | 계산 방식 |
|------|--------|----------|
| MBTI Score | 40% | `mbti_compatibility_v2.score` (0~100) 직접 참조 |
| Lifestyle Score | 25% | 7개 라이프스타일 카테고리 비교 (Drinking, Smoking, Workout, Communication Style, Love Language, Family Plans, Pets). 정확 일치=1.0, 인접 선택=0.5~0.7, 불일치=0.2~0.3 |
| Values Score | 20% | 온보딩 QA 답변 비교. 같은 질문에 같은 답변=1.0, 다른 답변=0.4 |
| Profile Affinity | 15% | 직업 도메인 클러스터 매칭 (Tech, Health, Creative, Business). 동일 직업=90, 같은 도메인=75, 기타=50 |

**Confidence Tier 분류:**

| CMS 범위 | 티어 | 별표 |
|----------|------|------|
| 85~100 | Excellent | ★★★ |
| 70~84 | Great | ★★ |
| 55~69 | Good | ★ |
| 0~54 | Fair | — |

**GPT 프롬프트 개선:**
- 각 후보의 MBTI 루브릭 상세 (Emotional Safety 점수, Why It Works, Watch-outs, Success Conditions) 를 프롬프트에 직접 주입.
- 4가지 인사이트 기반 추천 이유 생성 (모든 이유는 **영어**로 출력):
  1. **Emotional Connection**: 감정적 안전감 및 why_it_works 기반
  2. **Daily Life Compatibility**: 라이프스타일 정렬, 연애 스타일, 소통 방식 기반
  3. **Unique Bridge**: 직업·자기소개에서 추출한 고유 연결점
  4. **Confidence Summary**: 티어 + 핵심 인사이트 요약
- Watch-outs와 Success Conditions를 활용하여 균형 잡힌 뉘앙스 생성 (단순 긍정 일변도 방지).

**API 응답 구조 변경:**
```json
{
  "candidates": [
    {
      "candidate": { /* 기존 프로필 + mbti, lifestyle, answers 인리치 */ },
      "distance": 15,
      "confidenceTier": "Great",
      "compositeScore": 81.9,
      "topDimensions": ["Emotional Safety: Very High", "Values & Meaning: High"],
      "scores": {
        "mbti": 93.1,
        "lifestyle": 65.0,
        "values": 66.7,
        "profileAffinity": 50.0,
        "composite": 81.9
      },
      "reasons": {
        "step1": "You both share high emotional safety...",
        "step2": "Both of you prefer structured planning...",
        "step3": "As fellow creative professionals...",
        "step4": "An Excellent Match — your strong values alignment..."
      }
    }
  ],
  "matchedByPreference": true
}
```

---

**3. iOS — `User.swift` 모델 확장**
- `confidenceTier: String?` — "Excellent", "Great", "Good", "Fair"
- `compositeScore: Double?` — CMS 점수 (0~100)
- `topDimensions: [String]?` — 상위 호환 차원 (예: "Emotional Safety: Very High")

---

**4. iOS — `AiChatInterfaceView.swift` 디코더 업데이트**
- `CandidateContainer` 구조체에 `confidenceTier`, `compositeScore`, `topDimensions` 필드 추가.
- **`FlexibleAnswers` 커스텀 디코더 도입**: `answers` 필드가 딕셔너리(`{key: value}`)로 올 때와 배열(`[{question, answer, category}]`)로 올 때 모두 처리 가능. SQL 시드 유저와 앱 온보딩 유저의 데이터 형식 차이를 자동 정규화.
- 디코딩된 데이터를 `User` 모델의 `personalQA`, `confidenceTier`, `compositeScore`, `topDimensions`에 매핑.

---

**5. iOS — `AiRevealEffectView.swift` UI 강화**

- **블러 해제 오버레이 (Fog Reveal):**
  - "AI Matchmaker" 라벨 옆에 Confidence Tier 뱃지 표시 (★★★ Excellent / ★★ Great / ★ Good)
  - 티어별 동적 헤드라인: "An exceptional match found!" / "A wonderful match for you!" / "A promising match found!"

- **"Why this match?" 필 버튼:**
  - 버튼에 티어 별표 추가 표시

- **ReasonsSheetView (추천 이유 시트) 전면 개편:**
  - 한국어 라벨 → 영어로 전환 ("MBTI 궁합" → "Emotional Connection" 등)
  - 상단에 Confidence Tier 뱃지 + Composite Score 표시
  - **Top Compatibility Areas** 섹션 추가: `topDimensions` 배열을 체크마크 리스트로 렌더링
  - 4개 이유 카드: Emotional Connection (💜), Daily Life Compatibility (💙), Unique Bridge (💚), Match Summary (🩵)

---

**6. 기타 정리**
- `test-data-generator/` 폴더 삭제 (더 이상 불필요)
- 임시 SQL 시드 파일 정리

#### 보안 구조

| 항목 | 보안 수준 |
|------|----------|
| `mbti_compatibility_v2` | RLS 활성화, 정책 없음 = `service_role` 전용. anon key로 0행 반환 확인됨 |
| `mbti_pair_lookup` | RLS 활성화, 정책 없음 = `service_role` 전용 |
| Edge Function | `SUPABASE_SERVICE_ROLE_KEY`로만 호환성 데이터 조회. 클라이언트에 원시 점수/루브릭 절대 노출 안 함 |
| AI 응답 | 자연어 추천 이유만 반환. 내부 알고리즘 메트릭스 및 루브릭 데이터는 서버에서만 사용 |
| 알고리즘 소스 | `MBTI_Compatibility_136_Merged_v2.json` — 프로젝트 내부 전용, 절대 유출 금지 |

#### 변경 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `User.swift` | [MODIFY] `confidenceTier`, `compositeScore`, `topDimensions` 필드 추가 |
| `AiChatInterfaceView.swift` | [MODIFY] FlexibleAnswers 디코더, 새 응답 필드 매핑 |
| `AiRevealEffectView.swift` | [MODIFY] Confidence tier 뱃지, 동적 헤드라인, 영어 라벨, Top Dimensions |
| `ai-recommendation/index.ts` | [REWRITE] CMS 엔진, 라이프스타일/가치관/프로필 점수, 루브릭 기반 GPT 프롬프트 |
| `mbti_compatibility_v2` | [NEW TABLE] 136개 MBTI 쌍 호환성 레코드 |
| `mbti_pair_lookup` | [NEW TABLE] 256개 양방향 조회 엔트리 |
| `mbti_compatibility` | [DELETED TABLE] 기존 빈 테이블 삭제 |
| `test-data-generator/` | [DELETED] 불필요한 테스트 데이터 생성기 폴더 삭제 |

---

### Phase 17 — AI Recommendation Engine Finalization & Data Normalization

AI 추천 엔진의 정확도와 자연어 인식 능력을 극대화하기 위해 라이프스타일 메타데이터를 정규화하고, 엣지 펑션의 하드 필터링 및 프롬프트를 고도화했습니다.

#### 구성 요소

**1. 테스트 유저 라이프스타일 데이터 정규화 (Data Normalization)**
- 기존 임의의 랜덤 문자열로 생성된 테스트 유저들의 9가지 라이프스타일 데이터(Smoking, Drinking, Workout, Education 등)를 iOS 앱의 `PersonalityQAView`에서 사용하는 **정확한 Enum 값과 100% 일치**하도록 SQL 일괄 마이그레이션 수행.
  - 예시: `Daily` → `Everyday`, `Rarely` → `Never`, `Frequently` → `Reviewer`
- 이를 통해 서버 사이드 필터링 및 CMS(Composite Match Score) 계산 시 데이터 불일치로 인한 누락 및 오류 원천 차단.

**2. 자연어 기반 하드 필터링 (Server-Side Filtering)**
- `ai-recommendation/index.ts` 내에 유저의 자연어 검색어에서 특정 라이프스타일을 유추하는 정규식/키워드 매칭 로직 추가.
  - **학력 (Education)**: "postgraduate", "undergraduate" 등
  - **가족 계획 (Family Plans)**: "wants children", "doesn't want children" 등
  - **연애 언어 (Love Language)**: "physical touch", "quality time" 등
- 추출된 키워드를 바탕으로 GPT 모델에 컨텍스트를 넘기기 전, 데이터베이스 레벨에서 후보군을 먼저 좁혀(Filtering) 100% 조건에 부합하는 후보만 선별.

**3. GPT 컨텍스트 인리치먼트 (Context Enrichment)**
- 엣지 펑션이 GPT에 후보자 목록을 전달할 때, 9가지의 전체 라이프스타일 정보(Zodiac, Education, Family Plans 등)를 모두 텍스트로 풀어 제공 (`Education: Postgraduate, Family Plans: Want children` 등).
- 이를 통해 생성형 AI가 "이 후보자는 당신과 같은 대학원생이며..." 와 같이 훨씬 더 맥락 있고 깊이 있는 영문 추천 이유(reasons)를 4단계로 반환할 수 있도록 고도화.

**4. 자동화 테스트 스위트 확장 (`test_ai_recommendation.sh`)**
- 새롭게 추가된 기능 검증을 위해 3가지 시나리오(학력, 가족계획, 연애 언어)에 대한 통합 테스트(E2E) 케이스 추가. 총 13개 시나리오 100% 통과 확인.

#### 변경 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `ai-recommendation/index.ts` | [MODIFY] 라이프스타일 키워드 추출 정규식 추가, 하드 필터링 로직 구현, GPT 프롬프트 컨텍스트 확장 |
| `test_ai_recommendation.sh` | [MODIFY] Education, Family Plans, Love Language 테스트 케이스 3개 추가 |

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
