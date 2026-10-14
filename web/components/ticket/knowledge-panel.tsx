"use client";

import Link from "next/link";
import { useState } from "react";
import { BookOpen, Link2, Unlink } from "lucide-react";
import { api, errorMessage } from "@/lib/api";
import { useApi } from "@/lib/hooks";
import type { ArticleDetail, ArticleSummary, TicketDetail } from "@/lib/types";
import { Button, Card, CardHeader, ErrorState, Input, Spinner } from "../ui";
import type { Draft } from "./reply-composer";

export function KnowledgePanel({
  ticket,
  onTicket,
  onDraft,
  currentDraft,
}: {
  ticket: TicketDetail;
  onTicket: (t: TicketDetail) => void;
  onDraft: (d: Draft) => void;
  currentDraft: Draft;
}) {
  const [query, setQuery] = useState("");
  const [busy, setBusy] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const search = useApi<{ articles: ArticleSummary[] }>(
    query.trim().length >= 2 ? `/articles?status=published&q=${encodeURIComponent(query.trim())}` : null,
    { keepPreviousData: true },
  );

  async function link(article: ArticleSummary) {
    setBusy(article.id);
    setError(null);
    try {
      const res = await api<{ ticket: TicketDetail }>(`/tickets/${ticket.id}/articles`, { method: "POST", body: { article_id: article.id } });
      onTicket(res.ticket);
      setQuery("");
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(null);
    }
  }

  async function unlink(article: ArticleSummary) {
    setBusy(article.id);
    try {
      const res = await api<{ ticket: TicketDetail }>(`/tickets/${ticket.id}/articles/${article.id}`, { method: "DELETE" });
      onTicket(res.ticket);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(null);
    }
  }

  async function insert(article: ArticleSummary) {
    setBusy(article.id);
    setError(null);
    try {
      const { article: full } = await api<{ article: ArticleDetail }>(`/articles/${article.id}`);
      const steps = full.steps.length ? full.steps.map((s, i) => `${i + 1}. ${s}`).join("\n") : full.body;
      const greeting = `Merhaba ${ticket.customer.name.split(" ")[0]},\n\n`;
      const block = `"${full.title}" rehberimize göre şu adımları uygulayabilirsiniz:\n${steps}\n\nSonucu bize iletirseniz yardımcı olmaya devam edeceğiz.`;
      const body = currentDraft.body.trim() ? `${currentDraft.body.trim()}\n\n${block}` : `${greeting}${block}`;
      onDraft({ body, origin: currentDraft.origin === "ai_draft" ? "ai_draft" : "knowledge" });
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(null);
    }
  }

  const linkedIds = new Set(ticket.articles.map((a) => a.id));
  const results = (search.data?.articles ?? []).filter((a) => !linkedIds.has(a.id)).slice(0, 5);

  return (
    <Card>
      <CardHeader title="Bilgi bankası" description="Makale bağla ve çözüm adımlarını yanıta ekle" />
      <div className="space-y-3 p-4">
        {ticket.articles.length === 0 ? (
          <p className="text-xs text-slate-500">Bağlı makale yok.</p>
        ) : (
          <ul className="space-y-2">
            {ticket.articles.map((a) => (
              <li key={a.id} className="rounded-lg border border-slate-200 p-2.5">
                <Link href={`/knowledge/${a.slug}`} className="flex items-start gap-1.5 text-xs font-medium text-slate-900 hover:text-accent-700">
                  <BookOpen className="mt-0.5 size-3.5 shrink-0 text-accent-600" aria-hidden /> {a.title}
                </Link>
                <div className="mt-2 flex gap-1.5">
                  <Button size="sm" variant="secondary" loading={busy === a.id} onClick={() => void insert(a)}>
                    Yanıta ekle
                  </Button>
                  <Button size="sm" variant="ghost" disabled={busy === a.id} onClick={() => void unlink(a)} aria-label={`${a.title} bağlantısını kaldır`}>
                    <Unlink className="size-3.5" aria-hidden />
                  </Button>
                </div>
              </li>
            ))}
          </ul>
        )}
        <div>
          <label htmlFor="kb-search" className="sr-only">
            Makale ara
          </label>
          <Input id="kb-search" value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Makale ara (ör. şarj, LED, garanti)" className="h-8 text-xs" />
          {search.isLoading && <div className="mt-2"><Spinner label="Aranıyor..." /></div>}
          {query.trim().length >= 2 && !search.isLoading && results.length === 0 && <p className="mt-2 text-xs text-slate-500">Sonuç yok.</p>}
          {results.length > 0 && (
            <ul className="mt-2 divide-y divide-slate-100 rounded-lg border border-slate-200">
              {results.map((a) => (
                <li key={a.id} className="flex items-center justify-between gap-2 px-2.5 py-2">
                  <span className="min-w-0">
                    <span className="block truncate text-xs font-medium text-slate-800">{a.title}</span>
                    <span className="block truncate text-[11px] text-slate-500">{a.category_name ?? "Genel"}</span>
                  </span>
                  <Button size="sm" variant="secondary" loading={busy === a.id} onClick={() => void link(a)}>
                    <Link2 className="size-3.5" aria-hidden /> Bağla
                  </Button>
                </li>
              ))}
            </ul>
          )}
        </div>
        {error && <ErrorState message={error} />}
      </div>
    </Card>
  );
}
