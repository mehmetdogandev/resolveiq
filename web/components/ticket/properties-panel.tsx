"use client";

import { useState } from "react";
import { CheckCircle2, RotateCcw } from "lucide-react";
import { api, errorMessage } from "@/lib/api";
import { formatDateTime } from "@/lib/format";
import { PRIORITY_LABEL, STATUS_LABEL } from "@/lib/labels";
import type { Priority, TicketDetail, TicketStatus } from "@/lib/types";
import { SlaBadge } from "../badges";
import { useSession } from "../session";
import { Button, Card, CardHeader, ErrorState, Field, Input, Select } from "../ui";

export function PropertiesPanel({ ticket, onChange }: { ticket: TicketDetail; onChange: (t: TicketDetail) => void }) {
  const { me, meta } = useSession();
  const [saving, setSaving] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [tagDraft, setTagDraft] = useState(ticket.tags.join(", "));

  async function update(field: string, value: string | number | string[] | null) {
    setSaving(field);
    setError(null);
    try {
      const res = await api<{ ticket: TicketDetail }>(`/tickets/${ticket.id}`, { method: "PATCH", body: { ticket: { [field]: value } } });
      onChange(res.ticket);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(null);
    }
  }

  async function applyMacro(macroId: number) {
    setSaving("macro");
    setError(null);
    try {
      const res = await api<{ ticket: TicketDetail }>(`/tickets/${ticket.id}/apply_macro`, { method: "POST", body: { macro_id: macroId } });
      onChange(res.ticket);
      setTagDraft(res.ticket.tags.join(", "));
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(null);
    }
  }

  async function transition(action: "resolve" | "reopen") {
    setSaving(action);
    setError(null);
    try {
      const res = await api<{ ticket: TicketDetail }>(`/tickets/${ticket.id}/${action}`, { method: "POST" });
      onChange(res.ticket);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(null);
    }
  }

  const agents = meta.users;

  return (
    <Card>
      <CardHeader title="Ticket bilgileri" />
      <div className="space-y-3 p-4">
        <Field label="Durum" htmlFor="p-status">
          <Select id="p-status" value={ticket.status} disabled={!!saving} onChange={(e) => void update("status", e.target.value)}>
            {(Object.keys(STATUS_LABEL) as TicketStatus[]).map((s) => (
              <option key={s} value={s}>
                {STATUS_LABEL[s]}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Öncelik" htmlFor="p-priority">
          <Select id="p-priority" value={ticket.priority} disabled={!!saving} onChange={(e) => void update("priority", e.target.value)}>
            {(Object.keys(PRIORITY_LABEL) as Priority[]).map((p) => (
              <option key={p} value={p}>
                {PRIORITY_LABEL[p]}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Sorumlu" htmlFor="p-assignee">
          <div className="flex gap-2">
            <Select
              id="p-assignee"
              value={ticket.assignee?.id ?? ""}
              disabled={!!saving}
              onChange={(e) => void update("assignee_id", e.target.value ? Number(e.target.value) : null)}
            >
              <option value="">Atanmamış</option>
              {agents.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.name} · {u.team_name} ({u.open_tickets ?? 0} açık)
                </option>
              ))}
            </Select>
            {ticket.assignee?.id !== me.id && (
              <Button variant="secondary" size="sm" className="h-9 shrink-0" disabled={!!saving} onClick={() => void update("assignee_id", me.id)}>
                Bana ata
              </Button>
            )}
          </div>
        </Field>
        <Field label="Kategori" htmlFor="p-category">
          <Select id="p-category" value={ticket.category ?? ""} disabled={!!saving} onChange={(e) => void update("category", e.target.value || null)}>
            <option value="">Belirtilmedi</option>
            {meta.categories.map((c) => (
              <option key={c.code} value={c.code}>
                {c.name}
              </option>
            ))}
          </Select>
        </Field>
        {ticket.sla && (
          <div className="rounded-lg border border-slate-100 bg-slate-50 px-3 py-2">
            <div className="flex items-center justify-between gap-2">
              <p className="text-xs font-medium text-slate-600">SLA</p>
              <SlaBadge sla={ticket.sla} />
            </div>
            <p className="mt-1 text-[11px] text-slate-500">
              İlk yanıt: {formatDateTime(ticket.sla.first_response_due_at)} · Çözüm: {formatDateTime(ticket.sla.resolution_due_at)}
            </p>
          </div>
        )}
        <Field label="Makro" htmlFor="p-macro">
          <Select
            id="p-macro"
            defaultValue=""
            disabled={!!saving}
            onChange={(e) => {
              const id = e.target.value;
              e.target.value = "";
              if (id) void applyMacro(Number(id));
            }}
          >
            <option value="">Makro uygula…</option>
            {meta.macros.map((m) => (
              <option key={m.id} value={m.id}>
                {m.name}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Etiketler" htmlFor="p-tags">
          <Input
            id="p-tags"
            value={tagDraft}
            disabled={!!saving}
            onChange={(e) => setTagDraft(e.target.value)}
            onBlur={() => {
              const tags = tagDraft.split(",").map((t) => t.trim()).filter(Boolean);
              if (tags.join(",") !== ticket.tags.join(",")) void update("tags", tags);
            }}
            placeholder="garanti, batarya"
          />
        </Field>
        <Field label="Ürün" htmlFor="p-product">
          <Select id="p-product" value={ticket.product ?? ""} disabled={!!saving} onChange={(e) => void update("product", e.target.value || null)}>
            <option value="">Belirtilmedi</option>
            {meta.products.map((p) => (
              <option key={p.code} value={p.code}>
                {p.name}
              </option>
            ))}
          </Select>
        </Field>
        {error && <ErrorState message={error} />}
        {ticket.status === "resolved" ? (
          <Button variant="secondary" className="w-full" loading={saving === "reopen"} onClick={() => void transition("reopen")}>
            <RotateCcw className="size-4" aria-hidden /> Yeniden aç
          </Button>
        ) : (
          <Button variant="primary" className="w-full" loading={saving === "resolve"} onClick={() => void transition("resolve")}>
            <CheckCircle2 className="size-4" aria-hidden /> Çözüldü olarak işaretle
          </Button>
        )}
      </div>
    </Card>
  );
}
