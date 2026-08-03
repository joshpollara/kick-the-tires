#!/usr/bin/env bash
# Terrateam audit-export hook. Use as both a pre and post hook:
#
#   hooks:
#     plan:
#       pre:  [{type: run, cmd: ['./scripts/terrateam-audit-export.sh', 'plan']}]
#       post: [{type: run, cmd: ['./scripts/terrateam-audit-export.sh', 'plan'], run_on: always}]
#     apply:
#       pre:  [{type: run, cmd: ['./scripts/terrateam-audit-export.sh', 'apply']}]
#       post: [{type: run, cmd: ['./scripts/terrateam-audit-export.sh', 'apply'], run_on: always}]
#
# Emits one JSON audit record per invocation:
#   pre hook  -> phase "started"   (who/what/where)
#   post hook -> phase "completed" (same, plus per-directory results)
# Phase is auto-detected: TERRATEAM_RESULTS_FILE only exists in post hooks.

set -euo pipefail

OPERATION="${1:?usage: terrateam-audit-export.sh <plan|apply>}"

PHASE=started
[[ -n "${TERRATEAM_RESULTS_FILE:-}" ]] && PHASE=completed

gh_api() {
  curl -sf \
    -H "Authorization: Bearer ${TERRATEAM_GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/$1"
}

PR_JSON=null
TRIGGERED_BY=""
if [[ "${TERRATEAM_RUN_KIND:-}" == "pr" ]]; then
  PR_NUMBER="$(jq -r '.id' <<< "${TERRATEAM_RUN_KIND_DATA}")"
  PR_JSON="$(gh_api "pulls/${PR_NUMBER}" \
    | jq '{number, title, url: .html_url, author: .user.login}')"
  # Who triggered: author of the most recent "terrateam ..." comment,
  # falling back to the PR author (autoplan runs have no trigger comment).
  TRIGGERED_BY="$(gh_api "issues/${PR_NUMBER}/comments?per_page=100" \
    | jq -r '[.[] | select(.body | startswith("terrateam"))] | last.user.login // empty')"
  TRIGGERED_BY="${TRIGGERED_BY:-$(jq -r '.author' <<< "${PR_JSON}")}"
fi

RESULTS=null
if [[ "${PHASE}" == "completed" ]]; then
  RESULTS="$(jq '{
    success,
    dirspaces: ([.steps[] | select(.scope.type == "dirspace")]
      | group_by([.scope.dir, .scope.workspace])
      | map({dir: .[0].scope.dir,
             workspace: .[0].scope.workspace,
             success: (map(.success) | all)}))
  }' "${TERRATEAM_RESULTS_FILE}")"
fi

AUDIT_RECORD="$(jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg operation "${OPERATION}" \
  --arg phase "${PHASE}" \
  --arg triggered_by "${TRIGGERED_BY}" \
  --argjson pr "${PR_JSON}" \
  --argjson results "${RESULTS}" \
  '{
    timestamp: $ts,
    source: "terrateam",
    event: "terrateam_\($operation)_\($phase)",
    run_kind: env.TERRATEAM_RUN_KIND,
    repo: env.GITHUB_REPOSITORY,
    pull_request: $pr,
    triggered_by: $triggered_by,
    actions_run_url: "\(env.GITHUB_SERVER_URL)/\(env.GITHUB_REPOSITORY)/actions/runs/\(env.GITHUB_RUN_ID)",
    results: $results
  }')"

echo "${AUDIT_RECORD}"

###############################################################
# Ship it. Pick ONE and delete the rest.
###############################################################

## CloudWatch Logs (needs AWS creds, e.g. oidc pre-hook before this one)
# aws logs put-log-events \
#   --log-group-name /terrateam/audit \
#   --log-stream-name "${GITHUB_REPOSITORY//\//-}" \
#   --log-events "timestamp=$(date +%s%3N),message=$(jq -Rs . <<< "${AUDIT_RECORD}")"

## Datadog Logs
# curl -sf -X POST "https://http-intake.logs.datadoghq.com/api/v2/logs" \
#   -H "Content-Type: application/json" \
#   -H "DD-API-KEY: ${DATADOG_API_KEY}" \
#   -d "$(jq '[. + {ddsource: "terrateam", service: "terrateam"}]' <<< "${AUDIT_RECORD}")"

## Coralogix
# curl -sf -X POST "https://ingress.<coralogix-domain>/logs/v1/singles" \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer ${CORALOGIX_SEND_DATA_KEY}" \
#   -d "$(jq '[{applicationName: "terrateam", subsystemName: env.GITHUB_REPOSITORY, severity: 3, body: tostring}]' <<< "${AUDIT_RECORD}")"
