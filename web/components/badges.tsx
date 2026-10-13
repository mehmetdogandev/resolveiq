import { Globe, Mail, MessageCircle, Sparkles } from "lucide-react";
import { CHANNEL_LABEL, INCIDENT_STATUS_LABEL, INCIDENT_STATUS_TONE, PRIORITY_LABEL, PRIORITY_TONE, SOURCE_LABEL, STATUS_LABEL, STATUS_TONE } from "@/lib/labels";
import type { AgentRun, Channel, IncidentStatus, Priority, TicketStatus } from "@/lib/types";
import { Badge } from "./ui";

export function StatusBadge({ status }: { status: TicketStatus }) {
  return <Badge tone={STATUS_TONE[status]}>{STATUS_LABEL[status]}</Badge>;
}

export function PriorityBadge({ priority }: { priority: Priority }) {
  return (
    <Badge tone={PRIORITY_TONE[priority]}>
      {(priority === "urgent" || priority === "high") && <span className="size-1.5 rounded-full bg-current" aria-hidden />}
      {PRIORITY_LABEL[priority]}
    </Badge>
  );
}

const channelIcons = { email: Mail, web: Globe, chat: MessageCircle };

export function ChannelIcon({ channel, className = "size-3.5" }: { channel: Channel; className?: string }) {
  const Icon = channelIcons[channel];
  return <Icon className={className} aria-label={CHANNEL_LABEL[channel]} />;
}

export function ChannelBadge({ channel }: { channel: Channel }) {
  return (
    <Badge tone="slate">
      <ChannelIcon channel={channel} className="size-3" />
      {CHANNEL_LABEL[channel]}
    </Badge>
  );
}

export function IncidentStatusBadge({ status }: { status: IncidentStatus }) {
  return <Badge tone={INCIDENT_STATUS_TONE[status]}>{INCIDENT_STATUS_LABEL[status]}</Badge>;
}

/** Makes it explicit whether an AI result came from a real provider call. */
export function AiSourceBadge({ run }: { run: Pick<AgentRun, "source" | "model" | "status"> }) {
  if (run.status === "failed") return <Badge tone="red">AI çağrısı başarısız</Badge>;
  const tone = run.source === "openai" ? "teal" : run.source === "fallback" ? "amber" : "slate";
  return (
    <Badge tone={tone} className="font-normal">
      <Sparkles className="size-3" aria-hidden />
      {SOURCE_LABEL[run.source]}
      {run.source === "openai" && run.model ? ` · ${run.model}` : ""}
    </Badge>
  );
}
