#!/usr/bin/env bash
set -euo pipefail

ALLOWLIST_FILE="docs/legacy-exception-allowlist.md"

get_diff_range() {
  if [[ -n "${GITHUB_BASE_REF:-}" ]] && git show-ref --verify --quiet "refs/remotes/origin/${GITHUB_BASE_REF}"; then
    local merge_base
    merge_base="$(git merge-base HEAD "origin/${GITHUB_BASE_REF}")"
    echo "${merge_base}..HEAD"
    return
  fi

  if git rev-parse --verify --quiet HEAD >/dev/null; then
    echo "HEAD"
    return
  fi

  echo ""
}

is_allowlisted_path() {
  local file="$1"
  [[ -f "$ALLOWLIST_FILE" ]] || return 1
  grep -E "^\|[[:space:]]*${file//\//\/}[[:space:]]*\|" "$ALLOWLIST_FILE" >/dev/null 2>&1
}

is_valid_legacy_exception_line() {
  local line="$1"
  [[ "$line" =~ LEGACY_EXCEPTION: ]] || return 1
  [[ "$line" =~ reason= ]] || return 1
  [[ "$line" =~ owner= ]] || return 1
  [[ "$line" =~ remove_by=[0-9]{4}-[0-9]{2}-[0-9]{2} ]] || return 1
  return 0
}

check_rule_violations() {
  local diff_range="$1"
  local failed=0

  while IFS=$'\t' read -r file line_num content; do
    [[ -n "$file" ]] || continue

    local violation=""
    if [[ "$content" =~ Color\(0x ]]; then
      violation="Color(0x...)"
    elif [[ "$content" =~ BorderRadius\.circular\( ]]; then
      violation="BorderRadius.circular(...)"
    elif [[ "$content" =~ EdgeInsets\.(all|symmetric|only|fromLTRB)\( ]]; then
      violation="EdgeInsets.*(...)"
    fi

    [[ -n "$violation" ]] || continue

    if is_allowlisted_path "$file"; then
      echo "⚠️  allowlisted file violation accepted: ${file}:${line_num} -> ${violation}"
      continue
    fi

    if is_valid_legacy_exception_line "$content"; then
      echo "⚠️  LEGACY_EXCEPTION accepted on ${file}:${line_num}"
      continue
    fi

    echo "❌ New rule violation: ${file}:${line_num} -> ${violation}"
    echo "   Added line: ${content}"
    echo "   Fix: use FR tokens OR append LEGACY_EXCEPTION with reason/owner/remove_by metadata."
    failed=1
  done < <(
    if [[ -n "$diff_range" ]]; then
      git diff --unified=0 --no-color "$diff_range" -- '*.dart' | awk '
        BEGIN { file=""; line=0 }
        /^\+\+\+ b\// { file=substr($0, 7); next }
        /^@@/ {
          if (match($0, /\+[0-9]+/)) {
            line=substr($0, RSTART+1, RLENGTH-1)
          }
          next
        }
        /^\+/ && $0 !~ /^\+\+\+/ {
          print file "\t" line "\t" substr($0,2)
          line++
        }
      '
    fi
  )

  return "$failed"
}

main() {
  local diff_range
  diff_range="$(get_diff_range)"

  if [[ -z "$diff_range" ]]; then
    echo "No comparable git range found, skipping engineering guardrails check."
    exit 0
  fi

  echo "Engineering guardrails diff range: ${diff_range}"
  check_rule_violations "$diff_range"
}

main "$@"
