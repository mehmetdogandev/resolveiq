export type AiMode = "openai" | "fallback" | "fake" | "unavailable";

export type Health = {
  status: "ok" | "degraded";
  app: string;
  version: string;
  environment: string;
  checks: { database: string };
  ai: { configured: boolean; mode: AiMode };
  time: string;
};

export type Role = "manager" | "agent";

export type UserSummary = {
  id: number;
  name: string;
  role: Role;
  team: string;
  team_name: string;
  title: string | null;
  initials: string;
  open_tickets?: number;
};

export type Me = UserSummary & { email: string };

export type Channel = "email" | "web" | "chat";
export type TicketStatus = "open" | "in_progress" | "pending" | "resolved";
export type Priority = "low" | "normal" | "high" | "urgent";

export type CodeName = { code: string; name: string };

export type CustomerSummary = {
  id: number;
  name: string;
  email: string;
  company: string | null;
  tier: "standard" | "pro" | "enterprise";
  city: string | null;
};

export type Macro = {
  id: number;
  name: string;
  description: string | null;
  actions: {
    status?: TicketStatus;
    priority?: Priority;
    assignee_id?: number;
    add_tags?: string[];
    reply?: string;
  };
};

export type SlaState = "none" | "ok" | "warning" | "breached" | "met";

export type TicketSla = {
  policy_id: number | null;
  policy_name: string | null;
  first_response_due_at: string | null;
  resolution_due_at: string | null;
  breached_at: string | null;
  state: SlaState;
};

export type CsatRating = { id: number; score: number; comment: string | null; created_at: string };

export type Meta = {
  products: CodeName[];
  categories: CodeName[];
  teams: CodeName[];
  users: UserSummary[];
  customers: CustomerSummary[];
  macros: Macro[];
  ai: { configured: boolean; mode: AiMode; model: string | null };
};

export type TicketSummary = {
  id: number;
  number: string;
  subject: string;
  channel: Channel;
  status: TicketStatus;
  priority: Priority;
  category: string | null;
  category_name: string | null;
  product: string | null;
  product_name: string | null;
  customer: CustomerSummary;
  assignee: UserSummary | null;
  tags: string[];
  created_at: string;
  updated_at: string;
  resolved_at: string | null;
  first_response_at: string | null;
  sla: TicketSla | null;
  merged_into_id: number | null;
  similarity?: number;
  link_kind?: "related" | "merged";
};

export type TicketMessage = {
  id: number;
  body: string;
  internal: boolean;
  author_type: "agent" | "customer" | "system";
  author_name: string;
  origin: "manual" | "ai_draft" | "knowledge" | "incident";
  created_at: string;
};

export type AuditEntry = {
  id: number;
  action: string;
  actor_name: string;
  target_type: string | null;
  target_id: number | null;
  metadata: Record<string, unknown>;
  created_at: string;
};

export type ArticleRef = { id: number; title: string; slug: string };

export type TriageOutput = {
  category: string | null;
  category_name: string | null;
  priority: Priority | null;
  team: string | null;
  team_name: string | null;
  assignee_id: number | null;
  assignee_name: string | null;
  reasoning: string;
  evidence: string[];
  articles: ArticleRef[];
  confidence: number;
  draft_reply: string;
  dropped_suggestions: string[];
};

export type ResolutionOutput = {
  troubleshooting_steps: string[];
  customer_reply: string;
  internal_escalation: { needed: boolean; team: string; summary: string };
  kb_gap: boolean;
  kb_article: { title: string; body: string; tags: string[] };
  ticket_actions: { ticket_number: string; action: "reply_and_pending" | "reply_and_resolve" | "link_only"; reason: string }[];
  articles: ArticleRef[];
  product: string | null;
  agent_run_id?: number;
};

export type AgentRun<TOutput = Record<string, unknown>> = {
  id: number;
  agent_type: "triage" | "pattern_scan" | "resolution";
  status: "succeeded" | "failed";
  source: "openai" | "fallback" | "fake" | "none";
  model: string | null;
  tokens_in: number;
  tokens_out: number;
  latency_ms: number | null;
  cost_usd: number;
  cost_is_estimate: boolean;
  output: TOutput;
  error_summary: string | null;
  provider_request_id: string | null;
  subject_type: string | null;
  subject_id: number | null;
  user_name: string | null;
  applied_at: string | null;
  created_at: string;
};

export type IncidentStatus = "proposed" | "confirmed" | "resolved" | "dismissed";

export type IncidentSummary = {
  id: number;
  code: string;
  title: string;
  summary: string;
  status: IncidentStatus;
  severity: "low" | "medium" | "high" | "critical";
  confidence: number | null;
  product: string | null;
  product_name: string | null;
  ticket_count: number;
  affected_customers: number;
  has_resolution_plan: boolean;
  resolution_applied_at: string | null;
  created_at: string;
  confirmed_at: string | null;
  resolved_at: string | null;
  similarity?: number;
};

export type IncidentDetail = IncidentSummary & {
  suspected_root_cause: string | null;
  uncertainty: string | null;
  symptoms: string[];
  evidence: { ticket_number: string; observation: string }[];
  suggested_actions: string[];
  recommended_next_action: string | null;
  resolution_plan: Partial<ResolutionOutput>;
  resolution_note: string | null;
  confirmed_by: UserSummary | null;
  detected_by_run: AgentRun | null;
  tickets: (TicketSummary & { similarity: number | null })[];
};

export type TicketDetail = TicketSummary & {
  description: string;
  messages: TicketMessage[];
  articles: ArticleSummary[];
  incidents: IncidentSummary[];
  latest_triage: AgentRun<TriageOutput> | null;
  latest_resolution: AgentRun<ResolutionOutput> | null;
  similar_tickets: (TicketSummary & { similarity: number })[];
  related_tickets: TicketSummary[];
  merged_tickets: TicketSummary[];
  incident_suggestions: IncidentSummary[];
  activity: AuditEntry[];
  csat: CsatRating | null;
  customer_history: { total_tickets: number; open_tickets: number };
  permissions: { can_manage: boolean };
};

export type PageMeta = { page: number; per_page: number; total: number; total_pages: number };

export type TicketList = {
  tickets: TicketSummary[];
  meta: PageMeta & { channel_counts: Partial<Record<Channel, number>> };
};

export type ArticleSummary = {
  id: number;
  title: string;
  slug: string;
  product: string | null;
  product_name: string | null;
  category: string | null;
  category_name: string | null;
  tags: string[];
  status: "draft" | "published";
  source: "manual" | "ai_draft";
  excerpt: string;
  updated_at: string;
  published_at: string | null;
};

export type ArticleDetail = ArticleSummary & {
  body: string;
  steps: string[];
  author: UserSummary | null;
  linked_tickets_count: number;
};

export type CustomerDetail = CustomerSummary & {
  since: string;
  products: CodeName[];
  stats: { total: number; open: number; resolved: number; by_channel: Partial<Record<Channel, number>> };
};

export type PendingAction = {
  kind: "triage_ready" | "incident_proposed" | "resolution_ready" | "kb_draft";
  title: string;
  detail: string;
  href: string;
  created_at: string;
};

export type Dashboard = {
  generated_at: string;
  synthetic_data: boolean;
  totals: { open: number; urgent_high: number; unassigned: number; resolved: number; resolved_last_7d: number; mine_open: number; sla_breached: number; csat_average: number | null };
  by_status: Record<TicketStatus, number>;
  by_channel: Record<Channel, number>;
  by_priority: Record<Priority, number>;
  incidents: { proposed: number; confirmed: number; resolved: number; recent: IncidentSummary[] };
  agent_runs: AgentRun[];
  ai_cost_usd: number;
  recent_activity: AuditEntry[];
  pending_actions: PendingAction[];
};

export type Reports = {
  generated_at: string;
  totals: { tickets: number; open: number; resolved: number; breached_open: number };
  first_reply: { average_minutes: number | null; count: number };
  resolution: { average_minutes: number | null; count: number };
  sla: { evaluated: number; met: number; breached: number; met_rate: number | null };
  csat: { average: number | null; count: number; distribution: Record<number, number> };
  by_channel: Record<Channel, { tickets: number; open: number; avg_first_reply_minutes: number | null; avg_resolution_minutes: number | null }>;
  by_agent: {
    user: UserSummary;
    open: number;
    resolved: number;
    avg_first_reply_minutes: number | null;
    avg_resolution_minutes: number | null;
    csat_average: number | null;
  }[];
  by_priority: Record<Priority, number>;
};

export type AgentRunList = {
  runs: AgentRun[];
  totals: { source: string; runs: number; tokens_in: number; tokens_out: number; cost_usd: number }[];
  by_agent: Partial<Record<AgentRun["agent_type"], number>>;
  failed: number;
  cost_is_estimate: boolean;
};

export type PatternScanResult = {
  groups_found: number;
  candidates_scanned: number;
  proposals: { incident: IncidentSummary; run: AgentRun; created: boolean }[];
};
