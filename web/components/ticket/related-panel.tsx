"use client";

import Link from "next/link";
import { useState } from "react";
import { AlertOctagon, Link2 } from "lucide-react";
import { api, errorMessage } from "@/lib/api";
import { percent } from "@/lib/format";
import type { IncidentDetail, TicketDetail } from "@/lib/types";
import { IncidentStatusBadge, StatusBadge } from "../badges";
import { Button, Card, CardHeader, ErrorState } from "../ui";

export function RelatedPanel({ ticket, onChanged }: { ticket: TicketDetail; onChanged: () => void }) {
  const [busy, setBusy] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function linkToIncident(incidentId: number) {
    setBusy(incidentId);
    setError(null);
    try {
      await api<{ incident: IncidentDetail }>(`/incidents/${incidentId}/tickets`, { method: "POST", body: { ticket_id: ticket.id } });
      onChanged();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(null);
    }
  }

  const hasAnything = ticket.incidents.length + ticket.incident_suggestions.length + ticket.similar_tickets.length > 0;

  return (
    <Card>
      <CardHeader title="İlişkili kayıtlar" description="Metin benzerliğiyle bulunur (LLM kullanılmaz)" />
      <div className="space-y-3 p-4">
        {!hasAnything && <p className="text-xs text-slate-500">Benzer ticket veya aktif olay bulunamadı.</p>}

        {ticket.incidents.map((inc) => (
          <Link key={inc.id} href={`/ai-insights?incident=${inc.id}`} className="block rounded-lg border border-violet-200 bg-violet-50 p-2.5 hover:border-violet-300">
            <span className="flex items-center justify-between gap-2 text-xs">
              <span className="font-medium text-violet-900">{inc.code} · bağlı olay</span>
              <IncidentStatusBadge status={inc.status} />
            </span>
            <span className="mt-1 block text-xs text-violet-900">{inc.title}</span>
          </Link>
        ))}

        {ticket.incident_suggestions.map((inc) => (
          <div key={inc.id} className="rounded-lg border border-amber-200 bg-amber-50 p-2.5">
            <p className="flex items-start gap-1.5 text-xs font-medium text-amber-900">
              <AlertOctagon className="mt-0.5 size-3.5 shrink-0" aria-hidden />
              Bu ticket {inc.code} olayına benziyor ({percent(inc.similarity)} benzerlik)
            </p>
            <p className="mt-1 text-xs text-amber-900">{inc.title}</p>
            <div className="mt-2 flex gap-1.5">
              <Button size="sm" variant="secondary" loading={busy === inc.id} onClick={() => void linkToIncident(inc.id)}>
                <Link2 className="size-3.5" aria-hidden /> Olaya bağla
              </Button>
              <Link href={`/ai-insights?incident=${inc.id}`} className="inline-flex h-8 items-center px-2 text-xs font-medium text-amber-900 underline-offset-2 hover:underline">
                Olayı aç
              </Link>
            </div>
          </div>
        ))}

        {ticket.similar_tickets.length > 0 && (
          <div>
            <p className="mb-1.5 text-[11px] font-medium uppercase tracking-wide text-slate-400">Benzer ticket&apos;lar</p>
            <ul className="space-y-1.5">
              {ticket.similar_tickets.map((t) => (
                <li key={t.id}>
                  <Link href={`/tickets/${t.id}`} className="flex items-center justify-between gap-2 rounded-md px-1.5 py-1 text-xs hover:bg-slate-50">
                    <span className="min-w-0">
                      <span className="text-slate-500">{t.number}</span> <span className="truncate text-slate-800">{t.subject}</span>
                    </span>
                    <span className="flex shrink-0 items-center gap-1.5">
                      <span className="text-[10px] text-slate-400">{percent(t.similarity)}</span>
                      <StatusBadge status={t.status} />
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
            {ticket.similar_tickets.length >= 2 && ticket.incidents.length === 0 && (
              <Link href="/ai-insights" className="mt-2 inline-block text-xs font-medium text-accent-700 hover:underline">
                Ortak bir sorun olabilir: AI Insights&apos;ta örüntü taraması yap →
              </Link>
            )}
          </div>
        )}
        {error && <ErrorState message={error} />}
      </div>
    </Card>
  );
}
