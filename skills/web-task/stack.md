# Stack Reference

## 기술 스택

| 역할       | 기술                                     |
| ---------- | ---------------------------------------- |
| 프레임워크 | Next.js (App Router)                     |
| UI         | shadcn/ui + Tailwind CSS                 |
| 아이콘     | lucide-react                             |
| DB         | MongoDB (Docker, 같은 서버)              |
| ODM        | Mongoose                                 |
| 백엔드     | Next.js API Routes (`app/api/`)          |
| 인증       | NextAuth.js                              |
| 패키지 관리 | pnpm (없으면 npm)                       |

---

## 프로젝트 폴더 구조

```
├── app/
│   ├── layout.tsx               # 루트 레이아웃 (폰트, Provider 등)
│   ├── page.tsx                 # 홈
│   ├── loading.tsx              # 전역 로딩 UI (Suspense)
│   ├── error.tsx                # 전역 에러 UI
│   ├── not-found.tsx            # 404 UI
│   ├── (auth)/                  # 인증 라우트 그룹 (URL에 포함 안 됨)
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── (dashboard)/             # 대시보드 라우트 그룹
│   │   ├── layout.tsx           # ShellLayout (사이드바 + 콘텐츠)
│   │   └── [feature]/
│   │       ├── page.tsx         # Server Component — 데이터 fetch
│   │       ├── loading.tsx      # 이 페이지 전용 로딩
│   │       └── [id]/
│   │           └── page.tsx     # 상세 페이지
│   └── api/
│       └── [resource]/
│           ├── route.ts          # GET, POST
│           └── [id]/
│               └── route.ts      # GET, PATCH, DELETE
│
├── components/
│   ├── ui/                      # shadcn/ui 자동 생성 — 절대 수정 금지
│   ├── [feature]/               # 기능별 컴포넌트
│   │   ├── [feature]-card.tsx
│   │   ├── [feature]-list.tsx
│   │   └── [feature]-form.tsx
│   ├── layout/
│   │   ├── sidebar.tsx          # 'use client' (usePathname)
│   │   ├── header.tsx
│   │   └── shell-layout.tsx     # Server Component
│   └── shared/                  # 여러 기능에서 공유
│       ├── page-header.tsx
│       ├── empty-state.tsx
│       └── error-state.tsx
│
├── lib/
│   ├── db/
│   │   ├── connect.ts           # MongoDB 연결 (캐싱)
│   │   └── models/              # Mongoose 모델
│   │       └── [resource].ts
│   ├── actions/                 # Server Actions
│   │   └── [feature].ts
│   ├── auth.ts                  # NextAuth 설정
│   └── utils.ts                 # cn() 등 유틸
│
├── hooks/                       # 커스텀 훅 (클라이언트)
│   └── use-[feature].ts
├── types/                       # TypeScript 타입 정의
│   └── index.ts
└── .mcp.json                    # MongoDB MCP 설정
```

---

## MongoDB 설정

### Docker로 MongoDB 실행

```bash
# 최초 1회 — 컨테이너 생성 + 볼륨 마운트
docker run -d \
  --name mongodb \
  --restart unless-stopped \
  -p 27017:27017 \
  -v mongodb_data:/data/db \
  mongo:latest

# 이후 재시작
docker start mongodb

# 상태 확인
docker ps | grep mongodb
```

### `.mcp.json` (프로젝트 루트)

```json
{
  "mongodb": {
    "command": "npx",
    "args": [
      "-y",
      "mongodb-mcp-server@latest",
      "--connectionString",
      "mongodb://localhost:27017"
    ]
  }
}
```

### `lib/db/connect.ts`

```typescript
import mongoose from "mongoose";

const MONGODB_URI = process.env.MONGODB_URI!;

if (!MONGODB_URI) {
  throw new Error("MONGODB_URI 환경변수가 설정되지 않았습니다");
}

// TypeScript global 캐싱 (HMR 재실행 시 연결 유지)
declare global {
  var mongoose: {
    conn: typeof import("mongoose") | null;
    promise: Promise<typeof import("mongoose")> | null;
  };
}

let cached = global.mongoose;

if (!cached) {
  cached = global.mongoose = { conn: null, promise: null };
}

export async function connectDB() {
  if (cached.conn) return cached.conn;

  if (!cached.promise) {
    cached.promise = mongoose.connect(MONGODB_URI, {
      bufferCommands: false,
    });
  }

  try {
    cached.conn = await cached.promise;
  } catch (e) {
    cached.promise = null;
    throw e;
  }

  return cached.conn;
}
```

### `.env.local`

```bash
MONGODB_URI=mongodb://localhost:27017/your_db_name
NEXTAUTH_SECRET=your-secret-key-here
NEXTAUTH_URL=http://localhost:3000
NEXT_PUBLIC_BASE_URL=http://localhost:3000
```

---

## 신규 기능 추가 체크리스트

```
□ 1. types/index.ts에 타입 정의 추가
□ 2. lib/db/models/[resource].ts 모델 생성
□ 3. app/api/[resource]/route.ts API Route 생성
□ 4. lib/actions/[feature].ts Server Action 생성 (필요 시)
□ 5. app/(dashboard)/[feature]/page.tsx Server Component 생성
□ 6. app/(dashboard)/[feature]/loading.tsx 로딩 UI 생성
□ 7. components/[feature]/ 컴포넌트 생성
□ 8. app/(dashboard)/[feature]/layout.tsx 필요 시 생성
```

---

## 환경 구성

### 패키지 설치 (shadcn 초기화)

```bash
# Next.js 프로젝트 생성
pnpm create next-app@latest my-app --typescript --tailwind --eslint --app --src-dir=no

# shadcn/ui 초기화
pnpm dlx shadcn@latest init

# 자주 쓰는 shadcn 컴포넌트 일괄 설치
pnpm dlx shadcn@latest add button card input label textarea select badge avatar
pnpm dlx shadcn@latest add dialog sheet dropdown-menu popover tooltip
pnpm dlx shadcn@latest add table tabs separator skeleton scroll-area

# 필수 패키지
pnpm add mongoose next-auth lucide-react
pnpm add -D @types/mongoose
```

### `lib/utils.ts` (cn 유틸)

```typescript
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: Date | string): string {
  return new Date(date).toLocaleDateString("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export function formatRelativeTime(date: Date | string): string {
  const now = new Date();
  const target = new Date(date);
  const diffMs = now.getTime() - target.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);

  if (diffMin < 1) return "방금 전";
  if (diffMin < 60) return `${diffMin}분 전`;
  if (diffHour < 24) return `${diffHour}시간 전`;
  if (diffDay < 7) return `${diffDay}일 전`;
  return formatDate(date);
}
```
