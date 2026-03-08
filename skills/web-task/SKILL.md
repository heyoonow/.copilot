---
name: web-task
description: "Next.js 웹 앱 개발 작업을 실행한다. 기능 구현, UI 개발, API Routes, DB 연동 등 Next.js 관련 작업 요청이 오면 App Router 구조와 shadcn/ui 디자인 시스템을 유지하며 구현한다. 압도적인 디자인과 사용자 경험을 최우선으로 한다."
---

# Web Task Executor

Next.js App Router 기반으로 작업을 실행한다.
shadcn/ui + Tailwind로 인상적인 UI를 만들고, MongoDB로 데이터를 다룬다.
1억 다운로드 앱 기준의 디자인과 UX.

---

## 기술 스택

| 역할       | 기술                            |
| ---------- | ------------------------------- |
| 프레임워크 | Next.js (App Router)            |
| UI         | shadcn/ui + Tailwind CSS        |
| 아이콘     | lucide-react                    |
| DB         | MongoDB (Docker, 같은 서버)     |
| ODM        | Mongoose                        |
| 백엔드     | Next.js API Routes (`app/api/`) |
| 인증       | NextAuth.js                     |

---

## 프로젝트 구조

```
├── app/
│   ├── layout.tsx          # 루트 레이아웃
│   ├── page.tsx            # 홈
│   ├── (auth)/             # 인증 관련 라우트 그룹
│   ├── (dashboard)/        # 대시보드 라우트 그룹
│   └── api/                # API Routes
│       └── [resource]/
│           └── route.ts
│
├── components/
│   ├── ui/                 # shadcn/ui 자동 생성 (건드리지 않음)
│   └── [feature]/          # 피처별 컴포넌트
│
├── lib/
│   ├── db/
│   │   ├── connect.ts      # MongoDB 연결
│   │   └── models/         # Mongoose 모델
│   ├── actions/            # Server Actions
│   └── utils.ts            # cn() 등 유틸
│
├── hooks/                  # 커스텀 훅
├── types/                  # TypeScript 타입 정의
└── .mcp.json               # MongoDB MCP 설정
```

---

## MongoDB MCP 세팅

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

### Docker로 MongoDB 실행

```bash
# 최초 1회 — 컨테이너 생성
docker run -d \
  --name mongodb \
  --restart unless-stopped \
  -p 27017:27017 \
  -v mongodb_data:/data/db \
  mongo:latest

# 이후 재시작
docker start mongodb
```

### MongoDB 연결 (`lib/db/connect.ts`)

```typescript
import mongoose from "mongoose";

const MONGODB_URI = process.env.MONGODB_URI!;

if (!MONGODB_URI) {
  throw new Error("MONGODB_URI 환경변수가 설정되지 않았습니다");
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

  cached.conn = await cached.promise;
  return cached.conn;
}
```

### `.env.local`

```bash
MONGODB_URI=mongodb://localhost:27017/your_db_name
```

---

## 작업 실행 워크플로우

### 1단계: 파악

- Server Component인지 Client Component인지 판단
- API Route가 필요한지, Server Action으로 처리할지 결정
- 기존 shadcn 컴포넌트 재사용 가능한지 확인
- 디자인 일관성 체크 (색상, 간격, 타이포)

### 2단계: 구현 순서

**데이터 있는 기능:**

```
Mongoose 모델 → API Route or Server Action → Server Component (fetch) → Client Component (UI)
```

**UI만 있는 기능:**

```
shadcn 컴포넌트 조합 → 커스텀 스타일링 → 애니메이션
```

### 3단계: 검증

- TypeScript 에러 없는지 확인
- Server/Client 경계 올바른지 확인
- 모바일 반응형 확인
- 로딩/에러 상태 처리 확인

---

## Server vs Client Component 판단

```
데이터 fetch, DB 접근, 민감한 로직 → Server Component (기본값)
useState, useEffect, 이벤트 핸들러, 브라우저 API → Client Component ('use client')
```

```tsx
// Server Component (기본 — 'use client' 없음)
async function ProductList() {
  const products = await getProducts(); // 직접 DB 접근 가능
  return (
    <ul>
      {products.map((p) => (
        <ProductItem key={p._id} product={p} />
      ))}
    </ul>
  );
}

// Client Component
("use client");
function SearchBar() {
  const [query, setQuery] = useState("");
  return <input value={query} onChange={(e) => setQuery(e.target.value)} />;
}
```

---

## API Route 패턴

```typescript
// app/api/products/route.ts
import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db/connect";
import { Product } from "@/lib/db/models/product";

export async function GET() {
  try {
    await connectDB();
    const products = await Product.find().sort({ createdAt: -1 }).lean();
    return NextResponse.json(products);
  } catch (error) {
    return NextResponse.json({ error: "서버 오류" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    await connectDB();
    const body = await request.json();
    const product = await Product.create(body);
    return NextResponse.json(product, { status: 201 });
  } catch (error) {
    return NextResponse.json({ error: "생성 실패" }, { status: 500 });
  }
}
```

## Server Action 패턴

```typescript
// lib/actions/product.ts
"use server";
import { connectDB } from "@/lib/db/connect";
import { Product } from "@/lib/db/models/product";
import { revalidatePath } from "next/cache";

export async function createProduct(formData: FormData) {
  await connectDB();
  await Product.create({
    name: formData.get("name"),
    price: Number(formData.get("price")),
  });
  revalidatePath("/products");
}
```

## Mongoose 모델 패턴

```typescript
// lib/db/models/product.ts
import mongoose, { Schema, model, models } from "mongoose";

export interface IProduct {
  _id: string;
  name: string;
  price: number;
  createdAt: Date;
}

const ProductSchema = new Schema<IProduct>(
  {
    name: { type: String, required: true },
    price: { type: Number, required: true },
  },
  { timestamps: true },
);

export const Product =
  models.Product || model<IProduct>("Product", ProductSchema);
```

---

## 디자인 원칙

### 절대 원칙

- **shadcn/ui 기반** — 직접 스타일 만들지 않고 shadcn 컴포넌트 조합
- **일관성** — `cn()` 유틸로 조건부 클래스, Tailwind CSS 변수 사용
- **인상** — 평범한 UI 금지. 그라디언트, 그림자, 미묘한 애니메이션으로 차별화
- **반응형 필수** — mobile-first, `sm:` `md:` `lg:` 순서로
- **여백** — 콘텐츠가 숨 쉬어야 한다. 답답한 UI 금지

### 깊이감 & 그라디언트

```tsx
// 히어로 타이틀 — 그라디언트 텍스트
<h1 className="bg-gradient-to-br from-foreground to-foreground/50 bg-clip-text text-transparent">

// 섹션 배경 — 미묘한 그라디언트
<section className="bg-gradient-to-b from-background to-muted/30">

// 카드 — hover 시 border glow
<div className="rounded-xl border border-border/50 bg-card shadow-sm
  hover:border-primary/20 hover:shadow-md hover:shadow-primary/5
  transition-all duration-200">

// 글래스 카드 (히어로, 모달 등)
<div className="backdrop-blur-md bg-background/70 border border-white/10 rounded-2xl shadow-xl">

// 버튼 — 미묘한 그라디언트
<Button className="bg-gradient-to-b from-primary to-primary/90 shadow-sm">
```

---

## 애니메이션 원칙

**조금만, 하지만 인상적으로.**

- 페이지 로드 시 딱 한 번 — 반복 절대 금지
- 인터랙션(hover, click, focus)에만 반응
- duration 150~300ms — 빠르게, 자연스럽게
- 튀는 효과 금지 (bounce, elastic 사용 금지)
- 스피너 최소화 → 항상 스켈레톤

### Duration 기준

| 유형                    | Duration  |
| ----------------------- | --------- |
| 인터랙션 (hover, click) | 150~200ms |
| 컴포넌트 등장           | 250~300ms |
| 스태거 간격             | 40ms      |
| 페이지 전환             | 300ms     |

### 컴포넌트 등장

```tsx
// 페이드 + 슬라이드 업 (기본)
<div className="animate-in fade-in slide-in-from-bottom-4 duration-300">
  {content}
</div>

// 스태거 — 리스트 아이템 순차 등장 (딱 한 번)
{items.map((item, i) => (
  <div
    key={item.id}
    className="animate-in fade-in slide-in-from-bottom-2 duration-300 fill-mode-both"
    style={{ animationDelay: `${i * 40}ms` }}
  >
    {item.name}
  </div>
))}

// 페이드 인만 (텍스트, 배지 등 작은 요소)
<span className="animate-in fade-in duration-200">
```

### 인터랙션

```tsx
// 카드 hover — 살짝 뜨는 느낌
<div className="transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg cursor-pointer">

// 버튼 — 클릭 피드백
<button className="transition-all duration-150 hover:scale-105 active:scale-95">

// 링크 밑줄 애니메이션
<a className="relative after:absolute after:bottom-0 after:left-0 after:h-px after:w-0
  after:bg-primary after:transition-all after:duration-200 hover:after:w-full">
  링크 텍스트
</a>

// 아이콘 버튼 — 부드러운 색상 전환
<button className="text-muted-foreground transition-colors duration-150 hover:text-foreground">
  <Icon className="h-4 w-4" />
</button>
```

### 스켈레톤 로딩

```tsx
// 스피너 금지 — 항상 스켈레톤
function CardSkeleton() {
  return (
    <div className="animate-pulse rounded-xl border p-4 space-y-3">
      <div className="h-4 bg-muted rounded-md w-3/4" />
      <div className="h-4 bg-muted rounded-md w-1/2" />
      <div className="h-20 bg-muted rounded-lg w-full" />
    </div>
  )
}

// 로딩 → 콘텐츠 전환
{isLoading ? (
  <CardSkeleton />
) : (
  <div className="animate-in fade-in duration-200">
    <CardContent />
  </div>
)}

---

## 로딩 & 에러 처리

```

app/
├── loading.tsx # 자동 로딩 UI (Suspense)
├── error.tsx # 자동 에러 UI
└── not-found.tsx # 404 UI

````

```tsx
// app/loading.tsx
export default function Loading() {
  return (
    <div className="space-y-4 p-6">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="animate-pulse rounded-xl border p-4 space-y-3">
          <div className="h-4 bg-muted rounded w-3/4" />
          <div className="h-4 bg-muted rounded w-1/2" />
        </div>
      ))}
    </div>
  )
}
````

---

## 주의사항

- `use client` 최대한 아래로 내리기 (Server Component 최대 활용)
- Mongoose 모델은 `models.Model || model(...)` 패턴 필수 (HMR 중복 등록 방지)
- `connectDB()` 모든 API Route / Server Action 시작 시 호출
- 민감한 정보는 `.env.local` + 서버 사이드에서만 접근
- 이미지는 `next/image`, 링크는 `next/link` 사용
- `revalidatePath()` or `revalidateTag()`로 캐시 무효화

---

## Next.js 버전별 주의사항 (실전 검증)

### Next.js 15+ — `params`가 Promise 타입

Next.js 15부터 동적 라우트의 `params`는 **Promise**로 변경됨.
동기 접근하면 TypeScript 에러 발생.

```typescript
// ❌ 이전 방식 (Next.js 14 이하)
export default function Page({ params }: { params: { slug: string } }) {
  const { slug } = params; // 에러!
}

// ✅ 현재 방식 (Next.js 15+)
export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
}

// generateMetadata도 동일하게 적용
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
}
```

### Server Component에서 fetch + ISR

Server Component에서 `fetch()` 직접 호출 가능. ISR 적용 시 `next.revalidate` 옵션 사용.

```typescript
// ISR — 1시간마다 재검증
const res = await fetch(`${BASE_URL}/api/posts`, { next: { revalidate: 3600 } });

// 항상 최신 (no-store)
const res = await fetch(`${BASE_URL}/api/posts`, { cache: 'no-store' });
```

**BASE_URL 패턴:**
```typescript
const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:3000";
```

### Mongoose HMR 중복 등록 방지

```typescript
// ✅ 필수 패턴 — Next.js 개발서버 HMR 재실행 시 모델 중복 등록 방지
export const Product = models.Product || model<IProduct>("Product", ProductSchema);
```

### react-markdown은 Server Component에서 사용 가능

`react-markdown`은 `'use client'` 없이 Server Component에서 직접 사용 가능.
Markdown 렌더링 페이지는 Server Component로 유지하면 됨.

```typescript
import ReactMarkdown from "react-markdown";

// Server Component에서 바로 사용
export default async function PostPage() {
  const post = await getPost(slug);
  return <ReactMarkdown>{post.content}</ReactMarkdown>;
}
```

### ShellLayout 패턴 (사이드바 + 콘텐츠)

Sticky 사이드바가 있는 레이아웃은 아래 구조로 작성:

```
layout.tsx (Server) → ShellLayout (Server) → Sidebar (Client, usePathname) + {children}
```

- `Sidebar`는 `usePathname()` 쓰므로 반드시 `'use client'`
- `ShellLayout`은 Server Component 유지 (Sidebar만 Client로 분리)
- `layout.tsx`에서 `<ShellLayout>{children}</ShellLayout>` 래핑

### `findOneAndUpdate` deprecated 옵션

Mongoose에서 `{ new: true }` 옵션은 deprecated. `{ returnDocument: 'after' }` 사용 권장.
기능 차이는 없으나 경고 제거를 원하면 교체.

```typescript
// 경고 있음
await Model.findOneAndUpdate(filter, update, { upsert: true, new: true });

// 권장
await Model.findOneAndUpdate(filter, update, { upsert: true, returnDocument: 'after' });
```
