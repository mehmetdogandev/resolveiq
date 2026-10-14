"use client";

import Link from "next/link";
import { Building2, MapPin } from "lucide-react";
import { formatDate, timeAgo } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import type { CustomerDetail, TicketSummary } from "@/lib/types";
import { ChannelIcon, StatusBadge } from "./badges";
import { Badge, ErrorState, Spinner } from "./ui";

export function CustomerHistory({ customerId, highlightId, limit }: { customerId: number; highlightId?: number; limit?: number }) {
  const { data, error } = useApi<{ customer: CustomerDetail; tickets: TicketSummary[] }>(`/customers/${customerId}`);
  if (error) return <ErrorState message={error.message} />;
  if (!data) return <Spinner label="Müşteri geçmişi yükleniyor..." />;

  const { customer, tickets } = data;
  const shown = limit ? tickets.slice(0, limit) : tickets;
  return (
    <div className="space-y-3">
      <div>
        <p className="text-sm font-semibold text-slate-900">{customer.name}</p>
        <p className="text-xs text-slate-500">{customer.email}</p>
        <div className="mt-1.5 flex flex-wrap gap-x-3 gap-y-1 text-xs text-slate-600">
          {customer.company && (
            <span className="flex items-center gap-1">
              <Building2 className="size-3.5" aria-hidden /> {customer.company}
            </span>
          )}
          {customer.city && (
            <span className="flex items-center gap-1">
              <MapPin className="size-3.5" aria-hidden /> {customer.city}
            </span>
          )}
          <Badge tone={customer.tier === "enterprise" ? "violet" : customer.tier === "pro" ? "teal" : "slate"}>{customer.tier}</Badge>
        </div>
      </div>
      <div className="grid grid-cols-3 gap-2 text-center">
        {[
          ["Toplam", customer.stats.total],
          ["Açık", customer.stats.open],
          ["Çözülen", customer.stats.resolved],
        ].map(([label, value]) => (
          <div key={label} className="rounded-lg bg-slate-50 px-2 py-2">
            <p className="text-lg font-semibold text-slate-900">{value}</p>
            <p className="text-[11px] text-slate-500">{label}</p>
          </div>
        ))}
      </div>
      {customer.products.length > 0 && (
        <p className="text-xs text-slate-600">Ürünler: {customer.products.map((p) => p.name).join(", ")}</p>
      )}
      <p className="text-[11px] text-slate-400">Müşteri kaydı: {formatDate(customer.since)}</p>
      <ul className="divide-y divide-slate-100 rounded-lg border border-slate-200">
        {shown.map((t) => (
          <li key={t.id}>
            <Link
              href={`/tickets/${t.id}`}
              className={`flex items-center justify-between gap-2 px-3 py-2 text-xs hover:bg-slate-50 ${t.id === highlightId ? "bg-accent-50" : ""}`}
            >
              <span className="flex min-w-0 items-center gap-1.5">
                <ChannelIcon channel={t.channel} />
                <span className="text-slate-500">{t.number}</span>
                <span className="truncate text-slate-800">{t.subject}</span>
              </span>
              <span className="flex shrink-0 items-center gap-2">
                <span className="text-slate-400">{timeAgo(t.created_at)}</span>
                <StatusBadge status={t.status} />
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
