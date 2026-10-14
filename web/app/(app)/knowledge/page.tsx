"use client";

import Link from "next/link";
import { useState } from "react";
import { BookOpen, Plus, Search, Sparkles } from "lucide-react";
import { useSession } from "@/components/session";
import { Badge, Button, Card, EmptyState, ErrorState, LoadingBlock, PageHeader, Select } from "@/components/ui";
import { timeAgo } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import type { ArticleSummary } from "@/lib/types";

export default function KnowledgePage() {
  const { meta } = useSession();
  const [q, setQ] = useState("");
  const [product, setProduct] = useState("");
  const [category, setCategory] = useState("");
  const [status, setStatus] = useState("");
  const qs = new URLSearchParams(Object.entries({ q: q.trim(), product, category, status }).filter(([, v]) => v)).toString();
  const { data, error, isLoading, mutate } = useApi<{ articles: ArticleSummary[]; counts: Record<string, number> }>(`/articles?${qs}`, {
    keepPreviousData: true,
  });

  return (
    <>
      <PageHeader
        title="Bilgi bankası"
        description={`Sorun giderme rehberleri. ${data ? `${data.counts.published ?? 0} yayında, ${data.counts.draft ?? 0} taslak.` : ""}`}
        actions={
          <Link href="/knowledge/new">
            <Button variant="accent">
              <Plus className="size-4" aria-hidden /> Yeni makale
            </Button>
          </Link>
        }
      />
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <div className="relative w-72">
          <Search className="pointer-events-none absolute left-2.5 top-1/2 size-3.5 -translate-y-1/2 text-slate-400" aria-hidden />
          <label htmlFor="kb-q" className="sr-only">
            Makale ara
          </label>
          <input
            id="kb-q"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Başlık, içerik, etiket..."
            className="h-8 w-full rounded-md border border-slate-300 bg-white pl-8 pr-2 text-xs focus:border-accent-500 focus:outline-none focus:ring-2 focus:ring-accent-100"
          />
        </div>
        <Select aria-label="Ürün" value={product} onChange={(e) => setProduct(e.target.value)} className="h-8 w-52 text-xs">
          <option value="">Ürün: tümü</option>
          {meta.products.map((p) => (
            <option key={p.code} value={p.code}>
              {p.name}
            </option>
          ))}
        </Select>
        <Select aria-label="Kategori" value={category} onChange={(e) => setCategory(e.target.value)} className="h-8 w-44 text-xs">
          <option value="">Kategori: tümü</option>
          {meta.categories.map((c) => (
            <option key={c.code} value={c.code}>
              {c.name}
            </option>
          ))}
        </Select>
        <Select aria-label="Durum" value={status} onChange={(e) => setStatus(e.target.value)} className="h-8 w-36 text-xs">
          <option value="">Durum: tümü</option>
          <option value="published">Yayında</option>
          <option value="draft">Taslak</option>
        </Select>
      </div>

      {error && !data ? (
        <ErrorState message={error.message} onRetry={() => void mutate()} />
      ) : isLoading && !data ? (
        <LoadingBlock />
      ) : data && data.articles.length === 0 ? (
        <Card>
          <EmptyState title="Makale bulunamadı" description="Aramayı değiştirin veya yeni bir makale oluşturun." />
        </Card>
      ) : (
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {data?.articles.map((a) => (
            <Link key={a.id} href={`/knowledge/${a.slug}`} className="group">
              <Card className="h-full p-4 transition group-hover:border-accent-500 group-hover:shadow">
                <div className="flex items-start justify-between gap-2">
                  <BookOpen className="mt-0.5 size-4 shrink-0 text-accent-600" aria-hidden />
                  <div className="flex gap-1">
                    {a.source === "ai_draft" && (
                      <Badge tone="teal">
                        <Sparkles className="size-3" aria-hidden /> AI taslağı
                      </Badge>
                    )}
                    <Badge tone={a.status === "published" ? "green" : "amber"}>{a.status === "published" ? "Yayında" : "Taslak"}</Badge>
                  </div>
                </div>
                <h2 className="mt-2 text-sm font-semibold text-slate-900 group-hover:text-accent-700">{a.title}</h2>
                <p className="mt-1 line-clamp-3 text-xs leading-relaxed text-slate-600">{a.excerpt}</p>
                <p className="mt-3 text-[11px] text-slate-500">
                  {a.product_name ?? "Genel"} · {a.category_name ?? "—"} · {timeAgo(a.updated_at)}
                </p>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </>
  );
}
