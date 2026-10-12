"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { ErrorState, LoadingBlock } from "@/components/ui";
import { useApi } from "@/lib/hooks";
import type { ArticleDetail } from "@/lib/types";

export default function HelpArticlePage() {
  const { slug } = useParams<{ slug: string }>();
  const { data, error, mutate } = useApi<{ article: ArticleDetail }>(`/help/articles/${slug}`);

  if (error && !data) return <ErrorState message={error.message} onRetry={() => void mutate()} />;
  if (!data) return <LoadingBlock label="Makale yükleniyor..." />;

  const article = data.article;
  return (
    <article>
      <Link href="/help" className="text-xs text-slate-500 hover:text-slate-900">
        ← Yardım merkezi
      </Link>
      <h1 className="mt-3 text-2xl font-semibold tracking-tight text-slate-900">{article.title}</h1>
      <p className="mt-1 text-xs text-slate-500">
        {article.category_name ?? "Genel"}
        {article.product_name ? ` · ${article.product_name}` : ""}
      </p>
      <div className="mt-6 whitespace-pre-wrap text-sm leading-relaxed text-slate-800">{article.body}</div>
      <p className="mt-8 text-sm">
        Sorun çözülmedi mi?{" "}
        <Link href="/help/request" className="font-medium text-accent-700 hover:underline">
          Destek talebi oluşturun
        </Link>
        .
      </p>
    </article>
  );
}
