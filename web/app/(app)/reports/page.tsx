"use client";

import { AlertTriangle, Clock3, Smile } from "lucide-react";
import { Card, CardHeader, DemoDataNote, ErrorState, LoadingBlock, PageHeader } from "@/components/ui";
import { formatDateTime, formatMinutes, percent } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import { CHANNEL_LABEL, PRIORITY_LABEL } from "@/lib/labels";
import type { Channel, Priority, Reports } from "@/lib/types";

export default function ReportsPage() {
  const { data, error, mutate } = useApi<Reports>("/reports", { refreshInterval: 60000 });

  if (error && !data) return <ErrorState message={error.message} onRetry={() => void mutate()} />;
  if (!data) return <LoadingBlock label="Raporlar hesaplanıyor..." />;

  return (
    <>
      <PageHeader
        title="Raporlar"
        description={
          <span className="flex flex-wrap items-center gap-2">
            İlk yanıt, çözüm süresi, SLA ve CSAT veritabanından anlık hesaplanır · {formatDateTime(data.generated_at)} <DemoDataNote />
          </span>
        }
      />

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Card className="p-4">
          <p className="text-xs text-slate-500">Ortalama ilk yanıt</p>
          <p className="mt-1 flex items-center gap-2 text-2xl font-semibold text-slate-900">
            <Clock3 className="size-5 text-slate-400" aria-hidden />
            {formatMinutes(data.first_reply.average_minutes)}
          </p>
          <p className="mt-1 text-[11px] text-slate-500">{data.first_reply.count} ticket</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs text-slate-500">Ortalama çözüm</p>
          <p className="mt-1 text-2xl font-semibold text-slate-900">{formatMinutes(data.resolution.average_minutes)}</p>
          <p className="mt-1 text-[11px] text-slate-500">{data.resolution.count} çözülen</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs text-slate-500">SLA karşılama</p>
          <p className="mt-1 flex items-center gap-2 text-2xl font-semibold text-slate-900">
            <AlertTriangle className="size-5 text-amber-500" aria-hidden />
            {percent(data.sla.met_rate)}
          </p>
          <p className="mt-1 text-[11px] text-slate-500">
            {data.sla.met} uygun · {data.sla.breached} ihlal · {data.totals.breached_open} açık ihlal
          </p>
        </Card>
        <Card className="p-4">
          <p className="text-xs text-slate-500">CSAT ortalaması</p>
          <p className="mt-1 flex items-center gap-2 text-2xl font-semibold text-slate-900">
            <Smile className="size-5 text-emerald-500" aria-hidden />
            {data.csat.average ?? "—"}
          </p>
          <p className="mt-1 text-[11px] text-slate-500">{data.csat.count} anket</p>
        </Card>
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader title="Kanal kırılımı" />
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-xs uppercase tracking-wide text-slate-400">
                <tr>
                  <th className="px-4 py-2">Kanal</th>
                  <th className="px-4 py-2">Açık</th>
                  <th className="px-4 py-2">İlk yanıt</th>
                  <th className="px-4 py-2">Çözüm</th>
                </tr>
              </thead>
              <tbody>
                {(Object.keys(CHANNEL_LABEL) as Channel[]).map((channel) => {
                  const row = data.by_channel[channel];
                  return (
                    <tr key={channel} className="border-t border-slate-100">
                      <td className="px-4 py-2">{CHANNEL_LABEL[channel]}</td>
                      <td className="px-4 py-2">{row?.open ?? 0}/{row?.tickets ?? 0}</td>
                      <td className="px-4 py-2">{formatMinutes(row?.avg_first_reply_minutes)}</td>
                      <td className="px-4 py-2">{formatMinutes(row?.avg_resolution_minutes)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
        <Card>
          <CardHeader title="Temsilci performansı" />
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-xs uppercase tracking-wide text-slate-400">
                <tr>
                  <th className="px-4 py-2">Temsilci</th>
                  <th className="px-4 py-2">Açık</th>
                  <th className="px-4 py-2">Çözülen</th>
                  <th className="px-4 py-2">CSAT</th>
                </tr>
              </thead>
              <tbody>
                {data.by_agent.map((row) => (
                  <tr key={row.user.id} className="border-t border-slate-100">
                    <td className="px-4 py-2">{row.user.name}</td>
                    <td className="px-4 py-2">{row.open}</td>
                    <td className="px-4 py-2">{row.resolved}</td>
                    <td className="px-4 py-2">{row.csat_average ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </div>

      <Card className="mt-4">
        <CardHeader title="Açık talepler, önceliğe göre" />
        <ul className="grid gap-2 p-4 sm:grid-cols-4">
          {(Object.keys(PRIORITY_LABEL) as Priority[]).map((priority) => (
            <li key={priority} className="rounded-lg bg-slate-50 px-3 py-2 text-sm">
              <p className="text-xs text-slate-500">{PRIORITY_LABEL[priority]}</p>
              <p className="font-semibold text-slate-900">{data.by_priority[priority] ?? 0}</p>
            </li>
          ))}
        </ul>
      </Card>
    </>
  );
}
