---
name: web-debugging
description: "Next.js 웹 앱의 버그 수정, 버전 충돌 해결, 코드 구조 개선, 디자인 및 애니메이션 개선을 담당한다. 단순 에러 수정이 아니라 근본 원인 파악 후 더 나은 구조와 더 나은 UX로 개선한다. hydration 에러, API Route 오류, MongoDB 문제, 패키지 충돌, 퍼포먼스 이슈, 디자인이 평범하거나 애니메이션이 없는 경우도 여기서 개선한다."
---

# Web Debugging

단순히 에러를 고치지 않는다. 왜 발생했는지 파악하고, 더 나은 구조로 개선한다.
디자인도 함께 본다. 평범하면 인상적으로 바꾼다. 애니메이션은 조금만, 하지만 기억에 남게.

---

## 디버깅 워크플로우

### 1단계: 현황 파악

**패키지 버전 전체 확인 — 가장 먼저**

```bash
cat package.json
npm outdated
```

**에러 수집**

```bash
npm run build 2>&1      # 빌드 에러 전체 출력
npm run lint            # ESLint 에러
```

문제가 어느 레이어인지 파악한다:

- 렌더링 (Server/Client Component 경계 문제)
- 데이터 (MongoDB 연결, Mongoose 쿼리, API Route)
- 스타일 (Tailwind 클래스 충돌, shadcn 커스텀 깨짐)
- 빌드 (TypeScript 에러, 패키지 충돌)
- 런타임 (hydration, 메모리 누수, 무한 루프)

---

### 2단계: 버전 호환성 검증

**반드시 웹 검색으로 확인** — 버전 정보는 항상 최신 공식 문서 기준

```
next.js [버전] breaking changes
shadcn/ui [컴포넌트] latest usage
mongoose [버전] next.js compatibility
[패키지명] changelog 2025
```

```bash
npm outdated                    # 업데이트 가능한 패키지 확인
npm ls [패키지명]                # 특정 패키지 의존성 트리
```

---

### 3단계: 증상별 원인 분석

**자주 보는 에러 패턴:**

| 증상                                         | 원인                                     |
| -------------------------------------------- | ---------------------------------------- |
| `Hydration failed`                           | Server/Client 렌더 결과 불일치           |
| `useEffect` / `useState` in Server Component | `'use client'` 누락                      |
| `Cannot read properties of undefined` in API | DB 연결 안됨 or 모델 import 순서 문제    |
| Mongoose `OverwriteModelError`               | `models.Model \|\| model(...)` 패턴 누락 |
| `NEXT_REDIRECT` 에러                         | try/catch 안에서 `redirect()` 호출       |
| `cookies()`/`headers()` Dynamic Server Usage | 정적 생성 페이지에서 동적 함수 호출      |
| Tailwind 클래스 미적용                       | `tailwind.config.ts` content 경로 누락   |
| shadcn 컴포넌트 스타일 깨짐                  | CSS 변수 덮어쓰기 충돌                   |
| API Route 504 timeout                        | MongoDB 연결 풀 미설정, 쿼리 최적화 필요 |

---

### 4단계: 최신 best practice 검색

고치기 전에 현재 방식이 최선인지 확인한다.

**검색 키워드:**

```
next.js app router [기능] best practice 2025
shadcn ui [컴포넌트] example
mongoose next.js connection pooling
next.js server action error handling
```

---

### 5단계: 수정 + 구조 개선

에러만 고치지 않는다. 더 나은 구조가 될 수 있다면 함께 개선한다.

**자주 발견되는 안티패턴:**

```tsx
// ❌ Client Component 남발
'use client'
async function ProductList() {   // 데이터만 fetch하는데 굳이 client
  const [products, setProducts] = useState([])
  useEffect(() => { fetch('/api/products').then(...) }, [])
}

// ✅ Server Component로
async function ProductList() {
  const products = await getProducts()  // 직접 DB 접근
  return <ul>{products.map(...)}</ul>
}
```

```tsx
// ❌ try/catch 안에서 redirect
try {
  await createPost(data);
  redirect("/posts"); // throw 기반이라 catch에 잡힘
} catch (e) {
  console.error(e);
}

// ✅ redirect는 try 밖으로
await createPost(data);
redirect("/posts");
```

```typescript
// ❌ Mongoose 모델 중복 등록 (HMR에서 에러)
export const Product = model<IProduct>("Product", ProductSchema);

// ✅ 항상 이 패턴
export const Product =
  models.Product || model<IProduct>("Product", ProductSchema);
```

```typescript
// ❌ API Route마다 새 연결
export async function GET() {
  await mongoose.connect(process.env.MONGODB_URI!); // 매번 새 연결
}

// ✅ 캐시된 연결 사용
export async function GET() {
  await connectDB(); // lib/db/connect.ts의 캐시 패턴
}
```

```tsx
// ❌ 하드코딩 색상
<div style={{ color: '#1a1a2e' }}>

// ✅ Tailwind + CSS 변수
<div className="text-foreground">
```

---

## Hydration 에러 해결

```tsx
// ❌ 서버/클라이언트 렌더 결과 다름 (날짜, Math.random 등)
<p>{new Date().toLocaleDateString()}</p>

// ✅ suppressHydrationWarning (단순 날짜/시간)
<p suppressHydrationWarning>{new Date().toLocaleDateString()}</p>

// ✅ useEffect로 클라이언트에서만 렌더
'use client'
function TimeDisplay() {
  const [time, setTime] = useState('')
  useEffect(() => setTime(new Date().toLocaleDateString()), [])
  return <p>{time}</p>
}
```

---

## MongoDB 연결 문제

```bash
# 도커 컨테이너 상태 확인
docker ps | grep mongodb
docker logs mongodb --tail=20

# 연결 테스트
docker exec -it mongodb mongosh --eval "db.runCommand({ ping: 1 })"
```

```typescript
// 연결 옵션 최적화
mongoose.connect(MONGODB_URI, {
  bufferCommands: false,
  maxPoolSize: 10, // 연결 풀 크기
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
});
```

---

## 패키지 버전 충돌 해결

충돌 발생 시 순서:

1. `npm outdated`로 현황 파악
2. 충돌 패키지 npm 페이지에서 changelog 확인 (웹 검색)
3. breaking change 없으면 업데이트
4. breaking change 있으면 마이그레이션 가이드 보고 코드 수정 후 업데이트
5. 불가피하면 `package.json`의 `overrides`로 버전 고정 + 주석

```json
{
  "overrides": {
    "some-package": "^2.1.0"
  }
}
```

**자주 충돌하는 조합:**
| 패키지 | 주의사항 |
|---|---|
| `next` + `react` + `react-dom` | 항상 같이 업데이트 |
| `shadcn/ui` 컴포넌트 + `tailwindcss` | tailwind v3/v4 마이그레이션 주의 |
| `next-auth` | Next.js 버전과 맞는 메이저 버전 확인 |
| `mongoose` + `@types/mongoose` | mongoose 6+ 는 자체 타입 내장, @types 불필요 |

---

## 성능 이슈 디버깅

```tsx
// 불필요한 리렌더 방지
const MemoizedComponent = memo(HeavyComponent);
const memoizedValue = useMemo(() => computeHeavyValue(data), [data]);
const memoizedCallback = useCallback(() => handleClick(id), [id]);

// 이미지 최적화 — img 태그 사용 금지
import Image from "next/image";
<Image src={url} alt={alt} width={400} height={300} />;

// 무거운 컴포넌트 lazy load
const HeavyChart = dynamic(() => import("./HeavyChart"), {
  loading: () => <ChartSkeleton />,
  ssr: false,
});
```

---

## 주의사항

- 버전 정보는 항상 웹 검색으로 최신 확인
- `npm run build`로 프로덕션 빌드 에러 반드시 확인 (dev 환경에서 안 잡히는 에러 있음)
- Server Component에서 `console.log`는 서버 터미널에 출력됨 (브라우저 콘솔 아님)
- `redirect()`는 절대 try/catch 안에 넣지 않기
- MongoDB `connectDB()` 빠뜨리면 조용히 실패하는 경우 있음 — 반드시 호출 확인
- 고친 후 반드시 `npm run build` 통과 확인
