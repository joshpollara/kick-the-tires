#!/usr/bin/env sh
set -u

SCENARIO="${1:-unknown}"
echo "==PROOF=="
echo "scenario=${SCENARIO}"
echo "--env--"
env | grep -E '^(TFENV_[A-Z_]+|TOFUENV_[A-Z_]+|TG_[A-Z_]+|TERRATEAM_TF_CMD|TERRATEAM_ENGINE_NAME|TERRAGRUNT_TFPATH|TERRAGRUNT_NON_INTERACTIVE)=' | sort
echo "--terragrunt version--"
terragrunt --version
echo "--terraform version--"
terraform version
echo "==END=="
