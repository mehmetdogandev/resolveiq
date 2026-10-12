"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { ErrorState, Input, LoadingBlock } from "@/components/ui";
import { useApi } from "@/lib/hooks";
import type { ArticleSummary, CodeName } from "@/lib/types";

type HelpList = { articles: ArticleSummary[]; categories: CodeName[]; products: CodeName[] };

export default function HelpIndexPage() {
  const [q, setQ] = useState("");
  const query = useMemo(() => (q.trim() ? `?q=${encodeURIComponent(q.trim())}` : ""), [q]);
  const { data, error, mutate } = useApi<HelpList>(`/help/articles${query}`);

  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight text-slate-900">Northforge Tools yardım merkezi</h1>
      <p className="mt-2 text-sm text-slate-600">Sık karşılaşılan batarya, garanti ve kullanım soruları. Tüm içerik sentetik bir demo markasına aittir.</p>
      <div className="mt-5">
        <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Makale ara…" aria-label="Makale ara" />
      </div>
      {error && !data ? (
        <div className="mt-6">
          <ErrorState message={error.message} onRetry={() => void mutate()} />
        </div>
      ) : !data ? (
        <LoadingBlock label="Makaleler yükleniyor..." />
      ) : data.articles.length === 0 ? (
        <p className="mt-6 text-sm text-slate-500">Sonuç yok. Farklı bir arama deneyin veya destek talebi açın.</p>
      ) : (
        <ul className="mt-6 space-y-3">
          {data.articles.map((article) => (
            <li key={article.id}>
              <Link href={`/help/${article.slug}`} className="block rounded-xl border border-slate-200 bg-white p-4 hover:border-slate-300">
                <p className="text-sm font-medium text-slate-900">{article.title}</p>
                <p className="mt-1 text-xs text-slate-500">{article.excerpt}</p>
                <p className="mt-2 text-[11px] text-slate-400">{article.category_name ?? "Genel"}</p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
