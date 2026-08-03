#!/usr/bin/env bash
# Terrateam post-hook: export an audit record of this run to your log store.
#
# Runs as a post hook (hooks.plan.post / hooks.apply.post) inside the
# GitHub Actions job. Builds a JSON audit record answering "who ran what,
# where, and did it work", then ships it to CloudWatch / Datadog /
# Coralogix (pick the shipper at the bottom).
#
# Available context:
#   TERRATEAM_RUN_KIND        - "pr", "drift", "index", ...
#   TERRATEAM_RUN_KIND_DATA   - JSON; for pr runs: {"id": "<pr-number>"}
#   TERRATEAM_RESULTS_FILE    - JSON results of all dirspaces in this run
#   TERRATEAM_GITHUB_TOKEN    - GitHub token (for API lookups)
#   GITHUB_*                  - standard GitHub Actions variables

set -euo pipefail

gh_api() {
  curl -sf \
    -H "Authorization: Bearer ${TERRATEAM_GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "$1"
}

OPERATION="${1:-unknown}" # pass "plan" or "apply" from the hook config

PR_NUMBER=""
PR_AUTHOR=""
TRIGGERED_BY=""
PR_TITLE=""
PR_URL=""

if [[ "${TERRATEAM_RUN_KIND:-}" == "pr" ]]; then
  PR_NUMBER="$(printf '%s' "${TERRATEAM_RUN_KIND_DATA}" | jq -r '.id')"
  PR_JSON="$(gh_api "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}")"
  PR_AUTHOR="$(printf '%s' "${PR_JSON}" | jq -r '.user.login')"
  PR_TITLE="$(printf '%s' "${PR_JSON}" | jq -r '.title')"
  PR_URL="$(printf '%s' "${PR_JSON}" | jq -r '.html_url')"

  # Who triggered this operation: the author of the most recent
  # "terrateam plan/apply" comment. Falls back to the PR author
  # (autoplan / autoapply runs have no trigger comment).
  TRIGGERED_BY="$(gh_api "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments?per_page=100" \
    | jq -r --arg op "${OPERATION}" \
        '[.[] | select(.body | test("^terrateam (\($op)|apply|plan)"))] | last | .user.login // empty')"
  TRIGGERED_BY="${TRIGGERED_BY:-${PR_AUTHOR}}"
fi

AUDIT_RECORD="$(jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg source "terrateam" \
  --arg operation "${OPERATION}" \
  --arg run_kind "${TERRATEAM_RUN_KIND:-}" \
  --arg repo "${GITHUB_REPOSITORY:-}" \
  --arg pr_number "${PR_NUMBER}" \
  --arg pr_title "${PR_TITLE}" \
  --arg pr_url "${PR_URL}" \
  --arg pr_author "${PR_AUTHOR}" \
  --arg triggered_by "${TRIGGERED_BY}" \
  --arg branch "${TERRATEAM_BASE_REF:-}" \
  --arg sha "${GITHUB_SHA:-}" \
  --arg actions_run "${GITHUB_SERVER_URL:-}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}" \
  --slurpfile results "${TERRATEAM_RESULTS_FILE}" \
  '{
    timestamp: $ts,
    source: $source,
    operation: $operation,
    run_kind: $run_kind,
    repo: $repo,
    pull_request: {
      number: $pr_number,
      title: $pr_title,
      url: $pr_url,
      author: $pr_author
    },
    triggered_by: $triggered_by,
    base_branch: $branch,
    sha: $sha,
    actions_run_url: $actions_run,
    success: ($results[0] | (.overall.success // .success)),
    dirspaces: ($results[0] |
      if .dirspaces != null then
        [.dirspaces[] | {path, workspace, success}]
      else
        [.steps[]? | select(.scope.type? == "dirspace")]
        | group_by([.scope.dir, .scope.workspace])
        | map({
            path: .[0].scope.dir,
            workspace: .[0].scope.workspace,
            success: (map(.success or (.ignore_errors // false)) | all)
          })
      end)
  }')"

echo "Audit record:"
echo "${AUDIT_RECORD}" | jq .

###############################################################
# Pick ONE shipper below and delete the rest.
###############################################################

## CloudWatch Logs (needs aws creds in the job, e.g. via OIDC pre-hook)
# aws logs put-log-events \
#   --log-group-name /terrateam/audit \
#   --log-stream-name "${GITHUB_REPOSITORY//\//-}" \
#   --log-events "timestamp=$(date +%s%3N),message=$(printf '%s' "${AUDIT_RECORD}" | jq -Rs .)"

## Datadog Logs
# curl -sf -X POST "https://http-intake.logs.datadoghq.com/api/v2/logs" \
#   -H "Content-Type: application/json" \
#   -H "DD-API-KEY: ${DATADOG_API_KEY}" \
#   -d "$(printf '%s' "${AUDIT_RECORD}" | jq '[. + {ddsource: "terrateam", service: "terrateam"}]')"

## Coralogix
# curl -sf -X POST "https://ingress.<coralogix-domain>/logs/v1/singles" \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer ${CORALOGIX_SEND_DATA_KEY}" \
#   -d "$(printf '%s' "${AUDIT_RECORD}" | jq '[{applicationName: "terrateam", subsystemName: env.GITHUB_REPOSITORY, severity: 3, body: (. | tostring)}]')"
