"use client";

import Link from "next/link";
import { useParams, useSearchParams } from "next/navigation";
import { useState } from "react";
import { ArrowLeft, Building2, History } from "lucide-react";
import { ChannelBadge, PriorityBadge, SlaBadge, StatusBadge } from "@/components/badges";
import { CsatPanel } from "@/components/ticket/csat-panel";
import { Conversation } from "@/components/ticket/conversation";
import { KnowledgePanel } from "@/components/ticket/knowledge-panel";
import { PropertiesPanel } from "@/components/ticket/properties-panel";
import { RelatedPanel } from "@/components/ticket/related-panel";
import { ReplyComposer, type Draft } from "@/components/ticket/reply-composer";
import { ResolutionPanel } from "@/components/ticket/resolution-panel";
import { TriagePanel } from "@/components/ticket/triage-panel";
import { Card, CardHeader, ErrorState, LoadingBlock } from "@/components/ui";
import { formatDateTime, timeAgo } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import { actionLabel } from "@/lib/labels";
import type { TicketDetail } from "@/lib/types";

export default function TicketPage() {
  const { id } = useParams<{ id: string }>();
  const searchParams = useSearchParams();
  const { data, error, mutate } = useApi<{ ticket: TicketDetail }>(`/tickets/${id}`);
  const [draft, setDraft] = useState<Draft>({ body: "", origin: "manual" });

  if (error && !data) return <ErrorState message={error.message} onRetry={() => void mutate()} />;
  if (!data) return <LoadingBlock label="Ticket yükleniyor..." />;

  const ticket = data.ticket;
  const setTicket = (t: TicketDetail) => void mutate({ ticket: t }, { revalidate: false });
  const applyDraft = (d: Draft) => {
    setDraft(d);
    document.getElementById("composer")?.focus();
  };

  return (
    <div>
      <Link href="/tickets" className="mb-3 inline-flex items-center gap-1 text-xs text-slate-500 hover:text-slate-900">
        <ArrowLeft className="size-3.5" aria-hidden /> Ticket&apos;lar
      </Link>
      <div className="mb-5 flex flex-wrap items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-xs text-slate-500">
            {ticket.number} · {formatDateTime(ticket.created_at)} · {ticket.product_name ?? "Ürün belirtilmedi"}
          </p>
          <h1 className="mt-1 text-xl font-semibold tracking-tight text-slate-900">{ticket.subject}</h1>
          <div className="mt-2 flex flex-wrap gap-1.5">
            <StatusBadge status={ticket.status} />
            <PriorityBadge priority={ticket.priority} />
            <ChannelBadge channel={ticket.channel} />
            <SlaBadge sla={ticket.sla} />
            {ticket.tags.map((tag) => (
              <span key={tag} className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] text-slate-600">
                {tag}
              </span>
            ))}
            {ticket.category_name && <span className="text-xs text-slate-500">· {ticket.category_name}</span>}
          </div>
        </div>
      </div>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_340px]">
        <div className="min-w-0 space-y-5">
          <Conversation messages={ticket.messages} />
          <ReplyComposer ticket={ticket} draft={draft} setDraft={setDraft} onSent={setTicket} />
          <Card>
            <CardHeader title="Aktivite geçmişi" description="Denetim kaydı (audit log)" />
            <ul className="divide-y divide-slate-100">
              {ticket.activity.length === 0 && <li className="px-4 py-3 text-xs text-slate-500">Henüz aktivite yok.</li>}
              {ticket.activity.map((a) => (
                <li key={a.id} className="flex items-center justify-between gap-3 px-4 py-2 text-xs">
                  <span className="text-slate-700">
                    <strong className="font-medium text-slate-900">{a.actor_name}</strong> {actionLabel(a.action)}
                  </span>
                  <time className="shrink-0 text-slate-400" dateTime={a.created_at}>
                    {timeAgo(a.created_at)}
                  </time>
                </li>
              ))}
            </ul>
          </Card>
        </div>

        <aside className="space-y-4">
          <TriagePanel ticket={ticket} autoRun={searchParams.get("triage") === "auto"} onTicket={setTicket} onDraft={applyDraft} />
          <Card>
            <CardHeader title="Müşteri" />
            <div className="space-y-1.5 p-4 text-sm">
              <p className="font-medium text-slate-900">{ticket.customer.name}</p>
              <p className="text-xs text-slate-500">{ticket.customer.email}</p>
              {ticket.customer.company && (
                <p className="flex items-center gap-1 text-xs text-slate-600">
                  <Building2 className="size-3.5" aria-hidden /> {ticket.customer.company} · {ticket.customer.tier}
                </p>
              )}
              <Link href={`/customers/${ticket.customer.id}`} className="mt-1 inline-flex items-center gap-1 text-xs font-medium text-accent-700 hover:underline">
                <History className="size-3.5" aria-hidden /> Müşteri geçmişi ({ticket.customer_history.total_tickets} ticket, {ticket.customer_history.open_tickets} açık)
              </Link>
            </div>
          </Card>
          <PropertiesPanel ticket={ticket} onChange={setTicket} />
          <CsatPanel ticket={ticket} onChange={setTicket} />
          <RelatedPanel ticket={ticket} onChanged={() => void mutate()} />
          <KnowledgePanel ticket={ticket} onTicket={setTicket} onDraft={applyDraft} currentDraft={draft} />
          <ResolutionPanel ticket={ticket} onDraft={applyDraft} />
        </aside>
      </div>
    </div>
  );
}
