import type { Tone } from "@/components/ui";
import type { AgentRun, Channel, IncidentStatus, Priority, TicketStatus } from "./types";

export const STATUS_LABEL: Record<TicketStatus, string> = {
  open: "Açık",
  in_progress: "İşlemde",
  pending: "Beklemede",
  resolved: "Çözüldü",
};

export const STATUS_TONE: Record<TicketStatus, Tone> = {
  open: "blue",
  in_progress: "teal",
  pending: "amber",
  resolved: "green",
};

export const PRIORITY_LABEL: Record<Priority, string> = {
  low: "Düşük",
  normal: "Normal",
  high: "Yüksek",
  urgent: "Acil",
};

export const PRIORITY_TONE: Record<Priority, Tone> = {
  low: "slate",
  normal: "slate",
  high: "amber",
  urgent: "red",
};

export const CHANNEL_LABEL: Record<Channel, string> = {
  email: "E-posta",
  web: "Web formu",
  chat: "Canlı sohbet",
};

export const INCIDENT_STATUS_LABEL: Record<IncidentStatus, string> = {
  proposed: "Önerildi (hipotez)",
  confirmed: "Onaylandı",
  resolved: "Çözüldü",
  dismissed: "Reddedildi",
};

export const INCIDENT_STATUS_TONE: Record<IncidentStatus, Tone> = {
  proposed: "violet",
  confirmed: "amber",
  resolved: "green",
  dismissed: "slate",
};

export const SEVERITY_LABEL = { low: "Düşük", medium: "Orta", high: "Yüksek", critical: "Kritik" } as const;

export const AGENT_LABEL: Record<AgentRun["agent_type"], string> = {
  triage: "Akıllı triage",
  pattern_scan: "Örüntü tespiti",
  resolution: "Çözüm ve önleme",
};

export const SOURCE_LABEL: Record<AgentRun["source"], string> = {
  openai: "OpenAI",
  fallback: "Fallback (LLM yok)",
  fake: "Test",
  none: "Yapılandırılmamış",
};

export const ACTION_LABEL: Record<string, string> = {
  "ticket.created": "ticket oluşturdu",
  "ticket.updated": "ticket'ı güncelledi",
  "ticket.resolved": "ticket'ı çözdü",
  "ticket.reopened": "ticket'ı yeniden açtı",
  "ticket.reply_sent": "yanıt gönderdi",
  "ticket.internal_note_added": "iç not ekledi",
  "ticket.article_linked": "makale bağladı",
  "ticket.article_unlinked": "makale bağlantısını kaldırdı",
  "ticket.macro_applied": "makro uyguladı",
  "ticket.bulk_updated": "toplu güncelledi",
  "ticket.merged": "ticket birleştirdi",
  "ticket.merged_into": "bu ticket'ı birleştirdi",
  "ticket.related_linked": "ilişkili ticket bağladı",
  "ticket.csat_recorded": "CSAT kaydetti",
  "ticket.triage_requested": "AI triage çalıştırdı",
  "ticket.triage_applied": "AI triage önerilerini uyguladı",
  "ticket.resolution_prepared": "AI çözüm taslağı hazırlattı",
  "incident.proposed": "olası olay önerdi (AI)",
  "incident.proposal_refreshed": "olay önerisini güncelledi (AI)",
  "incident.confirmed": "olayı onayladı",
  "incident.dismissed": "olayı reddetti",
  "incident.resolved": "olayı çözdü",
  "incident.ticket_linked": "olaya ticket bağladı",
  "incident.ticket_unlinked": "olaydan ticket çıkardı",
  "incident.resolution_prepared": "AI çözüm paketi hazırlattı",
  "incident.resolution_applied": "ortak yanıtı uyguladı",
  "article.created": "makale oluşturdu",
  "article.updated": "makaleyi güncelledi",
  "article.published": "makaleyi yayınladı",
  "article.unpublished": "makaleyi yayından kaldırdı",
  "session.login": "giriş yaptı",
};

export function actionLabel(action: string) {
  return ACTION_LABEL[action] ?? action;
}
