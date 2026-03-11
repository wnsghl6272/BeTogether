# BeTogether Project Specification

---

## Implemented Features

### Phase 7 — AI Matchmaker Chatbot (2026-03-11)

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

```
[iOS App]
  → Bearer: 실제 Supabase 유저 JWT (fetchCurrentAccessToken으로 자동 갱신)
  → body: { query: "..." }  // userId는 보내지 않음

[Edge Function, verify_jwt=false]
  → auth.getUser(jwt) → Supabase Auth 서버에서 JWT 검증
  → userId를 서버에서 추출 (클라이언트 위조 불가)
  → adminClient (Service Role) 로 후보 조회
  → OpenAI API 호출
  → 추천 결과 반환
```

#### 데이터베이스 — RLS 정책 (2026-03-11 추가)

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
