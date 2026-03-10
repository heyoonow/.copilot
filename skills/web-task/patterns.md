# Patterns Reference

## Mongoose 모델 패턴

```typescript
// lib/db/models/product.ts

import mongoose, { Schema, model, models, Document } from "mongoose";

// 1. TypeScript 인터페이스 정의
export interface IProduct extends Document {
  _id: string;
  name: string;
  description?: string;
  price: number;
  imageUrl?: string;
  status: "active" | "inactive" | "draft";
  tags: string[];
  authorId: string;
  createdAt: Date;
  updatedAt: Date;
}

// 2. Schema 정의
const ProductSchema = new Schema<IProduct>(
  {
    name: {
      type: String,
      required: [true, "이름은 필수입니다"],
      trim: true,
      maxlength: [100, "이름은 100자 이하여야 합니다"],
    },
    description: {
      type: String,
      trim: true,
    },
    price: {
      type: Number,
      required: [true, "가격은 필수입니다"],
      min: [0, "가격은 0 이상이어야 합니다"],
    },
    imageUrl: String,
    status: {
      type: String,
      enum: ["active", "inactive", "draft"],
      default: "draft",
    },
    tags: {
      type: [String],
      default: [],
    },
    authorId: {
      type: String,
      required: true,
      index: true,          // 자주 조회하는 필드에 index
    },
  },
  {
    timestamps: true,       // createdAt, updatedAt 자동 관리
  }
);

// 3. 인덱스 (복합 인덱스 필요 시)
ProductSchema.index({ authorId: 1, status: 1 });
ProductSchema.index({ name: "text", description: "text" }); // 텍스트 검색

// 4. HMR 중복 등록 방지 — 필수 패턴
export const Product = models.Product || model<IProduct>("Product", ProductSchema);
```

---

## API Route 패턴 — 전체 CRUD

```typescript
// app/api/products/route.ts — GET 목록, POST 생성

import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { connectDB } from "@/lib/db/connect";
import { Product } from "@/lib/db/models/product";

export async function GET(request: Request) {
  try {
    await connectDB();

    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get("page") || "1");
    const limit = parseInt(searchParams.get("limit") || "20");
    const search = searchParams.get("search") || "";
    const status = searchParams.get("status") || "";

    // 쿼리 빌드
    const query: Record<string, unknown> = {};
    if (search) query.$text = { $search: search };
    if (status) query.status = status;

    const [items, total] = await Promise.all([
      Product.find(query)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Product.countDocuments(query),
    ]);

    return NextResponse.json({
      items,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      hasMore: page * limit < total,
    });
  } catch (error) {
    console.error("[GET /api/products]", error);
    return NextResponse.json({ error: "서버 오류가 발생했습니다" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    // 인증 체크
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
    }

    await connectDB();
    const body = await request.json();

    // 유효성 검사
    if (!body.name || !body.price) {
      return NextResponse.json({ error: "이름과 가격은 필수입니다" }, { status: 400 });
    }

    const product = await Product.create({
      ...body,
      authorId: session.user.id,
    });

    return NextResponse.json(product, { status: 201 });
  } catch (error: unknown) {
    console.error("[POST /api/products]", error);
    if (error instanceof Error && error.name === "ValidationError") {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    return NextResponse.json({ error: "생성에 실패했습니다" }, { status: 500 });
  }
}
```

```typescript
// app/api/products/[id]/route.ts — GET 단건, PATCH 수정, DELETE 삭제

import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { connectDB } from "@/lib/db/connect";
import { Product } from "@/lib/db/models/product";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await connectDB();

    const product = await Product.findById(id).lean();
    if (!product) {
      return NextResponse.json({ error: "찾을 수 없습니다" }, { status: 404 });
    }

    return NextResponse.json(product);
  } catch (error) {
    return NextResponse.json({ error: "서버 오류" }, { status: 500 });
  }
}

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
    }

    const { id } = await params;
    await connectDB();
    const body = await request.json();

    const product = await Product.findOneAndUpdate(
      { _id: id, authorId: session.user.id }, // 본인 것만 수정
      { $set: body },
      { returnDocument: "after", runValidators: true }
    );

    if (!product) {
      return NextResponse.json({ error: "찾을 수 없거나 권한이 없습니다" }, { status: 404 });
    }

    return NextResponse.json(product);
  } catch (error) {
    return NextResponse.json({ error: "수정에 실패했습니다" }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
    }

    const { id } = await params;
    await connectDB();

    const product = await Product.findOneAndDelete({
      _id: id,
      authorId: session.user.id,
    });

    if (!product) {
      return NextResponse.json({ error: "찾을 수 없거나 권한이 없습니다" }, { status: 404 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json({ error: "삭제에 실패했습니다" }, { status: 500 });
  }
}
```

---

## Server Action 패턴

```typescript
// lib/actions/product.ts
"use server";

import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { connectDB } from "@/lib/db/connect";
import { Product } from "@/lib/db/models/product";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

// 생성
export async function createProduct(formData: FormData) {
  const session = await getServerSession(authOptions);
  if (!session) throw new Error("로그인이 필요합니다");

  await connectDB();

  const name = formData.get("name") as string;
  const price = Number(formData.get("price"));
  const description = formData.get("description") as string;

  if (!name || !price) {
    throw new Error("이름과 가격은 필수입니다");
  }

  const product = await Product.create({
    name,
    price,
    description,
    authorId: session.user.id,
  });

  revalidatePath("/dashboard/products");
  redirect(`/dashboard/products/${product._id}`);
}

// 수정
export async function updateProduct(id: string, formData: FormData) {
  const session = await getServerSession(authOptions);
  if (!session) throw new Error("로그인이 필요합니다");

  await connectDB();

  await Product.findOneAndUpdate(
    { _id: id, authorId: session.user.id },
    {
      $set: {
        name: formData.get("name"),
        price: Number(formData.get("price")),
        description: formData.get("description"),
      },
    },
    { returnDocument: "after" }
  );

  revalidatePath(`/dashboard/products/${id}`);
  revalidatePath("/dashboard/products");
}

// 삭제
export async function deleteProduct(id: string) {
  const session = await getServerSession(authOptions);
  if (!session) throw new Error("로그인이 필요합니다");

  await connectDB();

  await Product.findOneAndDelete({ _id: id, authorId: session.user.id });

  revalidatePath("/dashboard/products");
  redirect("/dashboard/products");
}
```

```tsx
// Server Action 사용 — Server Component에서
import { createProduct } from "@/lib/actions/product";

// 폼에서 직접 action 연결
<form action={createProduct} className="space-y-4">
  <Input name="name" placeholder="이름" required />
  <Input name="price" type="number" placeholder="가격" required />
  <Button type="submit">생성</Button>
</form>

// Server Action 사용 — Client Component에서 (pending 상태 등)
"use client";
import { useTransition } from "react";
import { createProduct } from "@/lib/actions/product";

function ProductForm() {
  const [isPending, startTransition] = useTransition();

  function handleSubmit(formData: FormData) {
    startTransition(async () => {
      await createProduct(formData);
    });
  }

  return (
    <form action={handleSubmit}>
      <Button type="submit" disabled={isPending}>
        {isPending ? "저장 중..." : "저장"}
      </Button>
    </form>
  );
}
```

---

## NextAuth 설정

```typescript
// lib/auth.ts
import { NextAuthOptions } from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import GoogleProvider from "next-auth/providers/google";
import { connectDB } from "@/lib/db/connect";
import { User } from "@/lib/db/models/user";

export const authOptions: NextAuthOptions = {
  providers: [
    // Google OAuth
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),

    // 이메일 + 비밀번호
    CredentialsProvider({
      name: "credentials",
      credentials: {
        email: { label: "이메일", type: "email" },
        password: { label: "비밀번호", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) return null;

        await connectDB();
        const user = await User.findOne({ email: credentials.email });
        if (!user) return null;

        const isValid = await bcrypt.compare(credentials.password, user.password);
        if (!isValid) return null;

        return { id: user._id.toString(), email: user.email, name: user.name };
      },
    }),
  ],

  callbacks: {
    // JWT에 user.id 추가
    async jwt({ token, user }) {
      if (user) token.id = user.id;
      return token;
    },
    // Session에 user.id 추가
    async session({ session, token }) {
      if (session.user) session.user.id = token.id as string;
      return session;
    },
  },

  pages: {
    signIn: "/auth/login",
    error: "/auth/error",
  },

  session: {
    strategy: "jwt",
    maxAge: 30 * 24 * 60 * 60, // 30일
  },
};

// app/api/auth/[...nextauth]/route.ts
import NextAuth from "next-auth";
import { authOptions } from "@/lib/auth";
const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

```tsx
// 사용 — Server Component
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

export default async function ProtectedPage() {
  const session = await getServerSession(authOptions);
  if (!session) redirect("/auth/login");

  return <div>안녕하세요, {session.user.name}님!</div>;
}

// 사용 — Client Component
"use client";
import { useSession, signIn, signOut } from "next-auth/react";

function AuthButton() {
  const { data: session, status } = useSession();

  if (status === "loading") return <Skeleton className="h-9 w-20" />;
  if (session) {
    return <Button onClick={() => signOut()}>로그아웃</Button>;
  }
  return <Button onClick={() => signIn()}>로그인</Button>;
}
```

---

## 클라이언트 fetch 훅 패턴

```typescript
// hooks/use-products.ts
"use client";
import { useState, useEffect, useCallback } from "react";

interface UseProductsOptions {
  page?: number;
  search?: string;
  status?: string;
}

export function useProducts({ page = 1, search = "", status = "" }: UseProductsOptions = {}) {
  const [data, setData] = useState<{ items: Product[]; total: number; hasMore: boolean } | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProducts = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        page: page.toString(),
        ...(search && { search }),
        ...(status && { status }),
      });

      const res = await fetch(`/api/products?${params}`);
      if (!res.ok) throw new Error("조회에 실패했습니다");

      const json = await res.json();
      setData(json);
    } catch (e) {
      setError(e instanceof Error ? e.message : "알 수 없는 오류");
    } finally {
      setIsLoading(false);
    }
  }, [page, search, status]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  return { data, isLoading, error, refetch: fetchProducts };
}
```

---

## 에러 처리 패턴

```typescript
// types/index.ts
export interface ApiError {
  error: string;
  details?: string;
  statusCode?: number;
}

export type ApiResponse<T> = { data: T; error: null } | { data: null; error: ApiError };

// lib/api-client.ts — 클라이언트에서 API 호출 시 사용
export async function apiRequest<T>(
  url: string,
  options?: RequestInit
): Promise<ApiResponse<T>> {
  try {
    const res = await fetch(url, {
      headers: { "Content-Type": "application/json" },
      ...options,
    });

    const json = await res.json();

    if (!res.ok) {
      return {
        data: null,
        error: { error: json.error || "요청에 실패했습니다", statusCode: res.status },
      };
    }

    return { data: json, error: null };
  } catch (e) {
    return {
      data: null,
      error: { error: "네트워크 오류가 발생했습니다" },
    };
  }
}

// 사용 예시
const { data, error } = await apiRequest<Product[]>("/api/products");
if (error) {
  toast.error(error.error);
  return;
}
// data 사용
```

---

## Markdown 렌더링 (react-markdown)

```typescript
// react-markdown은 Server Component에서 'use client' 없이 사용 가능

import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

// Server Component에서 바로 사용
export default async function PostPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = await getPost(slug);

  return (
    <article className="prose prose-neutral dark:prose-invert max-w-none">
      <ReactMarkdown remarkPlugins={[remarkGfm]}>
        {post.content}
      </ReactMarkdown>
    </article>
  );
}
```

---

## Toast / 알림 패턴 (sonner)

```tsx
// 설치: pnpm add sonner

// app/layout.tsx에 추가
import { Toaster } from "sonner";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        {children}
        <Toaster richColors position="bottom-right" />
      </body>
    </html>
  );
}

// 사용 — Client Component
import { toast } from "sonner";

toast.success("저장됐어요!");
toast.error("오류가 발생했어요");
toast.loading("저장 중...", { id: "save" });
toast.dismiss("save");
toast("알림", { description: "상세 메시지", action: { label: "확인", onClick: () => {} } });
```
