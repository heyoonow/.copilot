# Next.js Reference

## Server vs Client Component 판단

```
DB 접근 / 데이터 fetch / 민감한 로직 / SEO → Server Component (기본값, 'use client' 없음)
useState / useEffect / 이벤트 핸들러 / 브라우저 API / usePathname → Client Component ('use client')
```

### 핵심 규칙
- `'use client'`는 가능한 가장 아래 레벨 컴포넌트에만 달기
- 부모가 Server Component면 자식을 Client로 분리해 내려보내기
- `'use client'` 경계 아래에는 Server Component 올 수 없음

```tsx
// ✅ Server Component — fetch, DB 직접 접근
async function ProductList() {
  const products = await getProducts(); // DB 직접 접근 가능
  return (
    <ul>
      {products.map((p) => (
        <ProductItem key={p._id} product={p} />
      ))}
    </ul>
  );
}

// ✅ Client Component — 인터랙션 필요
"use client";
function SearchBar({ onSearch }: { onSearch: (q: string) => void }) {
  const [query, setQuery] = useState("");
  return (
    <input
      value={query}
      onChange={(e) => {
        setQuery(e.target.value);
        onSearch(e.target.value);
      }}
      placeholder="검색..."
      className="border rounded-lg px-3 py-2 text-sm"
    />
  );
}

// ✅ 분리 패턴 — Server + Client 협업
// page.tsx (Server)
async function ProductPage() {
  const products = await getProducts(); // 서버에서 데이터 fetch
  return <ProductListClient initialProducts={products} />; // Client로 내려보내기
}

// product-list-client.tsx (Client)
"use client";
function ProductListClient({ initialProducts }: { initialProducts: Product[] }) {
  const [products, setProducts] = useState(initialProducts);
  const [search, setSearch] = useState("");

  const filtered = products.filter((p) =>
    p.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <>
      <input value={search} onChange={(e) => setSearch(e.target.value)} />
      {filtered.map((p) => <ProductCard key={p._id} product={p} />)}
    </>
  );
}
```

---

## Next.js 15+ — params는 Promise 타입

**Next.js 15부터 동적 라우트의 `params`는 Promise로 변경됨.**
동기 접근 시 TypeScript 에러 발생.

```typescript
// ❌ 이전 방식 (Next.js 14 이하) — 에러 발생
export default function Page({ params }: { params: { slug: string } }) {
  const { slug } = params;
}

// ✅ 현재 방식 (Next.js 15+)
export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  // ...
}

// ✅ generateMetadata도 동일
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  return { title: slug };
}

// ✅ API Route에서도 동일
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  // ...
}
```

---

## fetch + ISR (Server Component)

```typescript
// 서버 컴포넌트에서 fetch 직접 사용

const BASE_URL = process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:3000";

// 정적 (빌드 시 1회) — 자주 안 바뀌는 데이터
const data = await fetch(`${BASE_URL}/api/static-data`);

// ISR — 1시간마다 재검증
const data = await fetch(`${BASE_URL}/api/posts`, {
  next: { revalidate: 3600 },
});

// 항상 최신 (SSR) — 매 요청마다 새로 fetch
const data = await fetch(`${BASE_URL}/api/realtime`, {
  cache: "no-store",
});

// 태그 기반 재검증
const data = await fetch(`${BASE_URL}/api/posts`, {
  next: { tags: ["posts"] },
});

// Server Action에서 태그 무효화
import { revalidateTag } from "next/cache";
await revalidateTag("posts");
```

---

## 라우팅 패턴

```
app/
├── page.tsx                      → /
├── about/page.tsx                → /about
├── blog/page.tsx                 → /blog
├── blog/[slug]/page.tsx          → /blog/my-post
├── blog/[...slug]/page.tsx       → /blog/2024/01/post (캐치올)
├── (marketing)/                  → URL 없는 그룹
│   ├── layout.tsx                → 마케팅 레이아웃
│   └── pricing/page.tsx          → /pricing
└── @modal/                       → 패러렐 라우트 (모달)
    └── (.)product/[id]/page.tsx  → 인터셉트 라우트 (모달)
```

```typescript
// 동적 라우트 링크
import Link from "next/link";

<Link href={`/blog/${post.slug}`}>
  {post.title}
</Link>

// 프로그래매틱 네비게이션 (Client Component)
"use client";
import { useRouter } from "next/navigation";

const router = useRouter();
router.push("/dashboard");
router.replace("/login");
router.back();

// 현재 경로 확인 (Client Component)
import { usePathname, useSearchParams } from "next/navigation";

const pathname = usePathname();           // "/dashboard/items"
const searchParams = useSearchParams();   // ?page=2&sort=asc
const page = searchParams.get("page");    // "2"
```

---

## loading.tsx / error.tsx / not-found.tsx

```tsx
// app/loading.tsx — Suspense 자동 적용
export default function Loading() {
  return (
    <div className="p-6 space-y-6">
      <div className="space-y-2">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-4 w-72" />
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="rounded-xl border p-6 space-y-3 animate-pulse">
            <Skeleton className="h-5 w-1/2" />
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-4 w-1/3" />
          </div>
        ))}
      </div>
    </div>
  );
}

// app/error.tsx — Client Component (reset prop 받기 위해)
"use client";
export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <div className="rounded-full bg-destructive/10 p-4">
        <AlertCircleIcon className="h-8 w-8 text-destructive" />
      </div>
      <h2 className="text-xl font-semibold">오류가 발생했어요</h2>
      <p className="text-sm text-muted-foreground">{error.message}</p>
      <Button onClick={reset} variant="outline">
        <RefreshCwIcon className="mr-2 h-4 w-4" />
        다시 시도
      </Button>
    </div>
  );
}

// app/not-found.tsx
import Link from "next/link";
export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
      <h1 className="text-7xl font-bold text-muted-foreground/30">404</h1>
      <h2 className="text-xl font-semibold">페이지를 찾을 수 없어요</h2>
      <p className="text-sm text-muted-foreground">요청한 페이지가 존재하지 않습니다</p>
      <Button asChild>
        <Link href="/">홈으로 돌아가기</Link>
      </Button>
    </div>
  );
}
```

---

## Metadata (SEO)

```typescript
// app/layout.tsx — 전역 메타데이터
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: {
    template: "%s | 앱 이름",
    default: "앱 이름",
  },
  description: "앱 설명",
  openGraph: {
    type: "website",
    siteName: "앱 이름",
  },
};

// 동적 메타데이터
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [{ url: post.thumbnail }],
    },
  };
}
```

---

## Middleware (인증 보호)

```typescript
// middleware.ts (프로젝트 루트)
import { withAuth } from "next-auth/middleware";
import { NextResponse } from "next/server";

export default withAuth(
  function middleware(req) {
    return NextResponse.next();
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
);

// 보호할 경로만 지정
export const config = {
  matcher: ["/dashboard/:path*", "/api/protected/:path*"],
};
```
