"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useState } from "react";
import { Radar } from "lucide-react";
import { mutate as mutateGlobal } from "swr";
import { AiErrorNotice } from "@/components/ai/ai-unavailable";
import { IncidentDetailView } from "@/components/ai/incident-detail";
import { RunMeta } from "@/components/ai/run-meta";
import { AiSourceBadge, IncidentStatusBadge } from "@/components/badges";
import { useSession } from "@/components/session";
import { Button, Card, CardHeader, DemoDataNote, EmptyState, ErrorState, LoadingBlock, PageHeader, cn } from "@/components/ui";
import { api } from "@/lib/api";
import { formatUsd, timeAgo } from "@/lib/format";
import { useApi } from "@/lib/hooks";
import { AGENT_LABEL, SOURCE_LABEL } from "@/lib/labels";
import type { AgentRun, AgentRunList, IncidentDetail, IncidentSummary, PatternScanResult } from "@/lib/types";

export default function AiInsightsPage() {
  const { me } = useSession();
  const params = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const incidents = useApi<{ incidents: IncidentSummary[] }>("/incidents");
  const runs = useApi<AgentRunList>("/agent_runs");
  const selectedId = params.get("incident") ?? (incidents.data?.incidents[0] ? String(incidents.data.incidents[0].id) : null);
  const detail = useApi<{ incident: IncidentDetail }>(selectedId ? `/incidents/${selectedId}` : null);

  const [scanning, setScanning] = useState(false);
  const [scanError, setScanError] = useState<unknown>(null);
  const [scan, setScan] = useState<PatternScanResult | null>(null);

  const select = (id: number) => router.replace(`${pathname}?incident=${id}`, { scroll: false });

  async function runScan() {
    setScanning(true);
    setScanError(null);
    try {
      const res = await api<PatternScanResult>("/ai/pattern_scan", { method: "POST" });
      setScan(res);
      await Promise.all([incidents.mutate(), runs.mutate(), mutateGlobal("/dashboard")]);
      if (res.proposals[0]) select(res.proposals[0].incident.id);
    } catch (err) {
      setScanError(err);
      void runs.mutate();
    } finally {
      setScanning(false);
    }
  }

  function onIncident(incident: IncidentDetail) {
    void detail.mutate({ incident }, { revalidate: false });
    void incidents.mutate();
    void runs.mutate();
    void mutateGlobal("/dashboard");
  }

  return (
    <>
      <PageHeader
        title="AI Insights"
        description={
          <span className="flex flex-wrap items-center gap-2">
            Tekrarlayan şikayetlerden olası ortak sorunları bulur; her öneri insan onayı bekler. <DemoDataNote />
          </span>
        }
        actions={
          <Button variant="accent" loading={scanning} onClick={() => void runScan()}>
            <Radar className="size-4" aria-hidden /> Örüntü taraması çalıştır
          </Button>
        }
      />

      {scanError != null && (
        <div className="mb-4">
          <AiErrorNotice error={scanError} />
        </div>
      )}
      {scan && (
        <Card className="mb-4 p-4">
          <p className="text-sm text-slate-800">
            Son 30 günün <strong>{scan.candidates_scanned}</strong> ticket&apos;ı (açık ve yakın zamanda çözülen) tarandı, <strong>{scan.groups_found}</strong> benzerlik grubu bulundu.{" "}
            {scan.proposals.length === 0
              ? "Ortak sorun önerisi oluşmadı."
              : `${scan.proposals.filter((p) => p.created).length} yeni öneri, ${scan.proposals.filter((p) => !p.created).length} güncellenen öneri.`}
          </p>
          {scan.proposals.map((p) => (
            <div key={p.incident.id} className="mt-2 flex flex-wrap items-center gap-2 text-xs">
              <button type="button" className="font-medium text-accent-700 hover:underline" onClick={() => select(p.incident.id)}>
                {p.incident.code} · {p.incident.title}
              </button>
              <RunMeta run={p.run} />
            </div>
          ))}
        </Card>
      )}

      <div className="grid gap-4 xl:grid-cols-[320px_minmax(0,1fr)]">
        <Card className="h-fit">
          <CardHeader title="Olaylar" description="Önerilen olaylar hipotezdir." />
          {incidents.error && !incidents.data ? (
            <div className="p-4">
              <ErrorState message={incidents.error.message} onRetry={() => void incidents.mutate()} />
            </div>
          ) : !incidents.data ? (
            <LoadingBlock />
          ) : incidents.data.incidents.length === 0 ? (
            <EmptyState title="Henüz olay yok" description="“Örüntü taraması çalıştır” ile benzer şikayetleri gruplayın." />
          ) : (
            <ul className="divide-y divide-slate-100">
              {incidents.data.incidents.map((inc) => (
                <li key={inc.id}>
                  <button
                    type="button"
                    onClick={() => select(inc.id)}
                    aria-current={String(inc.id) === selectedId ? "true" : undefined}
                    className={cn("block w-full px-4 py-3 text-left", String(inc.id) === selectedId ? "bg-accent-50" : "hover:bg-slate-50")}
                  >
                    <span className="flex items-center justify-between gap-2">
                      <span className="text-xs text-slate-500">{inc.code}</span>
                      <IncidentStatusBadge status={inc.status} />
                    </span>
                    <span className="mt-1 block text-sm font-medium text-slate-900">{inc.title}</span>
                    <span className="text-xs text-slate-500">
                      {inc.ticket_count} ticket · {inc.affected_customers} müşteri · {timeAgo(inc.created_at)}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <div>
          {detail.data ? (
            <IncidentDetailView incident={detail.data.incident} isManager={me.role === "manager"} onIncident={onIncident} />
          ) : detail.error ? (
            <ErrorState message={detail.error.message} />
          ) : selectedId ? (
            <LoadingBlock label="Olay yükleniyor..." />
          ) : (
            <Card>
              <EmptyState title="Bir olay seçin" description="Tarama sonrası önerilen olaylar burada incelenir." />
            </Card>
          )}
        </div>
      </div>

      <Card className="mt-6">
        <CardHeader title="AI çalıştırma geçmişi" description="Her ajan çağrısı kaynak, model, token, süre ve tahmini maliyetle kaydedilir." />
        {runs.data && (
          <div className="flex flex-wrap gap-2 border-b border-slate-100 px-4 py-3 text-xs">
            {runs.data.totals.length === 0 && <span className="text-slate-500">Henüz çalıştırma yok.</span>}
            {runs.data.totals.map((t) => (
              <span key={t.source} className="rounded-md bg-slate-50 px-2.5 py-1.5 text-slate-700">
                <strong>{SOURCE_LABEL[t.source as AgentRun["source"]] ?? t.source}</strong>: {t.runs} çalıştırma · {t.tokens_in + t.tokens_out} token ·{" "}
                {formatUsd(t.cost_usd)}
                {t.source === "openai" && " (tahmini)"}
              </span>
            ))}
            {runs.data.failed > 0 && <span className="rounded-md bg-red-50 px-2.5 py-1.5 text-red-700">{runs.data.failed} başarısız</span>}
          </div>
        )}
        {runs.error && !runs.data ? (
          <div className="p-4">
            <ErrorState message={runs.error.message} />
          </div>
        ) : !runs.data ? (
          <LoadingBlock />
        ) : runs.data.runs.length === 0 ? (
          <EmptyState title="Kayıt yok" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-slate-500">
                <tr>
                  <th className="px-4 py-2 font-medium">Ajan</th>
                  <th className="px-4 py-2 font-medium">Kaynak</th>
                  <th className="px-4 py-2 font-medium">Konu</th>
                  <th className="px-4 py-2 font-medium">Kullanıcı</th>
                  <th className="px-4 py-2 text-right font-medium">Token</th>
                  <th className="px-4 py-2 text-right font-medium">Süre</th>
                  <th className="px-4 py-2 text-right font-medium">Maliyet</th>
                  <th className="px-4 py-2 font-medium">Zaman</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {runs.data.runs.map((r) => (
                  <tr key={r.id}>
                    <td className="px-4 py-2 text-slate-800">
                      {AGENT_LABEL[r.agent_type]}
                      {r.status === "failed" && <span className="ml-1 text-red-600" title={r.error_summary ?? undefined}>· başarısız</span>}
                    </td>
                    <td className="px-4 py-2">
                      <AiSourceBadge run={r} />
                    </td>
                    <td className="px-4 py-2 text-slate-600">{r.subject_type ? `${r.subject_type} #${r.subject_id}` : "—"}</td>
                    <td className="px-4 py-2 text-slate-600">{r.user_name ?? "—"}</td>
                    <td className="px-4 py-2 text-right text-slate-700">{r.tokens_in + r.tokens_out}</td>
                    <td className="px-4 py-2 text-right text-slate-700">{r.latency_ms != null ? `${(r.latency_ms / 1000).toFixed(1)} sn` : "—"}</td>
                    <td className="px-4 py-2 text-right text-slate-700">{r.source === "openai" ? formatUsd(r.cost_usd) : "—"}</td>
                    <td className="px-4 py-2 text-slate-500">{timeAgo(r.created_at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </>
  );
}
