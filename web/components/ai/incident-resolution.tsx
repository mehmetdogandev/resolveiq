"use client";

import { useMemo, useState } from "react";
import { CheckCircle2, Lightbulb, RefreshCw, Send } from "lucide-react";
import { api, errorMessage } from "@/lib/api";
import { formatDateTime } from "@/lib/format";
import type { AgentRun, IncidentDetail, ResolutionOutput, TicketStatus } from "@/lib/types";
import { StatusBadge } from "../badges";
import { Button, Card, CardHeader, ErrorState, Field, Select, Spinner, Textarea } from "../ui";
import { AiErrorNotice } from "./ai-unavailable";
import { KbDraftButton } from "./kb-draft-button";
import { RunMeta } from "./run-meta";

const ACTION_LABEL: Record<ResolutionOutput["ticket_actions"][number]["action"], string> = {
  reply_and_pending: "Yanıtla, beklemeye al",
  reply_and_resolve: "Yanıtla ve çöz",
  link_only: "Yalnızca bağla",
};

function defaultSelection(incident: IncidentDetail) {
  const actionable = new Set(
    (incident.resolution_plan.ticket_actions ?? []).filter((a) => a.action !== "link_only").map((a) => a.ticket_number),
  );
  return new Set(
    incident.tickets.filter((t) => t.status !== "resolved" && (actionable.size === 0 || actionable.has(t.number))).map((t) => t.id),
  );
}

export function IncidentResolution({
  incident,
  isManager,
  onIncident,
}: {
  incident: IncidentDetail;
  isManager: boolean;
  onIncident: (i: IncidentDetail) => void;
}) {
  const plan = incident.resolution_plan;
  const hasPlan = Boolean(plan.customer_reply);
  const active = incident.status === "proposed" || incident.status === "confirmed";

  const [run, setRun] = useState<AgentRun<ResolutionOutput> | null>(null);
  const [preparing, setPreparing] = useState(false);
  const [prepareError, setPrepareError] = useState<unknown>(null);
  const [reply, setReply] = useState(plan.customer_reply ?? "");
  const [note, setNote] = useState("");
  const [status, setStatus] = useState<TicketStatus>("pending");
  const [selected, setSelected] = useState<Set<number>>(() => defaultSelection(incident));
  const [confirming, setConfirming] = useState(false);
  const [applying, setApplying] = useState(false);
  const [applyError, setApplyError] = useState<string | null>(null);
  const [applied, setApplied] = useState<string[] | null>(null);

  const planKey = `${incident.id}:${plan.agent_run_id ?? ""}`;
  const [syncedPlanKey, setSyncedPlanKey] = useState(planKey);
  if (syncedPlanKey !== planKey) {
    setSyncedPlanKey(planKey);
    setReply(plan.customer_reply ?? "");
    setSelected(defaultSelection(incident));
    setConfirming(false);
  }

  const openTickets = useMemo(() => incident.tickets.filter((t) => t.status !== "resolved"), [incident.tickets]);

  async function prepare() {
    setPreparing(true);
    setPrepareError(null);
    setApplied(null);
    try {
      const res = await api<{ run: AgentRun<ResolutionOutput>; incident: IncidentDetail }>(`/incidents/${incident.id}/prepare_resolution`, { method: "POST" });
      setRun(res.run);
      onIncident(res.incident);
    } catch (err) {
      setPrepareError(err);
    } finally {
      setPreparing(false);
    }
  }

  async function apply() {
    setApplying(true);
    setApplyError(null);
    try {
      const res = await api<{ incident: IncidentDetail; updated_tickets: string[] }>(`/incidents/${incident.id}/apply_resolution`, {
        method: "POST",
        body: { reply_body: reply, ticket_ids: [...selected], status, internal_note: note || null },
      });
      setApplied(res.updated_tickets);
      setSelected(new Set());
      setConfirming(false);
      onIncident(res.incident);
    } catch (err) {
      setApplyError(errorMessage(err));
    } finally {
      setApplying(false);
    }
  }

  const toggle = (id: number) =>
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  return (
    <Card>
      <CardHeader
        title={
          <span className="flex items-center gap-1.5">
            <Lightbulb className="size-4 text-accent-600" aria-hidden /> Çözüm ve önleme paketi
          </span>
        }
        description="Ortak müşteri yanıtı, sorun giderme adımları, eskalasyon ve bilgi bankası boşluğu. Gözden geçirilmeden hiçbir şey gönderilmez."
        action={
          active &&
          hasPlan &&
          !preparing && (
            <Button variant="ghost" size="sm" onClick={() => void prepare()}>
              <RefreshCw className="size-3.5" aria-hidden /> Yeniden hazırla
            </Button>
          )
        }
      />
      <div className="space-y-4 p-4">
        {preparing && <Spinner label="Olay kanıtları, makaleler ve ticket'lar inceleniyor..." />}
        {prepareError != null && <AiErrorNotice error={prepareError} />}
        {!hasPlan && !preparing && (
          active ? (
            <div className="space-y-2">
              <p className="text-xs text-slate-600">Bu olay için henüz çözüm paketi hazırlanmadı.</p>
              <Button variant="accent" size="sm" onClick={() => void prepare()}>
                Çözüm paketi hazırla
              </Button>
            </div>
          ) : (
            <p className="text-xs text-slate-500">Bu olay kapandığı için yeni çözüm paketi hazırlanamaz.</p>
          )
        )}

        {hasPlan && !preparing && (
          <>
            {run && <RunMeta run={run} />}
            {plan.troubleshooting_steps && plan.troubleshooting_steps.length > 0 && (
              <div>
                <p className="mb-1 text-xs font-medium text-slate-700">Sorun giderme adımları</p>
                <ol className="list-decimal space-y-1 pl-4 text-xs text-slate-700">
                  {plan.troubleshooting_steps.map((s) => (
                    <li key={s}>{s}</li>
                  ))}
                </ol>
              </div>
            )}
            {plan.internal_escalation?.needed && (
              <p className="rounded-md bg-amber-50 px-3 py-2 text-xs text-amber-900">
                İç eskalasyon önerisi: <strong>{plan.internal_escalation.team}</strong> · {plan.internal_escalation.summary}
              </p>
            )}
            {plan.kb_gap && plan.kb_article?.title && (
              <div className="rounded-lg border border-dashed border-slate-300 p-3">
                <p className="mb-1.5 text-xs text-slate-600">
                  Bilgi bankası boşluğu: <strong>{plan.kb_article.title}</strong>
                </p>
                <KbDraftButton
                  title={plan.kb_article.title}
                  body={plan.kb_article.body}
                  tags={plan.kb_article.tags ?? []}
                  product={incident.product}
                  category={incident.tickets.find((t) => t.category)?.category ?? null}
                  runId={run?.id ?? plan.agent_run_id}
                />
              </div>
            )}

            <Field label="Ortak müşteri yanıtı (düzenlenebilir)" htmlFor="shared-reply" hint="{{musteri_adi}} her ticket'ta müşterinin adıyla değiştirilir.">
              <Textarea id="shared-reply" rows={9} value={reply} onChange={(e) => setReply(e.target.value)} />
            </Field>

            <div>
              <p className="mb-1.5 text-xs font-medium text-slate-700">Uygulanacak ticket&apos;lar</p>
              <ul className="divide-y divide-slate-100 rounded-lg border border-slate-200">
                {incident.tickets.map((t) => {
                  const action = plan.ticket_actions?.find((a) => a.ticket_number === t.number);
                  const disabled = t.status === "resolved";
                  return (
                    <li key={t.id}>
                      <label className={`flex items-start gap-2.5 px-3 py-2 text-xs ${disabled ? "opacity-60" : "cursor-pointer hover:bg-slate-50"}`}>
                        <input type="checkbox" className="mt-0.5 accent-accent-600" checked={selected.has(t.id)} disabled={disabled} onChange={() => toggle(t.id)} />
                        <span className="min-w-0 flex-1">
                          <span className="flex flex-wrap items-center gap-1.5">
                            <span className="font-medium text-slate-900">{t.number}</span>
                            <span className="text-slate-500">{t.customer.name}</span>
                            <StatusBadge status={t.status} />
                          </span>
                          {action && (
                            <span className="mt-0.5 block text-slate-500">
                              AI önerisi: {ACTION_LABEL[action.action]} · {action.reason}
                            </span>
                          )}
                        </span>
                      </label>
                    </li>
                  );
                })}
              </ul>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Uygulama sonrası durum" htmlFor="apply-status">
                <Select id="apply-status" value={status} onChange={(e) => setStatus(e.target.value as TicketStatus)}>
                  <option value="pending">Beklemede (müşteri dönüşü bekleniyor)</option>
                  <option value="in_progress">İşlemde</option>
                  <option value="resolved">Çözüldü</option>
                </Select>
              </Field>
              <Field label="İç not (isteğe bağlı)" htmlFor="apply-note">
                <Textarea id="apply-note" rows={2} value={note} onChange={(e) => setNote(e.target.value)} />
              </Field>
            </div>

            {applyError && <ErrorState message={applyError} />}
            {applied && (
              <p className="flex items-center gap-1.5 rounded-md bg-emerald-50 px-3 py-2 text-xs text-emerald-800" role="status">
                <CheckCircle2 className="size-4" aria-hidden /> Yanıt {applied.length} ticket&apos;a eklendi: {applied.join(", ")}
              </p>
            )}

            {!isManager ? (
              <p className="text-xs text-slate-500">Toplu uygulama yalnızca yöneticiler tarafından yapılabilir.</p>
            ) : incident.status !== "confirmed" ? (
              <p className="text-xs text-slate-500">Toplu uygulama için olayın önce yönetici tarafından onaylanması gerekir.</p>
            ) : confirming ? (
              <div className="flex flex-wrap items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 p-3">
                <p className="flex-1 text-xs text-amber-900">
                  {selected.size} ticket&apos;a ortak yanıt eklenecek ve durumları güncellenecek. Onaylıyor musunuz?
                </p>
                <Button variant="secondary" size="sm" onClick={() => setConfirming(false)}>
                  Vazgeç
                </Button>
                <Button variant="accent" size="sm" loading={applying} onClick={() => void apply()}>
                  Evet, uygula
                </Button>
              </div>
            ) : (
              <div className="space-y-2">
                {incident.resolution_applied_at && (
                  <p className="text-xs text-slate-600">
                    Ortak yanıt {formatDateTime(incident.resolution_applied_at)} tarihinde uygulandı. Tekrar uygulamak seçili müşterilere ikinci bir mesaj
                    ekler.
                  </p>
                )}
                <Button
                  variant={incident.resolution_applied_at ? "secondary" : "accent"}
                  disabled={selected.size === 0 || reply.trim().length < 10 || openTickets.length === 0}
                  onClick={() => setConfirming(true)}
                >
                  <Send className="size-4" aria-hidden /> {incident.resolution_applied_at ? "Tekrar uygula" : "Uygula"}: seçili {selected.size} ticket
                </Button>
              </div>
            )}
          </>
        )}
      </div>
    </Card>
  );
}
