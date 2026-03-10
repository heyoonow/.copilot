# Design Reference

## 설계 원칙

- **shadcn/ui 먼저** — `components/ui/`에 있는 것부터 조합. 없으면 직접 구현
- **인상적인 UI** — 평범한 흰 배경 + 텍스트 UI 금지. 그라디언트·그림자·애니메이션으로 차별화
- **반응형 필수** — mobile-first. `sm:` → `md:` → `lg:` 순서
- **여백** — 콘텐츠가 숨 쉬어야 한다. 답답한 UI 금지. 넉넉한 `px-6 py-8`
- **일관성** — 같은 카드, 같은 버튼, 같은 타이포그래피

---

## 깊이감 & 글래스 효과

```tsx
// 히어로 타이틀 — 그라디언트 텍스트
<h1 className="bg-gradient-to-br from-foreground to-foreground/50 bg-clip-text text-transparent text-5xl font-bold">
  제목
</h1>

// 섹션 배경 — 미묘한 그라디언트
<section className="bg-gradient-to-b from-background to-muted/30 py-20">

// 글래스 카드 (히어로, 모달 배경 등)
<div className="backdrop-blur-md bg-background/70 border border-white/10 rounded-2xl shadow-xl p-6">

// 글로우 카드 — hover 시 primary glow
<div className="rounded-xl border border-border/50 bg-card shadow-sm
  hover:border-primary/20 hover:shadow-md hover:shadow-primary/5
  transition-all duration-200 p-6 cursor-pointer">

// 그라디언트 버튼
<Button className="bg-gradient-to-b from-primary to-primary/90 shadow-sm hover:shadow-md transition-shadow">
  시작하기
</Button>

// 배지 — 색상 강조
<Badge className="bg-primary/10 text-primary border-primary/20 font-medium">
  New
</Badge>

// 섹션 구분 — 빛나는 구분선
<div className="h-px bg-gradient-to-r from-transparent via-border to-transparent" />
```

---

## 카드 패턴

```tsx
// 기본 데이터 카드
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";

function FeatureCard({ item }: { item: Item }) {
  return (
    <Card className="group hover:border-primary/20 hover:shadow-md transition-all duration-200">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base font-semibold">{item.title}</CardTitle>
          <Badge variant="secondary">{item.status}</Badge>
        </div>
        <CardDescription className="line-clamp-2">{item.description}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <CalendarIcon className="h-3.5 w-3.5" />
          <span>{formatDate(item.createdAt)}</span>
        </div>
      </CardContent>
    </Card>
  );
}

// 통계 카드 (대시보드)
function StatCard({
  title, value, change, icon: Icon
}: {
  title: string; value: string; change: string; icon: LucideIcon
}) {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <p className="text-sm text-muted-foreground font-medium">{title}</p>
            <p className="text-3xl font-bold">{value}</p>
            <p className="text-xs text-emerald-600 font-medium">{change}</p>
          </div>
          <div className="h-12 w-12 rounded-xl bg-primary/10 flex items-center justify-center">
            <Icon className="h-6 w-6 text-primary" />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
```

---

## 폼 패턴

```tsx
// 기본 폼 레이아웃
"use client";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

function FeatureForm({ onSubmit }: { onSubmit: (data: FormData) => Promise<void> }) {
  const [isLoading, setIsLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setIsLoading(true);
    try {
      await onSubmit(new FormData(e.currentTarget));
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="name">이름</Label>
        <Input
          id="name"
          name="name"
          placeholder="이름을 입력하세요"
          required
          disabled={isLoading}
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="description">설명</Label>
        <Textarea
          id="description"
          name="description"
          placeholder="설명을 입력하세요"
          rows={4}
          disabled={isLoading}
        />
      </div>
      <Button type="submit" disabled={isLoading} className="w-full">
        {isLoading ? (
          <>
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            저장 중...
          </>
        ) : (
          "저장"
        )}
      </Button>
    </form>
  );
}
```

---

## 빈 상태 / 에러 상태

```tsx
// 빈 상태
function EmptyState({
  icon: Icon,
  title,
  description,
  action,
}: {
  icon: LucideIcon;
  title: string;
  description: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="mb-4 rounded-full bg-muted p-4">
        <Icon className="h-8 w-8 text-muted-foreground" />
      </div>
      <h3 className="mb-1 text-lg font-semibold">{title}</h3>
      <p className="mb-6 max-w-sm text-sm text-muted-foreground">{description}</p>
      {action}
    </div>
  );
}

// 사용
<EmptyState
  icon={InboxIcon}
  title="아직 항목이 없어요"
  description="첫 번째 항목을 추가해 시작해보세요."
  action={
    <Button>
      <PlusIcon className="mr-2 h-4 w-4" />
      추가하기
    </Button>
  }
/>

// 에러 상태
function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="mb-4 rounded-full bg-destructive/10 p-4">
        <AlertCircleIcon className="h-8 w-8 text-destructive" />
      </div>
      <h3 className="mb-1 text-lg font-semibold">오류가 발생했어요</h3>
      <p className="mb-6 max-w-sm text-sm text-muted-foreground">{message}</p>
      {onRetry && (
        <Button variant="outline" onClick={onRetry}>
          <RefreshCwIcon className="mr-2 h-4 w-4" />
          다시 시도
        </Button>
      )}
    </div>
  );
}
```

---

## Skeleton 로딩 — 스피너 절대 금지

```tsx
// 기본 Skeleton 카드
import { Skeleton } from "@/components/ui/skeleton";

function CardSkeleton() {
  return (
    <div className="rounded-xl border p-6 space-y-4">
      <div className="flex items-center justify-between">
        <Skeleton className="h-5 w-1/2" />
        <Skeleton className="h-5 w-16 rounded-full" />
      </div>
      <Skeleton className="h-4 w-3/4" />
      <Skeleton className="h-4 w-1/3" />
    </div>
  );
}

// 리스트 Skeleton
function ListSkeleton({ count = 5 }: { count?: number }) {
  return (
    <div className="space-y-3">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="flex items-center gap-3 rounded-lg border p-4">
          <Skeleton className="h-10 w-10 rounded-full shrink-0" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-1/2" />
            <Skeleton className="h-3 w-1/3" />
          </div>
          <Skeleton className="h-8 w-20" />
        </div>
      ))}
    </div>
  );
}

// 그리드 Skeleton
function GridSkeleton({ count = 6 }: { count?: number }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {Array.from({ length: count }).map((_, i) => (
        <CardSkeleton key={i} />
      ))}
    </div>
  );
}

// 페이지 전체 로딩 (app/loading.tsx)
export default function Loading() {
  return (
    <div className="p-6 space-y-6">
      <div className="space-y-2">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-4 w-72" />
      </div>
      <GridSkeleton />
    </div>
  );
}
```

---

## 애니메이션 원칙

**조금만, 하지만 인상적으로.**

| 규칙 | 내용 |
|------|------|
| 등장 애니메이션 | 페이지 로드 시 딱 한 번 — 반복 절대 금지 |
| 인터랙션 | hover, click, focus에만 반응 |
| Duration | 150~300ms — 빠르고 자연스럽게 |
| 금지 | bounce, elastic — 튀는 효과 금지 |
| 로딩 | 스피너 최소화 → Skeleton 사용 |

### Duration 기준표

| 유형                    | Duration  | Tailwind 클래스      |
| ----------------------- | --------- | -------------------- |
| 인터랙션 (hover, click) | 150~200ms | `duration-150`       |
| 컴포넌트 등장           | 250~300ms | `duration-300`       |
| 스태거 간격             | 40ms      | `style animationDelay` |
| 페이지 전환             | 300ms     | `duration-300`       |

### 컴포넌트 등장 패턴

```tsx
// 페이드 + 슬라이드 업 (기본 — 데이터 로드 후)
<div className="animate-in fade-in slide-in-from-bottom-4 duration-300">
  {content}
</div>

// 스태거 리스트 (딱 한 번, 페이지 로드 시)
{items.map((item, i) => (
  <div
    key={item.id}
    className="animate-in fade-in slide-in-from-bottom-2 duration-300 fill-mode-both"
    style={{ animationDelay: `${i * 40}ms` }}
  >
    <ItemCard item={item} />
  </div>
))}

// 로딩 → 콘텐츠 전환 (깜빡임 없이)
{isLoading ? (
  <CardSkeleton />
) : (
  <div className="animate-in fade-in duration-200">
    <CardContent />
  </div>
)}
```

### 인터랙션 패턴

```tsx
// 카드 hover — 살짝 뜨는 느낌
<div className="transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg cursor-pointer">

// 버튼 — 클릭 피드백
<button className="transition-all duration-150 hover:scale-105 active:scale-95">

// 아이콘 버튼 — 부드러운 색상 전환
<button className="text-muted-foreground transition-colors duration-150 hover:text-foreground">
  <Icon className="h-4 w-4" />
</button>

// 링크 밑줄 애니메이션
<a className="relative after:absolute after:bottom-0 after:left-0 after:h-px after:w-0
  after:bg-primary after:transition-all after:duration-200 hover:after:w-full">
  링크 텍스트
</a>

// 탭 전환 — 부드러운 콘텐츠 교체
<div className={cn(
  "transition-all duration-200",
  isActive ? "opacity-100 translate-y-0" : "opacity-0 translate-y-1"
)}>
```

---

## 페이지 헤더 패턴

```tsx
// 기본 페이지 헤더
function PageHeader({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex items-start justify-between pb-6 border-b">
      <div className="space-y-1">
        <h1 className="text-2xl font-bold tracking-tight">{title}</h1>
        {description && (
          <p className="text-sm text-muted-foreground">{description}</p>
        )}
      </div>
      {action}
    </div>
  );
}
```

---

## ShellLayout (사이드바 레이아웃)

```tsx
// components/layout/shell-layout.tsx — Server Component
import { Sidebar } from "./sidebar";

export function ShellLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen overflow-hidden bg-background">
      <Sidebar />
      <main className="flex-1 overflow-y-auto">
        <div className="container mx-auto max-w-5xl px-6 py-8">
          {children}
        </div>
      </main>
    </div>
  );
}

// components/layout/sidebar.tsx — Client Component (usePathname 때문에)
"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/dashboard", label: "홈", icon: HomeIcon },
  { href: "/dashboard/items", label: "항목", icon: ListIcon },
  { href: "/dashboard/settings", label: "설정", icon: SettingsIcon },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 border-r bg-card flex flex-col">
      <div className="p-4 border-b">
        <h2 className="font-semibold text-lg">앱 이름</h2>
      </div>
      <nav className="flex-1 p-3 space-y-1">
        {navItems.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            className={cn(
              "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors duration-150",
              pathname === href
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:bg-muted hover:text-foreground"
            )}
          >
            <Icon className="h-4 w-4" />
            {label}
          </Link>
        ))}
      </nav>
    </aside>
  );
}

// app/(dashboard)/layout.tsx
import { ShellLayout } from "@/components/layout/shell-layout";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return <ShellLayout>{children}</ShellLayout>;
}
```

---

## 반응형 그리드 패턴

```tsx
// 카드 그리드 (기본)
<div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
  {items.map((item) => <ItemCard key={item._id} item={item} />)}
</div>

// 대시보드 통계 그리드
<div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
  <StatCard ... />
</div>

// 2컬럼 레이아웃 (리스트 + 상세)
<div className="grid gap-6 lg:grid-cols-[1fr_2fr]">
  <ItemList />
  <ItemDetail />
</div>

// 모바일 우선 패딩
<div className="px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
```
