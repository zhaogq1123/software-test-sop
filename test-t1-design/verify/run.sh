#!/usr/bin/env bash
# verify runner (template). env.local|env.example + cases.json → out.txt
# Paths/fields must match T1-04; do not invent endpoints.
set -euo pipefail
cd "$(dirname "$0")"

ENV_FILE=env.example
[[ -f env.local ]] && ENV_FILE=env.local
set -a
# shellcheck disable=SC1090
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$' | sed 's/\r$//')
set +a

BASE_URL="${BASE_URL:?BASE_URL empty — copy env.example to env.local}"
BASE_URL="${BASE_URL%/}"
SVC="${SVC:-}"
SUCCESS_CODE="${SUCCESS_CODE:-}"

OUT=out.txt
{
  echo "VERIFY $(date -Iseconds 2>/dev/null || date)"
  echo "ENV_FILE=$ENV_FILE"
  echo "BASE=$BASE_URL"
} >"$OUT"

fail=0
# minimal parser: requires jq
if ! command -v jq >/dev/null; then
  echo "NEED jq to parse cases.json" | tee -a "$OUT"
  exit 2
fi

n=$(jq 'length' cases.json)
i=0
while [[ $i -lt $n ]]; do
  id=$(jq -r ".[$i].id" cases.json)
  ac=$(jq -r ".[$i].ac" cases.json)
  card=$(jq -r ".[$i].card" cases.json)
  method=$(jq -r ".[$i].method" cases.json)
  path=$(jq -r ".[$i].path" cases.json | sed "s/{svc}/$SVC/g")
  url="$BASE_URL$path"
  # expand ${VAR} in Authorization header (common case)
  auth=$(jq -r ".[$i].headers.Authorization // empty" cases.json)
  while [[ "$auth" =~ \$\{([A-Z0-9_]+)\} ]]; do
    var="${BASH_REMATCH[1]}"
    auth="${auth//\$\{$var\}/${!var-}}"
  done
  body=$(jq -c ".[$i].body // empty" cases.json)
  deny=$(jq -r ".[$i].expect.deny // false" cases.json)
  hdr=(-H "Content-Type: application/json")
  [[ -n "$auth" ]] && hdr+=(-H "Authorization: $auth")
  args=(-sS -w "\n%{http_code}" -X "$method" "$url" "${hdr[@]}")
  [[ "$body" != "null" && -n "$body" ]] && args+=(-d "$body")
  resp=$(curl "${args[@]}" || true)
  http=$(echo "$resp" | tail -n1)
  text=$(echo "$resp" | sed '$d')
  ok=0
  if [[ "$deny" == "true" ]]; then
    if [[ "$http" == "401" || "$http" == "403" ]]; then ok=1; fi
    if [[ -n "$SUCCESS_CODE" && "$text" != *"$SUCCESS_CODE"* ]]; then ok=1; fi
  else
    if [[ "$http" == "200" && ( -z "$SUCCESS_CODE" || "$text" == *"\"code\":$SUCCESS_CODE"* || "$text" == *"\"code\":\"$SUCCESS_CODE\""* ) ]]; then
      ok=1
    fi
  fi
  if [[ $ok -eq 1 ]]; then
    echo "PASS id=$id ac=$ac card=$card http=$http $url" >>"$OUT"
  else
    echo "FAIL id=$id ac=$ac card=$card http=$http $url" >>"$OUT"
    echo "BODY_SNIP $(echo "$text" | tr '\n' ' ' | cut -c1-400)" >>"$OUT"
    fail=$((fail + 1))
  fi
  i=$((i + 1))
done

echo "RESULT fail=$fail" | tee -a "$OUT"
[[ $fail -eq 0 ]]
