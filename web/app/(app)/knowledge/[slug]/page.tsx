"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { ArrowLeft, Pencil, Sparkles } from "lucide-react";
import { ArticleForm } from "@/components/knowledge/article-form";
import { useSession } from "@/components/session";
import { Badge, Button, Card, ErrorState, LoadingBlock } from "@/components/ui";
import { api, errorMessage } from "@/lib/api";
import { formatDate } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import type { ArticleDetail } from "@/lib/types";

export default function ArticlePage() {
  const { slug } = useParams<{ slug: string }>();
  const router = useRouter();
  const { me } = useSession();
  const { data, error, mutate } = useApi<{ article: ArticleDetail }>(`/articles/${slug}`);
  const [editing, setEditing] = useState(false);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  if (error && !data) return <ErrorState message={error.message} onRetry={() => void mutate()} />;
  if (!data) return <LoadingBlock />;
  const article = data.article;
  const isManager = me.role === "manager";
  const canEdit = article.status === "draft" || isManager;

  async function toggle() {
    setBusy(true);
    setActionError(null);
    try {
      const res = await api<{ article: ArticleDetail }>(`/articles/${article.id}/${article.status === "published" ? "unpublish" : "publish"}`, { method: "POST" });
      void mutate(res, { revalidate: false });
    } catch (err) {
      setActionError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto max-w-3xl">
      <Link href="/knowledge" className="mb-3 inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-900">
        <ArrowLeft className="size-3.5" aria-hidden /> Bilgi bankası
      </Link>
      {editing ? (
        <Card className="p-5">
          <ArticleForm
            article={article}
            onCancel={() => setEditing(false)}
            onSaved={(a) => {
              setEditing(false);
              if (a.slug !== slug) router.replace(`/knowledge/${a.slug}`);
              else void mutate({ article: a }, { revalidate: false });
            }}
          />
        </Card>
      ) : (
        <Card>
          <div className="flex flex-wrap items-start justify-between gap-3 border-b border-slate-100 p-5">
            <div className="min-w-0">
              <div className="flex flex-wrap gap-1.5">
                <Badge tone={article.status === "published" ? "green" : "amber"}>{article.status === "published" ? "Yayında" : "Taslak"}</Badge>
                {article.source === "ai_draft" && (
                  <Badge tone="teal">
                    <Sparkles className="size-3" aria-hidden /> AI tarafından önerildi
                  </Badge>
                )}
                {article.tags.map((t) => (
                  <Badge key={t}>#{t}</Badge>
                ))}
              </div>
              <h1 className="mt-2 text-xl font-semibold tracking-tight text-slate-900">{article.title}</h1>
              <p className="mt-1 text-xs text-slate-500">
                {article.product_name ?? "Genel"} · {article.category_name ?? "—"} · {article.linked_tickets_count} ticket&apos;a bağlı ·
                güncellendi {formatDate(article.updated_at)}
              </p>
            </div>
            <div className="flex gap-2">
              {canEdit && (
                <Button variant="secondary" size="sm" onClick={() => setEditing(true)}>
                  <Pencil className="size-3.5" aria-hidden /> Düzenle
                </Button>
              )}
              {isManager ? (
                <Button variant={article.status === "published" ? "secondary" : "accent"} size="sm" loading={busy} onClick={() => void toggle()}>
                  {article.status === "published" ? "Yayından kaldır" : "Yayınla"}
                </Button>
              ) : (
                article.status === "draft" && <span className="self-center text-xs text-slate-500">Yayın için yönetici onayı gerekir</span>
              )}
            </div>
          </div>
          {actionError && (
            <div className="px-5 pt-4">
              <ErrorState message={actionError} />
            </div>
          )}
          <div className="whitespace-pre-wrap p-5 text-sm leading-relaxed text-slate-800">{article.body}</div>
        </Card>
      )}
    </div>
  );
}
