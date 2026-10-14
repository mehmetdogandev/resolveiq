"use client";

import { useEffect, useRef, useState } from "react";
import { ArrowRight, Check, RefreshCw, Sparkles } from "lucide-react";
import { api, errorMessage } from "@/lib/api";
import { percent } from "@/lib/format";
import { PRIORITY_LABEL } from "@/lib/labels";
import type { AgentRun, TicketDetail, TriageOutput } from "@/lib/types";
import { AiErrorNotice } from "../ai/ai-unavailable";
import { RunMeta } from "../ai/run-meta";
import { Badge, Button, Card, ErrorState, Spinner } from "../ui";
import type { Draft } from "./reply-composer";

type Field = "category" | "priority" | "assignee";

export function TriagePanel({
  ticket,
  autoRun,
  onTicket,
  onDraft,
}: {
  ticket: TicketDetail;
  autoRun: boolean;
  onTicket: (t: TicketDetail) => void;
  onDraft: (d: Draft) => void;
}) {
  const [localRun, setRun] = useState<AgentRun<TriageOutput> | null>(null);
  const [running, setRunning] = useState(false);
  const [applying, setApplying] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [applyError, setApplyError] = useState<string | null>(null);
  const [selected, setSelected] = useState<Record<Field, boolean>>({ category: true, priority: true, assignee: true });
  const autoStarted = useRef(false);
  const serverRun = ticket.latest_triage;
  const run = localRun && (!serverRun || localRun.id > serverRun.id) ? localRun : serverRun;

  async function runTriage() {
    setRunning(true);
    setError(null);
    try {
      const res = await api<{ run: AgentRun<TriageOutput> }>(`/tickets/${ticket.id}/triage`, { method: "POST" });
      setRun(res.run);
    } catch (err) {
      setError(err);
    } finally {
      setRunning(false);
    }
  }

  useEffect(() => {
    if (autoRun && !ticket.latest_triage && !autoStarted.current) {
      autoStarted.current = true;
      void runTriage();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [autoRun, ticket.latest_triage]);

  async function apply() {
    if (!run) return;
    setApplying(true);
    setApplyError(null);
    try {
      const fields = (Object.keys(selected) as Field[]).filter((f) => selected[f]);
      const res = await api<{ ticket: TicketDetail }>(`/tickets/${ticket.id}/triage/apply`, { method: "POST", body: { run_id: run.id, fields } });
      onTicket(res.ticket);
    } catch (err) {
      setApplyError(errorMessage(err));
    } finally {
      setApplying(false);
    }
  }

  const out = run?.status === "succeeded" ? run.output : null;
  const rows: { field: Field; label: string; current: string; next: string | null; same: boolean }[] = out
    ? [
        { field: "category", label: "Kategori", current: ticket.category_name ?? "—", next: out.category_name, same: out.category === ticket.category },
        {
          field: "priority",
          label: "Öncelik",
          current: PRIORITY_LABEL[ticket.priority],
          next: out.priority ? PRIORITY_LABEL[out.priority] : null,
          same: out.priority === ticket.priority,
        },
        {
          field: "assignee",
          label: "Sorumlu",
          current: ticket.assignee?.name ?? "Atanmamış",
          next: out.assignee_name ? `${out.assignee_name}${out.team_name ? ` · ${out.team_name}` : ""}` : null,
          same: out.assignee_id === ticket.assignee?.id,
        },
      ]
    : [];
  const pendingChanges = rows.some((r) => r.next && !r.same && selected[r.field]);
  const pendingArticles = out ? out.articles.some((a) => !ticket.articles.some((ta) => ta.id === a.id)) : false;

  return (
    <Card className="border-accent-100">
      <div className="flex items-center justify-between gap-2 border-b border-accent-100 bg-accent-50/60 px-4 py-3">
        <h2 className="flex items-center gap-1.5 text-sm font-semibold text-slate-900">
          <Sparkles className="size-4 text-accent-600" aria-hidden /> Akıllı triage
        </h2>
        {run && !running && (
          <Button variant="ghost" size="sm" onClick={() => void runTriage()}>
            <RefreshCw className="size-3.5" aria-hidden /> Yeniden çalıştır
          </Button>
        )}
      </div>
      <div className="space-y-3 p-4">
        {running && <Spinner label="ResolveIQ ticket'ı okuyor, kategori, öncelik ve sorumlu öneriyor..." />}
        {!run && !running && !error && (
          <div className="space-y-2">
            <p className="text-xs text-slate-600">Kategori, öncelik, sorumlu, ilgili makaleler ve müşteri yanıtı taslağını tek seferde hazırlar.</p>
            <Button variant="accent" size="sm" onClick={() => void runTriage()}>
              <Sparkles className="size-3.5" aria-hidden /> Triage çalıştır
            </Button>
          </div>
        )}
        {error != null && <AiErrorNotice error={error} />}
        {run?.status === "failed" && !running && <ErrorState message={`Son AI çağrısı başarısız: ${run.error_summary ?? ""}`} />}

        {out && !running && run && (
          <>
            <div className="flex items-center justify-between text-xs">
              <span className="text-slate-500">Güven: {percent(out.confidence)}</span>
              {run.applied_at ? <Badge tone="green">Uygulandı</Badge> : <Badge tone="violet">Onayınızı bekliyor</Badge>}
            </div>
            <ul className="divide-y divide-slate-100 rounded-lg border border-slate-200">
              {rows.map((r) => (
                <li key={r.field} className="flex items-center gap-2 px-3 py-2 text-xs">
                  <input
                    type="checkbox"
                    aria-label={`${r.label} önerisini uygula`}
                    className="accent-accent-600"
                    checked={selected[r.field]}
                    disabled={!r.next || r.same}
                    onChange={(e) => setSelected((s) => ({ ...s, [r.field]: e.target.checked }))}
                  />
                  <span className="w-16 shrink-0 text-slate-500">{r.label}</span>
                  {r.next ? (
                    r.same ? (
                      <span className="flex items-center gap-1 text-slate-600">
                        <Check className="size-3 text-emerald-600" aria-hidden /> {r.next}
                      </span>
                    ) : (
                      <span className="flex min-w-0 items-center gap-1">
                        <span className="truncate text-slate-400 line-through">{r.current}</span>
                        <ArrowRight className="size-3 shrink-0 text-slate-400" aria-hidden />
                        <span className="truncate font-medium text-slate-900">{r.next}</span>
                      </span>
                    )
                  ) : (
                    <span className="text-slate-400">Öneri yok</span>
                  )}
                </li>
              ))}
            </ul>
            <p className="text-xs leading-relaxed text-slate-700">{out.reasoning}</p>
            {out.evidence.length > 0 && (
              <ul className="space-y-0.5 text-[11px] text-slate-500">
                {out.evidence.map((e) => (
                  <li key={e}>“{e}”</li>
                ))}
              </ul>
            )}
            {out.articles.length > 0 && (
              <p className="text-xs text-slate-600">
                İlgili makaleler: {out.articles.map((a) => a.title).join(", ")}
              </p>
            )}
            {out.dropped_suggestions.length > 0 && (
              <p className="text-[11px] text-slate-400">Doğrulanamayan {out.dropped_suggestions.length} öneri sunucuda elendi.</p>
            )}
            {applyError && <ErrorState message={applyError} />}
            <div className="flex flex-wrap gap-2">
              <Button variant="accent" size="sm" loading={applying} disabled={!pendingChanges && !pendingArticles} onClick={() => void apply()}>
                <Check className="size-3.5" aria-hidden /> Önerileri uygula
              </Button>
              {out.draft_reply && (
                <Button variant="secondary" size="sm" onClick={() => onDraft({ body: out.draft_reply, origin: "ai_draft" })}>
                  Yanıt taslağını kullan
                </Button>
              )}
            </div>
            <RunMeta run={run} />
          </>
        )}
      </div>
    </Card>
  );
}
