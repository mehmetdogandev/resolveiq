import { formatUsd, timeAgo } from "@/lib/format";
import type { AgentRun } from "@/lib/types";
import { AiSourceBadge } from "../badges";

/** Provenance line shown under every AI result: real provider vs fallback, tokens, latency, estimated cost. */
export function RunMeta({ run }: { run: AgentRun<unknown> }) {
  return (
    <div className="flex flex-wrap items-center gap-x-2 gap-y-1 text-[11px] text-slate-500">
      <AiSourceBadge run={run} />
      {run.source === "openai" && (
        <>
          <span>
            {run.tokens_in + run.tokens_out} token · {formatUsd(run.cost_usd)} (tahmini)
          </span>
          {run.provider_request_id && <span title={run.provider_request_id}>istek: {run.provider_request_id.slice(0, 14)}…</span>}
        </>
      )}
      {run.latency_ms != null && <span>{(run.latency_ms / 1000).toFixed(1)} sn</span>}
      <span>{timeAgo(run.created_at)}</span>
    </div>
  );
}
