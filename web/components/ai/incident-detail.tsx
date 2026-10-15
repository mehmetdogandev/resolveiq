"use client";

import Link from "next/link";
import { useState, type FormEvent } from "react";
import { AlertTriangle, Check, Link2, Unlink, X } from "lucide-react";
import { api, errorMessage } from "@/lib/api";
import { formatDateTime, percent } from "@/lib/format";
import { SEVERITY_LABEL } from "@/lib/labels";
import type { IncidentDetail, TicketList } from "@/lib/types";
import { IncidentStatusBadge, StatusBadge } from "../badges";
import { Badge, Button, Card, CardHeader, ErrorState, Input, Textarea } from "../ui";
import { IncidentResolution } from "./incident-resolution";
import { RunMeta } from "./run-meta";

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="mb-1 text-xs font-medium uppercase tracking-wide text-slate-500">{title}</p>
      {children}
    </div>
  );
}

export function IncidentDetailView({
  incident,
  isManager,
  onIncident,
}: {
  incident: IncidentDetail;
  isManager: boolean;
  onIncident: (i: IncidentDetail) => void;
}) {
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [resolveNote, setResolveNote] = useState("");
  const [showResolve, setShowResolve] = useState(false);
  const [linkNumber, setLinkNumber] = useState("");
  const active = incident.status === "proposed" || incident.status === "confirmed";
  const customers = Array.from(new Map(incident.tickets.map((t) => [t.customer.id, t.customer])).values());

  async function run(key: string, fn: () => Promise<{ incident: IncidentDetail }>) {
    setBusy(key);
    setError(null);
    try {
      const res = await fn();
      onIncident(res.incident);
      return true;
    } catch (err) {
      setError(errorMessage(err));
      return false;
    } finally {
      setBusy(null);
    }
  }

  const action = (path: string, body?: unknown) => () => api<{ incident: IncidentDetail }>(`/incidents/${incident.id}/${path}`, { method: "POST", body });

  async function linkTicket(event: FormEvent) {
    event.preventDefault();
    const number = linkNumber.trim().toUpperCase();
    if (!number) return;
    const ok = await run("link", async () => {
      const list = await api<TicketList>(`/tickets?q=${encodeURIComponent(number)}`);
      const match = list.tickets.find((t) => t.number === number);
      if (!match) throw new Error(`${number} numaralı ticket bulunamadı`);
      return api<{ incident: IncidentDetail }>(`/incidents/${incident.id}/tickets`, { method: "POST", body: { ticket_id: match.id } });
    });
    if (ok) setLinkNumber("");
  }

  return (
    <div className="space-y-4">
      <Card>
        <div className="border-b border-slate-100 p-4">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-1.5">
                <span className="text-xs text-slate-500">{incident.code}</span>
                <IncidentStatusBadge status={incident.status} />
                <Badge tone={incident.severity === "critical" || incident.severity === "high" ? "red" : "slate"}>Etki: {SEVERITY_LABEL[incident.severity]}</Badge>
                {incident.confidence != null && <Badge tone="violet">Güven: {percent(incident.confidence)}</Badge>}
              </div>
              <h2 className="mt-1.5 text-lg font-semibold text-slate-900">{incident.title}</h2>
              <p className="mt-0.5 text-xs text-slate-500">
                {incident.product_name ?? "Ürün belirsiz"} · {incident.ticket_count} ticket · {incident.affected_customers} müşteri · tespit {formatDateTime(incident.created_at)}
              </p>
            </div>
            {isManager && active && (
              <div className="flex flex-wrap gap-2">
                {incident.status === "proposed" && (
                  <>
                    <Button variant="secondary" size="sm" loading={busy === "dismiss"} onClick={() => void run("dismiss", action("dismiss"))}>
                      <X className="size-3.5" aria-hidden /> Reddet
                    </Button>
                    <Button variant="accent" size="sm" loading={busy === "confirm"} onClick={() => void run("confirm", action("confirm"))}>
                      <Check className="size-3.5" aria-hidden /> Ortak sorun olarak onayla
                    </Button>
                  </>
                )}
                {incident.status === "confirmed" && (
                  <Button variant="secondary" size="sm" onClick={() => setShowResolve((v) => !v)}>
                    Olayı çözüldü olarak kapat
                  </Button>
                )}
              </div>
            )}
          </div>
          {incident.status === "proposed" && (
            <p className="mt-3 flex items-start gap-2 rounded-md bg-violet-50 px-3 py-2 text-xs text-violet-900">
              <AlertTriangle className="mt-0.5 size-3.5 shrink-0" aria-hidden />
              Bu bir hipotezdir: ticket&apos;lar arasındaki benzerlik ortak bir nedenin kanıtı değildir. Bir yönetici kanıtı inceleyip onaylayana kadar olay
              doğrulanmış sayılmaz.
            </p>
          )}
          {incident.status === "confirmed" && incident.confirmed_by && (
            <p className="mt-3 text-xs text-slate-600">
              {incident.confirmed_by.name} tarafından {incident.confirmed_at ? formatDateTime(incident.confirmed_at) : ""} onaylandı. Kök neden yine de
              doğrulanmamış bir varsayımdır.
            </p>
          )}
          {incident.resolution_note && <p className="mt-3 text-xs text-slate-600">Kapanış notu: {incident.resolution_note}</p>}
          {showResolve && (
            <form
              className="mt-3 space-y-2"
              onSubmit={(e) => {
                e.preventDefault();
                void run("resolve", action("resolve", { note: resolveNote })).then((ok) => ok && setShowResolve(false));
              }}
            >
              <label htmlFor="resolve-note" className="text-xs font-medium text-slate-700">
                Kapanış notu
              </label>
              <Textarea id="resolve-note" rows={2} value={resolveNote} onChange={(e) => setResolveNote(e.target.value)} />
              <Button type="submit" size="sm" variant="accent" loading={busy === "resolve"}>
                Kapat
              </Button>
            </form>
          )}
          {error && (
            <div className="mt-3">
              <ErrorState message={error} />
            </div>
          )}
        </div>

        <div className="grid gap-4 p-4 md:grid-cols-2">
          <div className="space-y-4">
            <Section title="Özet">
              <p className="text-sm leading-relaxed text-slate-700">{incident.summary}</p>
            </Section>
            {incident.symptoms.length > 0 && (
              <Section title="Ortak belirtiler">
                <ul className="list-disc space-y-0.5 pl-4 text-sm text-slate-700">
                  {incident.symptoms.map((s) => (
                    <li key={s}>{s}</li>
                  ))}
                </ul>
              </Section>
            )}
            {incident.suspected_root_cause && (
              <Section title="Olası kök neden (doğrulanmadı)">
                <p className="text-sm text-slate-700">{incident.suspected_root_cause}</p>
              </Section>
            )}
            {incident.uncertainty && (
              <Section title="Belirsizlik ve eksik bilgi">
                <p className="text-sm text-slate-700">{incident.uncertainty}</p>
              </Section>
            )}
          </div>
          <div className="space-y-4">
            {incident.evidence.length > 0 && (
              <Section title="Kanıt">
                <ul className="space-y-1.5">
                  {incident.evidence.map((e, i) => (
                    <li key={`${e.ticket_number}-${i}`} className="rounded-md bg-slate-50 px-2.5 py-1.5 text-xs text-slate-700">
                      <strong className="text-slate-900">{e.ticket_number}</strong> · {e.observation}
                    </li>
                  ))}
                </ul>
              </Section>
            )}
            {incident.suggested_actions.length > 0 && (
              <Section title="Önerilen aksiyonlar">
                <ul className="list-disc space-y-0.5 pl-4 text-sm text-slate-700">
                  {incident.suggested_actions.map((s) => (
                    <li key={s}>{s}</li>
                  ))}
                </ul>
              </Section>
            )}
            {incident.recommended_next_action && (
              <Section title="Önerilen sonraki adım">
                <p className="text-sm font-medium text-slate-800">{incident.recommended_next_action}</p>
              </Section>
            )}
            <Section title="Etkilenen müşteriler">
              <p className="text-xs text-slate-700">{customers.map((c) => c.name).join(", ") || "—"}</p>
            </Section>
          </div>
        </div>
        {incident.detected_by_run && (
          <div className="border-t border-slate-100 px-4 py-2.5">
            <RunMeta run={incident.detected_by_run} />
          </div>
        )}
      </Card>

      <Card>
        <CardHeader title={`Bağlı ticket'lar (${incident.tickets.length})`} description="Benzerlik skoru TF-IDF metin benzerliğidir; nedensellik göstermez." />
        <ul className="divide-y divide-slate-100">
          {incident.tickets.map((t) => (
            <li key={t.id} className="flex items-center justify-between gap-3 px-4 py-2.5 text-xs">
              <Link href={`/tickets/${t.id}`} className="min-w-0 flex-1 hover:underline">
                <span className="font-medium text-slate-900">{t.number}</span> <span className="text-slate-700">{t.subject}</span>
                <span className="block text-slate-500">{t.customer.name}</span>
              </Link>
              {t.similarity != null && <Badge tone="violet">%{Math.round(t.similarity * 100)} benzer</Badge>}
              <StatusBadge status={t.status} />
              {active && (
                <Button
                  variant="ghost"
                  size="sm"
                  aria-label={`${t.number} ticket'ını olaydan çıkar`}
                  loading={busy === `unlink-${t.id}`}
                  onClick={() => void run(`unlink-${t.id}`, () => api(`/incidents/${incident.id}/tickets/${t.id}`, { method: "DELETE" }))}
                >
                  <Unlink className="size-3.5" aria-hidden />
                </Button>
              )}
            </li>
          ))}
        </ul>
        {active && (
          <form onSubmit={linkTicket} className="flex items-center gap-2 border-t border-slate-100 px-4 py-3">
            <label htmlFor="link-number" className="sr-only">
              Ticket numarası
            </label>
            <Input id="link-number" value={linkNumber} onChange={(e) => setLinkNumber(e.target.value)} placeholder="RIQ-1010" className="h-8 max-w-40 text-xs" />
            <Button type="submit" variant="secondary" size="sm" loading={busy === "link"}>
              <Link2 className="size-3.5" aria-hidden /> Ticket bağla
            </Button>
          </form>
        )}
      </Card>

      <IncidentResolution incident={incident} isManager={isManager} onIncident={onIncident} />
    </div>
  );
}
