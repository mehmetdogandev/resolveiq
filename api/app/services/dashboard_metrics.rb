class DashboardMetrics
  def initialize(user)
    @user = user
  end

  def as_json(*)
    tickets = Ticket.all
    {
      generated_at: Time.current,
      synthetic_data: true,
      totals: {
        open: tickets.unresolved.count,
        urgent_high: tickets.unresolved.where(priority: %w[urgent high]).count,
        unassigned: tickets.unresolved.where(assignee_id: nil).count,
        resolved: tickets.resolved.count,
        resolved_last_7d: tickets.resolved.where("resolved_at >= ?", 7.days.ago).count,
        mine_open: tickets.unresolved.where(assignee_id: @user.id).count
      },
      by_status: Ticket.statuses.keys.index_with { |s| 0 }.merge(tickets.group(:status).count),
      by_channel: Ticket.channels.keys.index_with { |c| 0 }.merge(tickets.unresolved.group(:channel).count),
      by_priority: Ticket.priorities.keys.index_with { |p| 0 }.merge(tickets.unresolved.group(:priority).count),
      incidents: {
        proposed: Incident.proposed.count,
        confirmed: Incident.confirmed.count,
        resolved: Incident.resolved.count,
        recent: Incident.order(created_at: :desc).limit(4).map(&:summary_json)
      },
      agent_runs: AgentRun.includes(:user).recent.limit(6).map(&:as_api_json),
      ai_cost_usd: AgentRun.sum(:cost_usd).to_f,
      recent_activity: AuditLog.includes(:actor).recent.limit(10).map(&:as_api_json),
      pending_actions: pending_actions
    }
  end

  private

  # Work the AI has already prepared that only needs a human decision.
  def pending_actions
    actions = []

    triage_runs = AgentRun.succeeded.where(agent_type: "triage", applied_at: nil, subject_type: "Ticket")
                          .where("agent_runs.created_at >= ?", 7.days.ago).recent.limit(20)
    seen = Set.new
    triage_runs.includes(:subject).each do |run|
      ticket = run.subject
      next if ticket.nil? || ticket.resolved? || !seen.add?(ticket.id)

      actions << { kind: "triage_ready", title: "#{ticket.number}: triage önerisi hazır", detail: ticket.subject,
                   href: "/tickets/#{ticket.id}", created_at: run.created_at }
    end

    Incident.proposed.order(created_at: :desc).limit(5).each do |inc|
      actions << { kind: "incident_proposed", title: "#{inc.code}: olası ortak sorun onay bekliyor", detail: inc.title,
                   href: "/ai-insights?incident=#{inc.id}", created_at: inc.created_at }
    end

    Incident.confirmed.where(resolution_applied_at: nil).where.not(resolution_plan: {}).limit(5).each do |inc|
      actions << { kind: "resolution_ready", title: "#{inc.code}: ortak yanıt ve aksiyonlar hazır", detail: inc.title,
                   href: "/ai-insights?incident=#{inc.id}", created_at: inc.updated_at }
    end

    KnowledgeArticle.draft.where(source: "ai_draft").order(created_at: :desc).limit(5).each do |a|
      actions << { kind: "kb_draft", title: "Bilgi bankası taslağı yayın bekliyor", detail: a.title,
                   href: "/knowledge/#{a.slug}", created_at: a.created_at }
    end

    actions.sort_by { |a| a[:created_at] }.reverse.first(10)
  end
end
