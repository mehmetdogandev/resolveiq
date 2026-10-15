module Api
  module V1
    class AgentRunsController < BaseController
      def index
        scope = AgentRun.includes(:user).recent
        scope = scope.where(agent_type: params[:agent_type]) if AgentRun::AGENT_TYPES.include?(params[:agent_type])
        runs = scope.limit(40)
        totals = AgentRun.group(:source).pluck(:source, Arel.sql("COUNT(*)"), Arel.sql("SUM(tokens_in)"), Arel.sql("SUM(tokens_out)"), Arel.sql("SUM(cost_usd)"))
        render json: {
          runs: runs.map(&:as_api_json),
          totals: totals.map { |source, count, tin, tout, cost| { source: source, runs: count, tokens_in: tin.to_i, tokens_out: tout.to_i, cost_usd: cost.to_f } },
          by_agent: AgentRun.succeeded.group(:agent_type).count,
          failed: AgentRun.where(status: "failed").count,
          cost_is_estimate: true
        }
      end

      def show
        render json: { run: AgentRun.find(params[:id]).as_api_json }
      end
    end
  end
end
