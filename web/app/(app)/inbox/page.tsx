"use client";

import Link from "next/link";
import { useState } from "react";
import { ArrowRight, ChevronLeft, ChevronRight } from "lucide-react";
import { ChannelBadge, ChannelIcon, PriorityBadge, SlaBadge, StatusBadge } from "@/components/badges";
import { CustomerHistory } from "@/components/customer-history";
import { ChannelTabs, TicketFilterBar, useTicketQuery } from "@/components/tickets/ticket-filters";
import { Button, Card, CardHeader, DemoDataNote, EmptyState, ErrorState, LoadingBlock, PageHeader, Select, cn } from "@/components/ui";
import { api, errorMessage } from "@/lib/api";
import { timeAgo } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import type { TicketDetail, TicketList, TicketStatus } from "@/lib/types";
import { STATUS_LABEL } from "@/lib/labels";

export default function InboxPage() {
  const { values, apiQuery, setParams, rawParams } = useTicketQuery({ open_only: "true", sort: "priority" });
  const { data, error, isLoading, mutate } = useApi<TicketList>(`/tickets?${apiQuery}`, { keepPreviousData: true, refreshInterval: 30000 });
  const selectedId = rawParams.get("selected") ?? (data?.tickets[0] ? String(data.tickets[0].id) : null);
  const selected = useApi<{ ticket: TicketDetail }>(selectedId ? `/tickets/${selectedId}` : null);
  const page = Number(values.page ?? 1);
  const [picked, setPicked] = useState<number[]>([]);
  const [bulkStatus, setBulkStatus] = useState<TicketStatus>("pending");
  const [bulkError, setBulkError] = useState<string | null>(null);
  const [bulkBusy, setBulkBusy] = useState(false);

  function toggle(id: number) {
    setPicked((current) => (current.includes(id) ? current.filter((x) => x !== id) : [ ...current, id ]));
  }

  async function bulkUpdate() {
    if (picked.length === 0) return;
    setBulkBusy(true);
    setBulkError(null);
    try {
      await api("/tickets/bulk_update", { method: "POST", body: { ids: picked, ticket: { status: bulkStatus } } });
      setPicked([]);
      await mutate();
    } catch (err) {
      setBulkError(errorMessage(err));
    } finally {
      setBulkBusy(false);
    }
  }

  return (
    <>
      <PageHeader
        title="Birleşik gelen kutusu"
        description={
          <span className="flex flex-wrap items-center gap-2">
            E-posta, web formu ve canlı sohbet talepleri tek listede. Kanallar sentetiktir; gerçek entegrasyon yoktur. <DemoDataNote />
          </span>
        }
      />
      <div className="mb-3 flex flex-wrap items-center justify-between gap-3">
        <ChannelTabs value={values.channel ?? ""} counts={data?.meta.channel_counts} onChange={(c) => setParams({ channel: c, selected: null })} />
        <label className="flex items-center gap-2 text-xs text-slate-600">
          <input
            type="checkbox"
            className="accent-accent-600"
            checked={values.open_only === "true"}
            onChange={(e) => setParams({ open_only: e.target.checked ? "true" : "false", selected: null })}
          />
          Yalnızca çözülmemişler
        </label>
      </div>
      <div className="mb-4">
        <TicketFilterBar values={values} setParams={(next) => setParams({ ...next, selected: null })} compact />
      </div>
      {picked.length > 0 && (
        <div className="mb-3 flex flex-wrap items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm">
          <span className="text-slate-600">{picked.length} seçili</span>
          <Select value={bulkStatus} onChange={(e) => setBulkStatus(e.target.value as TicketStatus)} className="h-8 w-40 text-xs">
            {(Object.keys(STATUS_LABEL) as TicketStatus[]).map((s) => (
              <option key={s} value={s}>
                {STATUS_LABEL[s]}
              </option>
            ))}
          </Select>
          <Button size="sm" loading={bulkBusy} onClick={() => void bulkUpdate()}>
            Toplu güncelle
          </Button>
          <Button size="sm" variant="ghost" onClick={() => setPicked([])}>
            Seçimi temizle
          </Button>
          {bulkError && <span className="text-xs text-red-600">{bulkError}</span>}
        </div>
      )}

      <div className="grid gap-4 lg:grid-cols-[minmax(0,420px)_minmax(0,1fr)]">
        <Card className="overflow-hidden">
          {error && !data ? (
            <div className="p-4">
              <ErrorState message={error.message} onRetry={() => void mutate()} />
            </div>
          ) : isLoading && !data ? (
            <LoadingBlock label="Gelen kutusu yükleniyor..." />
          ) : data && data.tickets.length === 0 ? (
            <EmptyState title="Gelen kutusu boş" description="Bu filtrelere uyan talep yok." />
          ) : (
            data && (
              <ul className="max-h-[70vh] divide-y divide-slate-100 overflow-y-auto scrollbar-thin" aria-label="Talepler">
                {data.tickets.map((t) => {
                  const active = String(t.id) === selectedId;
                  return (
                    <li key={t.id} className="flex items-start gap-1">
                      <label className="pl-3 pt-4">
                        <input type="checkbox" className="accent-accent-600" checked={picked.includes(t.id)} onChange={() => toggle(t.id)} aria-label={`${t.number} seç`} />
                      </label>
                      <button
                        type="button"
                        onClick={() => setParams({ selected: String(t.id) }, false)}
                        aria-current={active ? "true" : undefined}
                        className={cn(
                          "block min-w-0 flex-1 px-3 py-3 text-left transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-accent-500",
                          active ? "bg-accent-50" : "hover:bg-slate-50",
                        )}
                      >
                        <span className="flex items-center justify-between gap-2 text-xs text-slate-500">
                          <span className="flex items-center gap-1.5">
                            <ChannelIcon channel={t.channel} /> {t.customer.name}
                          </span>
                          <span>{timeAgo(t.created_at)}</span>
                        </span>
                        <span className="mt-1 block truncate text-sm font-medium text-slate-900">{t.subject}</span>
                        <span className="mt-1.5 flex flex-wrap items-center gap-1.5">
                          <StatusBadge status={t.status} />
                          <PriorityBadge priority={t.priority} />
                          <SlaBadge sla={t.sla} />
                          <span className="text-[11px] text-slate-500">{t.number}</span>
                          {!t.assignee && <span className="text-[11px] text-amber-700">· atanmamış</span>}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            )
          )}
          {data && data.meta.total_pages > 1 && (
            <div className="flex items-center justify-between border-t border-slate-100 px-4 py-2 text-xs text-slate-500">
              <span>
                {data.meta.total} talep · {page}/{data.meta.total_pages}
              </span>
              <div className="flex gap-1">
                <Button variant="secondary" size="sm" disabled={page <= 1} onClick={() => setParams({ page: String(page - 1), selected: null })} aria-label="Önceki sayfa">
                  <ChevronLeft className="size-4" />
                </Button>
                <Button variant="secondary" size="sm" disabled={page >= data.meta.total_pages} onClick={() => setParams({ page: String(page + 1), selected: null })} aria-label="Sonraki sayfa">
                  <ChevronRight className="size-4" />
                </Button>
              </div>
            </div>
          )}
        </Card>

        <div className="space-y-4">
          {selected.data ? (
            <>
              <Card>
                <div className="flex flex-wrap items-start justify-between gap-3 border-b border-slate-100 px-4 py-3">
                  <div className="min-w-0">
                    <p className="text-xs text-slate-500">
                      {selected.data.ticket.number} · {selected.data.ticket.product_name ?? "Ürün belirtilmedi"}
                    </p>
                    <h2 className="mt-0.5 text-base font-semibold text-slate-900">{selected.data.ticket.subject}</h2>
                    <div className="mt-1.5 flex flex-wrap gap-1.5">
                      <StatusBadge status={selected.data.ticket.status} />
                      <PriorityBadge priority={selected.data.ticket.priority} />
                      <ChannelBadge channel={selected.data.ticket.channel} />
                    </div>
                  </div>
                  <Link href={`/tickets/${selected.data.ticket.id}`}>
                    <Button variant="accent" size="sm">
                      Ticket&apos;ı aç <ArrowRight className="size-3.5" aria-hidden />
                    </Button>
                  </Link>
                </div>
                <div className="space-y-3 p-4">
                  <p className="whitespace-pre-wrap text-sm leading-relaxed text-slate-700">{selected.data.ticket.description}</p>
                  {selected.data.ticket.similar_tickets.length > 0 && (
                    <div className="rounded-lg border border-violet-200 bg-violet-50 p-3">
                      <p className="text-xs font-medium text-violet-900">
                        {selected.data.ticket.similar_tickets.length} benzer talep bulundu: olası ortak sorun
                      </p>
                      <ul className="mt-1.5 space-y-1">
                        {selected.data.ticket.similar_tickets.slice(0, 4).map((s) => (
                          <li key={s.id}>
                            <button type="button" onClick={() => setParams({ selected: String(s.id) }, false)} className="text-left text-xs text-violet-900 hover:underline">
                              {s.number} · {s.subject}
                            </button>
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              </Card>
              <Card>
                <CardHeader title="Müşteri geçmişi" />
                <div className="p-4">
                  <CustomerHistory customerId={selected.data.ticket.customer.id} highlightId={selected.data.ticket.id} limit={6} />
                </div>
              </Card>
            </>
          ) : selectedId ? (
            <LoadingBlock label="Talep yükleniyor..." />
          ) : (
            <Card>
              <EmptyState title="Bir talep seçin" description="Soldaki listeden bir talep seçtiğinizde ayrıntı ve müşteri geçmişi burada görünür." />
            </Card>
          )}
        </div>
      </div>
    </>
  );
}
