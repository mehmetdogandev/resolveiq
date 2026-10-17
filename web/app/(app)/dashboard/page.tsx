"use client";

import Link from "next/link";
import { AlertTriangle, ArrowRight, BookPlus, CheckCircle2, Inbox, Layers, Sparkles, UserX, Wand2 } from "lucide-react";
import type { ReactNode } from "react";
import { IncidentStatusBadge } from "@/components/badges";
import { RunMeta } from "@/components/ai/run-meta";
import { useSession } from "@/components/session";
import { Card, CardHeader, DemoDataNote, EmptyState, ErrorState, LoadingBlock, PageHeader } from "@/components/ui";
import { formatDateTime, formatUsd, timeAgo } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import { AGENT_LABEL, CHANNEL_LABEL, PRIORITY_LABEL, STATUS_LABEL, actionLabel } from "@/lib/labels";
import type { Channel, Dashboard, PendingAction, Priority, TicketStatus } from "@/lib/types";

const PENDING_ICON: Record<PendingAction["kind"], ReactNode> = {
  triage_ready: <Wand2 className="size-4 text-accent-600" aria-hidden />,
  incident_proposed: <Layers className="size-4 text-violet-600" aria-hidden />,
  resolution_ready: <CheckCircle2 className="size-4 text-emerald-600" aria-hidden />,
  kb_draft: <BookPlus className="size-4 text-amber-600" aria-hidden />,
};

function Stat({ label, value, icon, href, tone = "text-slate-900" }: { label: string; value: number | string; icon: ReactNode; href?: string; tone?: string }) {
  const body = (
    <Card className="flex items-center gap-3 p-4 transition hover:border-slate-300">
      <div className="flex size-9 items-center justify-center rounded-lg bg-slate-100">{icon}</div>
      <div>
        <p className={`text-2xl font-semibold leading-none ${tone}`}>{value}</p>
        <p className="mt-1 text-xs text-slate-500">{label}</p>
      </div>
    </Card>
  );
  return href ? <Link href={href}>{body}</Link> : body;
}

function Bars<K extends string>({ data, labels, color, hrefFor }: { data: Record<K, number>; labels: Record<K, string>; color: string; hrefFor: (k: K) => string }) {
  const entries = Object.entries(data) as [K, number][];
  const max = Math.max(1, ...entries.map(([, v]) => v));
  return (
    <ul className="space-y-2.5 p-4">
      {entries.map(([key, value]) => (
        <li key={key}>
          <Link href={hrefFor(key)} className="group block">
            <div className="flex justify-between text-xs">
              <span className="text-slate-600 group-hover:text-slate-900">{labels[key]}</span>
              <span className="font-medium text-slate-900">{value}</span>
            </div>
            <div className="mt-1 h-2 overflow-hidden rounded-full bg-slate-100">
              <div className={`h-full rounded-full ${color}`} style={{ width: `${(value / max) * 100}%` }} />
            </div>
          </Link>
        </li>
      ))}
    </ul>
  );
}

export default function DashboardPage() {
  const { me } = useSession();
  const { data, error, mutate } = useApi<Dashboard>("/dashboard", { refreshInterval: 30000 });

  if (error && !data) return <ErrorState message={error.message} onRetry={() => void mutate()} />;
  if (!data) return <LoadingBlock label="Panel hesaplanıyor..." />;

  return (
    <>
      <PageHeader
        title={`Merhaba, ${me.name.split(" ")[0]}`}
        description={
          <span className="flex flex-wrap items-center gap-2">
            Tüm değerler veritabanından anlık hesaplanır · {formatDateTime(data.generated_at)} {data.synthetic_data && <DemoDataNote />}
          </span>
        }
      />

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-7">
        <Stat label="Açık talep" value={data.totals.open} icon={<Inbox className="size-4 text-slate-600" />} href="/tickets?open_only=true" />
        <Stat label="Acil / yüksek öncelik" value={data.totals.urgent_high} icon={<AlertTriangle className="size-4 text-red-600" />} href="/tickets?open_only=true&priority=urgent,high" tone="text-red-700" />
        <Stat label="Atanmamış" value={data.totals.unassigned} icon={<UserX className="size-4 text-amber-600" />} href="/tickets?open_only=true&assignee_id=none" />
        <Stat label="Son 7 günde çözülen" value={data.totals.resolved_last_7d} icon={<CheckCircle2 className="size-4 text-emerald-600" />} href="/tickets?status=resolved" />
        <Stat label="Bana atanan açık" value={data.totals.mine_open} icon={<Sparkles className="size-4 text-accent-600" />} href={`/tickets?open_only=true&assignee_id=${me.id}`} />
        <Stat label="Açık SLA ihlali" value={data.totals.sla_breached} icon={<AlertTriangle className="size-4 text-red-600" />} href="/tickets?open_only=true&sla=breached" tone="text-red-700" />
        <Stat label="CSAT ortalaması" value={data.totals.csat_average ?? "—"} icon={<CheckCircle2 className="size-4 text-emerald-600" />} href="/reports" />
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2" >
          <div id="pending" className="scroll-mt-20">
            <CardHeader title="Onay bekleyen AI işleri" description="AI hazırladı; uygulamak için insan kararı gerekiyor. Hiçbir müşteri iletişimi otomatik gönderilmez." />
          </div>
          {data.pending_actions.length === 0 ? (
            <EmptyState title="Bekleyen iş yok" description="Bir ticket'ta AI triage çalıştırın veya AI Insights'ta örüntü taraması başlatın." />
          ) : (
            <ul className="divide-y divide-slate-100">
              {data.pending_actions.map((a) => (
                <li key={`${a.kind}-${a.href}`}>
                  <Link href={a.href} className="flex items-center gap-3 px-4 py-3 hover:bg-slate-50">
                    {PENDING_ICON[a.kind]}
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-slate-900">{a.title}</p>
                      <p className="truncate text-xs text-slate-500">{a.detail}</p>
                    </div>
                    <span className="hidden text-[11px] text-slate-400 sm:inline">{timeAgo(a.created_at)}</span>
                    <ArrowRight className="size-4 text-slate-400" aria-hidden />
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card>
          <CardHeader
            title="Olası ortak sorunlar"
            description={`${data.incidents.proposed} önerildi · ${data.incidents.confirmed} onaylı · ${data.incidents.resolved} çözüldü`}
            action={
              <Link href="/ai-insights" className="text-xs font-medium text-accent-700 hover:underline">
                AI Insights
              </Link>
            }
          />
          {data.incidents.recent.length === 0 ? (
            <EmptyState title="Henüz olay yok" description="AI Insights ekranından örüntü taraması çalıştırın." />
          ) : (
            <ul className="divide-y divide-slate-100">
              {data.incidents.recent.map((inc) => (
                <li key={inc.id}>
                  <Link href={`/ai-insights?incident=${inc.id}`} className="block px-4 py-3 hover:bg-slate-50">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs text-slate-500">{inc.code}</span>
                      <IncidentStatusBadge status={inc.status} />
                    </div>
                    <p className="mt-1 text-sm font-medium text-slate-900">{inc.title}</p>
                    <p className="text-xs text-slate-500">
                      {inc.ticket_count} ticket · {inc.affected_customers} müşteri
                    </p>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-3">
        <Card>
          <CardHeader title="Duruma göre (tümü)" />
          <Bars<TicketStatus> data={data.by_status} labels={STATUS_LABEL} color="bg-navy-700" hrefFor={(k) => `/tickets?status=${k}`} />
        </Card>
        <Card>
          <CardHeader title="Kanala göre (açık)" />
          <Bars<Channel> data={data.by_channel} labels={CHANNEL_LABEL} color="bg-accent-500" hrefFor={(k) => `/inbox?channel=${k}`} />
        </Card>
        <Card>
          <CardHeader title="Önceliğe göre (açık)" />
          <Bars<Priority> data={data.by_priority} labels={PRIORITY_LABEL} color="bg-amber-500" hrefFor={(k) => `/tickets?open_only=true&priority=${k}`} />
        </Card>
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader title="Son AI çalıştırmaları" description={`Toplam tahmini ürün AI maliyeti: ${formatUsd(data.ai_cost_usd)}`} />
          {data.agent_runs.length === 0 ? (
            <EmptyState title="Henüz AI çalıştırması yok" />
          ) : (
            <ul className="divide-y divide-slate-100">
              {data.agent_runs.map((run) => (
                <li key={run.id} className="px-4 py-2.5">
                  <p className="text-sm text-slate-800">
                    {AGENT_LABEL[run.agent_type]} {run.status === "failed" && <span className="text-xs text-red-600">· başarısız</span>}
                    {run.user_name && <span className="text-xs text-slate-500"> · {run.user_name}</span>}
                  </p>
                  <RunMeta run={run} />
                </li>
              ))}
            </ul>
          )}
        </Card>
        <Card>
          <CardHeader title="Son etkinlikler" />
          {data.recent_activity.length === 0 ? (
            <EmptyState title="Etkinlik yok" />
          ) : (
            <ul className="divide-y divide-slate-100">
              {data.recent_activity.map((e) => (
                <li key={e.id} className="flex items-center justify-between gap-3 px-4 py-2.5 text-xs">
                  <span className="text-slate-700">
                    <strong className="font-medium text-slate-900">{e.actor_name}</strong> {actionLabel(e.action)}
                    {e.target_type === "Ticket" && e.target_id && (
                      <Link href={`/tickets/${e.target_id}`} className="ml-1 text-accent-700 hover:underline">
                        görüntüle
                      </Link>
                    )}
                  </span>
                  <span className="shrink-0 text-slate-400">{timeAgo(e.created_at)}</span>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>
    </>
  );
}
