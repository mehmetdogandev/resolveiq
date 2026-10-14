"use client";

import { useState } from "react";
import { Lightbulb, RefreshCw } from "lucide-react";
import { api } from "@/lib/api";
import type { AgentRun, ResolutionOutput, TicketDetail } from "@/lib/types";
import { AiErrorNotice } from "../ai/ai-unavailable";
import { KbDraftButton } from "../ai/kb-draft-button";
import { RunMeta } from "../ai/run-meta";
import { Button, Card, Spinner } from "../ui";
import type { Draft } from "./reply-composer";

export function ResolutionPanel({ ticket, onDraft }: { ticket: TicketDetail; onDraft: (d: Draft) => void }) {
  const [localRun, setRun] = useState<AgentRun<ResolutionOutput> | null>(null);
  const [running, setRunning] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const serverRun = ticket.latest_resolution;
  const run = localRun && (!serverRun || localRun.id > serverRun.id) ? localRun : serverRun;

  async function prepare() {
    setRunning(true);
    setError(null);
    try {
      const res = await api<{ run: AgentRun<ResolutionOutput> }>(`/tickets/${ticket.id}/prepare_resolution`, { method: "POST" });
      setRun(res.run);
    } catch (err) {
      setError(err);
    } finally {
      setRunning(false);
    }
  }

  const out = run?.status === "succeeded" ? run.output : null;
  const reply = out ? out.customer_reply.replaceAll("{{musteri_adi}}", ticket.customer.name.split(" ")[0]) : "";

  return (
    <Card>
      <div className="flex items-center justify-between gap-2 border-b border-slate-100 px-4 py-3">
        <h2 className="flex items-center gap-1.5 text-sm font-semibold text-slate-900">
          <Lightbulb className="size-4 text-accent-600" aria-hidden /> Çözüm önerisi
        </h2>
        {out && !running && (
          <Button variant="ghost" size="sm" onClick={() => void prepare()}>
            <RefreshCw className="size-3.5" aria-hidden /> Yenile
          </Button>
        )}
      </div>
      <div className="space-y-3 p-4">
        {running && <Spinner label="Makaleler ve önceki çözümler taranıyor..." />}
        {!out && !running && (
          <div className="space-y-2">
            <p className="text-xs text-slate-600">Bilgi bankası ve önceki çözümlerden sorun giderme adımları ve yanıt taslağı hazırlar.</p>
            <Button size="sm" variant="secondary" onClick={() => void prepare()}>
              Çözüm taslağı hazırla
            </Button>
          </div>
        )}
        {error != null && <AiErrorNotice error={error} />}
        {out && run && !running && (
          <>
            <ol className="list-decimal space-y-1 pl-4 text-xs text-slate-700">
              {out.troubleshooting_steps.map((s) => (
                <li key={s}>{s}</li>
              ))}
            </ol>
            {out.internal_escalation.needed && (
              <p className="rounded-md bg-amber-50 px-2.5 py-2 text-xs text-amber-900">
                Eskalasyon önerisi: <strong>{out.internal_escalation.team}</strong> · {out.internal_escalation.summary}
              </p>
            )}
            <Button size="sm" variant="accent" onClick={() => onDraft({ body: reply, origin: "ai_draft" })}>
              Yanıt taslağını kullan
            </Button>
            {out.kb_gap && out.kb_article.title && (
              <div className="rounded-lg border border-dashed border-slate-300 p-2.5">
                <p className="mb-1.5 text-xs text-slate-600">
                  Bilgi bankasında boşluk tespit edildi: <strong>{out.kb_article.title}</strong>
                </p>
                <KbDraftButton title={out.kb_article.title} body={out.kb_article.body} tags={out.kb_article.tags} product={ticket.product} category={ticket.category} runId={run.id} />
              </div>
            )}
            <RunMeta run={run} />
          </>
        )}
      </div>
    </Card>
  );
}
