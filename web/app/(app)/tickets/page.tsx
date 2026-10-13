"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { ChevronLeft, ChevronRight, Plus } from "lucide-react";
import { ChannelIcon, PriorityBadge, StatusBadge } from "@/components/badges";
import { ChannelTabs, TicketFilterBar, useTicketQuery } from "@/components/tickets/ticket-filters";
import { Button, Card, DemoDataNote, EmptyState, ErrorState, LoadingBlock, PageHeader, Select } from "@/components/ui";
import { timeAgo } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import type { TicketList } from "@/lib/types";

export default function TicketsPage() {
  const router = useRouter();
  const { values, apiQuery, setParams } = useTicketQuery({ sort: "newest" });
  const { data, error, isLoading, mutate } = useApi<TicketList>(`/tickets?${apiQuery}`, { keepPreviousData: true });
  const page = Number(values.page ?? 1);

  return (
    <>
      <PageHeader
        title="Ticket'lar"
        description={<span className="flex items-center gap-2">Tüm destek talepleri, sunucu tarafında filtrelenir. <DemoDataNote /></span>}
        actions={
          <Link href="/tickets/new">
            <Button variant="accent">
              <Plus className="size-4" aria-hidden /> Yeni ticket
            </Button>
          </Link>
        }
      />

      <div className="mb-3 flex flex-wrap items-center justify-between gap-3">
        <ChannelTabs value={values.channel ?? ""} counts={data?.meta.channel_counts} onChange={(c) => setParams({ channel: c })} />
        <div className="w-44">
          <label htmlFor="sort" className="sr-only">
            Sıralama
          </label>
          <Select id="sort" value={values.sort ?? "newest"} onChange={(e) => setParams({ sort: e.target.value })} className="h-8 text-xs">
            <option value="newest">En yeni</option>
            <option value="oldest">En eski</option>
            <option value="updated">Son güncellenen</option>
            <option value="priority">Önceliğe göre</option>
          </Select>
        </div>
      </div>
      <div className="mb-4">
        <TicketFilterBar values={values} setParams={setParams} />
      </div>

      <Card className="overflow-hidden">
        {error && !data ? (
          <div className="p-4">
            <ErrorState message={error.message} onRetry={() => void mutate()} />
          </div>
        ) : isLoading && !data ? (
          <LoadingBlock label="Ticket'lar yükleniyor..." />
        ) : data && data.tickets.length === 0 ? (
          <EmptyState title="Filtreye uyan ticket yok" description="Filtreleri temizleyin veya yeni bir ticket oluşturun." />
        ) : (
          data && (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="border-b border-slate-200 bg-slate-50 text-left text-xs font-medium text-slate-500">
                  <tr>
                    <th className="px-4 py-2.5">Ticket</th>
                    <th className="px-3 py-2.5">Müşteri</th>
                    <th className="px-3 py-2.5">Durum</th>
                    <th className="px-3 py-2.5">Öncelik</th>
                    <th className="hidden px-3 py-2.5 xl:table-cell">Ürün</th>
                    <th className="px-3 py-2.5">Sorumlu</th>
                    <th className="px-3 py-2.5 text-right">Oluşturma</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {data.tickets.map((t) => (
                    <tr
                      key={t.id}
                      className="cursor-pointer hover:bg-slate-50"
                      onClick={() => router.push(`/tickets/${t.id}`)}
                    >
                      <td className="max-w-md px-4 py-3">
                        <Link href={`/tickets/${t.id}`} className="group block" onClick={(e) => e.stopPropagation()}>
                          <span className="flex items-center gap-1.5 text-xs text-slate-500">
                            <ChannelIcon channel={t.channel} /> {t.number}
                          </span>
                          <span className="mt-0.5 block truncate font-medium text-slate-900 group-hover:text-accent-700">{t.subject}</span>
                        </Link>
                      </td>
                      <td className="px-3 py-3">
                        <span className="block text-slate-800">{t.customer.name}</span>
                        {t.customer.company && <span className="block text-xs text-slate-500">{t.customer.company}</span>}
                      </td>
                      <td className="px-3 py-3"><StatusBadge status={t.status} /></td>
                      <td className="px-3 py-3"><PriorityBadge priority={t.priority} /></td>
                      <td className="hidden px-3 py-3 text-xs text-slate-600 xl:table-cell">{t.product_name ?? "—"}</td>
                      <td className="px-3 py-3 text-xs text-slate-700">{t.assignee?.name ?? <span className="text-slate-400">Atanmamış</span>}</td>
                      <td className="whitespace-nowrap px-3 py-3 text-right text-xs text-slate-500">{timeAgo(t.created_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )
        )}
        {data && data.meta.total_pages > 1 && (
          <div className="flex items-center justify-between border-t border-slate-100 px-4 py-2.5 text-xs text-slate-500">
            <span>
              {data.meta.total} ticket · sayfa {page}/{data.meta.total_pages}
            </span>
            <div className="flex gap-1">
              <Button variant="secondary" size="sm" disabled={page <= 1} onClick={() => setParams({ page: String(page - 1) })} aria-label="Önceki sayfa">
                <ChevronLeft className="size-4" />
              </Button>
              <Button variant="secondary" size="sm" disabled={page >= data.meta.total_pages} onClick={() => setParams({ page: String(page + 1) })} aria-label="Sonraki sayfa">
                <ChevronRight className="size-4" />
              </Button>
            </div>
          </div>
        )}
      </Card>
    </>
  );
}
