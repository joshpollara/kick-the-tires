#!/usr/bin/env sh
set -u
SCENARIO="${1:-unknown}"
echo "==PROOF=="
echo "scenario=${SCENARIO}"
echo "--env--"
env | grep -E '^(TF_CMD|TFENV_|TOFUENV_|TG_|STATEGRAPH_|TERRATEAM_TF_CMD|TERRATEAM_ENGINE_NAME|TERRAGRUNT_TFPATH)=' | sort
echo "--which--"
echo "TERRATEAM_TF_CMD=${TERRATEAM_TF_CMD:-<unset>}"
echo "TF_CMD=${TF_CMD:-<unset>}"
BIN="${TERRATEAM_TF_CMD:-tofu}"
echo "--${BIN} version--"
"${BIN}" version 2>&1 || true
echo "==END=="
