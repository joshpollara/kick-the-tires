#!/usr/bin/env sh
echo "[my-terraform-wrapper] invoked: $*" >&2
exec terraform "$@"
