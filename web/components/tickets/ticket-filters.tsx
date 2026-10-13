"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import { Search, X } from "lucide-react";
import { CHANNEL_LABEL, PRIORITY_LABEL, STATUS_LABEL } from "@/lib/labels";
import type { Channel, Priority, TicketStatus } from "@/lib/types";
import { ChannelIcon } from "../badges";
import { useSession } from "../session";
import { Button, Select, cn } from "../ui";

export const FILTER_KEYS = ["q", "channel", "status", "priority", "assignee_id", "category", "product", "open_only", "sort", "page"] as const;

export function useTicketQuery(defaults: Record<string, string> = {}) {
  const params = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  const values: Record<string, string> = { ...defaults };
  FILTER_KEYS.forEach((key) => {
    const v = params.get(key);
    if (v !== null) values[key] = v;
  });

  const apiQuery = new URLSearchParams(Object.entries(values).filter(([, v]) => v !== "")).toString();

  function setParams(next: Record<string, string | null>, resetPage = true) {
    const sp = new URLSearchParams(params.toString());
    Object.entries(next).forEach(([key, value]) => {
      if (value === null) sp.delete(key);
      else sp.set(key, value);
    });
    if (resetPage && !("page" in next)) sp.delete("page");
    const qs = sp.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
  }

  return { values, apiQuery, setParams, rawParams: params };
}

export function ChannelTabs({
  value,
  counts,
  onChange,
}: {
  value: string;
  counts?: Partial<Record<Channel, number>>;
  onChange: (channel: string | null) => void;
}) {
  const total = counts ? Object.values(counts).reduce((a, b) => a + (b ?? 0), 0) : undefined;
  const tabs: { key: string; label: string; count?: number; channel?: Channel }[] = [
    { key: "", label: "Tüm kanallar", count: total },
    ...(Object.keys(CHANNEL_LABEL) as Channel[]).map((c) => ({ key: c, label: CHANNEL_LABEL[c], count: counts?.[c] ?? 0, channel: c })),
  ];
  return (
    <div className="flex flex-wrap gap-1 rounded-lg bg-slate-100 p-1" role="tablist" aria-label="Kanal">
      {tabs.map((tab) => {
        const active = (value || "") === tab.key;
        return (
          <button
            key={tab.key || "all"}
            type="button"
            role="tab"
            aria-selected={active}
            onClick={() => onChange(tab.key || null)}
            className={cn(
              "flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent-500",
              active ? "bg-white text-slate-900 shadow-sm" : "text-slate-600 hover:text-slate-900",
            )}
          >
            {tab.channel && <ChannelIcon channel={tab.channel} />}
            {tab.label}
            {tab.count !== undefined && <span className="rounded bg-slate-200/70 px-1.5 text-[10px] text-slate-600">{tab.count}</span>}
          </button>
        );
      })}
    </div>
  );
}

export function TicketFilterBar({
  values,
  setParams,
  compact = false,
}: {
  values: Record<string, string>;
  setParams: (next: Record<string, string | null>) => void;
  compact?: boolean;
}) {
  const { meta } = useSession();
  const [q, setQ] = useState(values.q ?? "");
  const [urlQ, setUrlQ] = useState(values.q ?? "");
  if (urlQ !== (values.q ?? "")) {
    setUrlQ(values.q ?? "");
    setQ(values.q ?? "");
  }

  useEffect(() => {
    const handle = setTimeout(() => {
      if ((values.q ?? "") !== q) setParams({ q: q || null });
    }, 350);
    return () => clearTimeout(handle);
  }, [q, values.q, setParams]);

  const active = ["q", "status", "priority", "assignee_id", "category", "product"].some((k) => values[k]);
  const select = (key: string, label: string, options: { value: string; label: string }[]) => (
    <div className={compact ? "min-w-[8rem] flex-1" : "w-40"}>
      <label htmlFor={`f-${key}`} className="sr-only">
        {label}
      </label>
      <Select id={`f-${key}`} value={values[key] ?? ""} onChange={(e) => setParams({ [key]: e.target.value || null })} className="h-8 text-xs">
        <option value="">{label}: tümü</option>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </Select>
    </div>
  );

  return (
    <div className="flex flex-wrap items-center gap-2">
      <div className={cn("relative", compact ? "w-full" : "w-64")}>
        <Search className="pointer-events-none absolute left-2.5 top-1/2 size-3.5 -translate-y-1/2 text-slate-400" aria-hidden />
        <label htmlFor="f-q" className="sr-only">
          Ara
        </label>
        <input
          id="f-q"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="No, konu, müşteri, ürün..."
          className="h-8 w-full rounded-md border border-slate-300 bg-white pl-8 pr-2 text-xs focus:border-accent-500 focus:outline-none focus:ring-2 focus:ring-accent-100"
        />
      </div>
      {select("status", "Durum", (Object.keys(STATUS_LABEL) as TicketStatus[]).map((s) => ({ value: s, label: STATUS_LABEL[s] })))}
      {select("priority", "Öncelik", (Object.keys(PRIORITY_LABEL) as Priority[]).map((p) => ({ value: p, label: PRIORITY_LABEL[p] })))}
      {select("assignee_id", "Sorumlu", [
        { value: "none", label: "Atanmamış" },
        ...meta.users.map((u) => ({ value: String(u.id), label: u.name })),
      ])}
      {select("category", "Kategori", meta.categories.map((c) => ({ value: c.code, label: c.name })))}
      {!compact && select("product", "Ürün", meta.products.map((p) => ({ value: p.code, label: p.name })))}
      {active && (
        <Button
          variant="ghost"
          size="sm"
          onClick={() => {
            setQ("");
            setParams({ q: null, status: null, priority: null, assignee_id: null, category: null, product: null });
          }}
        >
          <X className="size-3.5" aria-hidden /> Temizle
        </Button>
      )}
    </div>
  );
}
